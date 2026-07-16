package httpapi

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/bielcarpi/nia/apps/api/internal/auth"
	"github.com/bielcarpi/nia/apps/api/internal/domain"
	"github.com/bielcarpi/nia/apps/api/internal/requestmeta"
)

type Application interface {
	Ready(context.Context) error
	GetPreferences(context.Context, string) (domain.Preferences, error)
	PatchPreferences(context.Context, string, domain.PreferencesPatch) (domain.Preferences, error)
	CreateSession(context.Context, string, domain.Preferences) (domain.RealtimeGrant, error)
	ListConversations(context.Context, string, string, int) (domain.ConversationPage, error)
	GetConversation(context.Context, string, string) (domain.ConversationDetail, error)
	UpsertTurn(context.Context, string, string, domain.Turn) (domain.Turn, error)
	CompleteConversation(context.Context, string, string) (domain.ConversationDetail, error)
	DeleteConversation(context.Context, string, string) error
}

type Config struct {
	AllowedOrigins        []string
	MaxRequestBodyBytes   int64
	MaxConcurrentRequests int
	RequestTimeout        time.Duration
}

type API struct {
	app      Application
	verifier auth.Verifier
	logger   *slog.Logger
	config   Config
	handler  http.Handler
}

func New(app Application, verifier auth.Verifier, logger *slog.Logger, config Config) (*API, error) {
	if app == nil || verifier == nil || logger == nil {
		return nil, errors.New("http API dependencies must not be nil")
	}
	if config.MaxRequestBodyBytes <= 0 || config.MaxConcurrentRequests <= 0 || config.RequestTimeout <= 0 {
		return nil, errors.New("http API limits must be positive")
	}
	api := &API{app: app, verifier: verifier, logger: logger, config: config}
	api.handler = api.routes()
	return api, nil
}

func (a *API) Handler() http.Handler { return a.handler }

func (a *API) routes() http.Handler {
	root := http.NewServeMux()
	root.HandleFunc("GET /healthz", a.health)
	root.HandleFunc("GET /readyz", a.ready)

	protected := http.NewServeMux()
	protected.HandleFunc("GET /api/v1/me/preferences", a.getPreferences)
	protected.HandleFunc("PATCH /api/v1/me/preferences", a.patchPreferences)
	protected.HandleFunc("POST /api/v1/realtime/sessions", a.createSession)
	protected.HandleFunc("GET /api/v1/conversations", a.listConversations)
	protected.HandleFunc("GET /api/v1/conversations/{conversation_id}", a.getConversation)
	protected.HandleFunc("DELETE /api/v1/conversations/{conversation_id}", a.deleteConversation)
	protected.HandleFunc("PUT /api/v1/conversations/{conversation_id}/turns/{turn_id}", a.upsertTurn)
	protected.HandleFunc("POST /api/v1/conversations/{conversation_id}/complete", a.completeConversation)
	protectedHandler := a.authenticate(a.captureRoute(protected))
	root.Handle("/api/v1/", a.concurrencyLimit(protectedHandler))

	var handler http.Handler = a.captureRoute(root)
	handler = a.requestTimeout(handler)
	handler = a.bodyLimit(handler)
	handler = a.cors(handler)
	handler = a.accessLog(handler)
	handler = securityHeaders(handler)
	handler = a.recoverPanic(handler)
	handler = requestID(handler)
	return handler
}

func (a *API) health(response http.ResponseWriter, _ *http.Request) {
	writeJSON(response, http.StatusOK, map[string]string{"status": "ok"})
}

func (a *API) ready(response http.ResponseWriter, request *http.Request) {
	ctx, cancel := context.WithTimeout(request.Context(), time.Second)
	defer cancel()
	if err := a.app.Ready(ctx); err != nil {
		a.logger.WarnContext(request.Context(), "readiness check failed", "request_id", requestIDFromContext(request.Context()), "error_class", "dependency_unavailable")
		writeError(response, request, &domain.PublicError{Code: "not_ready", Message: "A required dependency is unavailable.", Status: 503, Retryable: true, Cause: err})
		return
	}
	writeJSON(response, http.StatusOK, map[string]string{"status": "ok"})
}

func (a *API) getPreferences(response http.ResponseWriter, request *http.Request) {
	preferences, err := a.app.GetPreferences(request.Context(), identityUID(request))
	if err != nil {
		writeError(response, request, err)
		return
	}
	writeJSON(response, http.StatusOK, preferences)
}

func (a *API) patchPreferences(response http.ResponseWriter, request *http.Request) {
	var patch domain.PreferencesPatch
	if err := decodeJSON(request, &patch); err != nil {
		writeError(response, request, err)
		return
	}
	preferences, err := a.app.PatchPreferences(request.Context(), identityUID(request), patch)
	if err != nil {
		writeError(response, request, err)
		return
	}
	writeJSON(response, http.StatusOK, preferences)
}

func (a *API) createSession(response http.ResponseWriter, request *http.Request) {
	var body struct {
		Preferences domain.Preferences `json:"preferences"`
	}
	if err := decodeJSON(request, &body); err != nil {
		writeError(response, request, err)
		return
	}
	grant, err := a.app.CreateSession(request.Context(), identityUID(request), body.Preferences)
	if err != nil {
		writeError(response, request, err)
		return
	}
	writeJSON(response, http.StatusCreated, grant)
}

func (a *API) listConversations(response http.ResponseWriter, request *http.Request) {
	limit := 0
	if rawLimit := request.URL.Query().Get("limit"); rawLimit != "" {
		parsed, err := strconv.Atoi(rawLimit)
		if err != nil {
			writeError(response, request, domain.ValidationError("limit", "must be an integer"))
			return
		}
		limit = parsed
	}
	page, err := a.app.ListConversations(request.Context(), identityUID(request), request.URL.Query().Get("cursor"), limit)
	if err != nil {
		writeError(response, request, err)
		return
	}
	if page.Items == nil {
		page.Items = []domain.ConversationSummary{}
	}
	writeJSON(response, http.StatusOK, page)
}

func (a *API) getConversation(response http.ResponseWriter, request *http.Request) {
	detail, err := a.app.GetConversation(request.Context(), identityUID(request), request.PathValue("conversation_id"))
	if err != nil {
		writeError(response, request, err)
		return
	}
	if detail.Turns == nil {
		detail.Turns = []domain.Turn{}
	}
	writeJSON(response, http.StatusOK, detail)
}

func (a *API) upsertTurn(response http.ResponseWriter, request *http.Request) {
	var body struct {
		Role       string    `json:"role"`
		Text       string    `json:"text"`
		OccurredAt time.Time `json:"occurred_at"`
	}
	if err := decodeJSON(request, &body); err != nil {
		writeError(response, request, err)
		return
	}
	turn, err := a.app.UpsertTurn(request.Context(), identityUID(request), request.PathValue("conversation_id"), domain.Turn{
		ID: request.PathValue("turn_id"), Role: body.Role, Text: body.Text, OccurredAt: body.OccurredAt,
	})
	if err != nil {
		writeError(response, request, err)
		return
	}
	writeJSON(response, http.StatusOK, turn)
}

func (a *API) completeConversation(response http.ResponseWriter, request *http.Request) {
	detail, err := a.app.CompleteConversation(request.Context(), identityUID(request), request.PathValue("conversation_id"))
	if err != nil {
		writeError(response, request, err)
		return
	}
	if detail.Turns == nil {
		detail.Turns = []domain.Turn{}
	}
	writeJSON(response, http.StatusOK, detail)
}

func (a *API) deleteConversation(response http.ResponseWriter, request *http.Request) {
	if err := a.app.DeleteConversation(request.Context(), identityUID(request), request.PathValue("conversation_id")); err != nil {
		writeError(response, request, err)
		return
	}
	response.WriteHeader(http.StatusNoContent)
}

func decodeJSON(request *http.Request, target any) error {
	if contentType := request.Header.Get("Content-Type"); contentType != "" && !strings.HasPrefix(strings.ToLower(contentType), "application/json") {
		return domain.ValidationError("content_type", "must be application/json")
	}
	decoder := json.NewDecoder(request.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return domain.ValidationError("body", "must be valid JSON")
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		return domain.ValidationError("body", "must contain one JSON object")
	}
	return nil
}

func writeJSON(response http.ResponseWriter, statusCode int, value any) {
	response.Header().Set("Content-Type", "application/json; charset=utf-8")
	response.WriteHeader(statusCode)
	_ = json.NewEncoder(response).Encode(value)
}

func writeError(response http.ResponseWriter, request *http.Request, err error) {
	public := domain.AsPublicError(err)
	if recorder, ok := response.(interface {
		setError(string, string, bool)
	}); ok {
		recorder.setError(public.Code, classifyError(public), public.Retryable)
	}
	requestID := requestIDFromContext(request.Context())
	writeJSON(response, public.Status, map[string]any{
		"error": map[string]string{
			"code":       public.Code,
			"message":    public.Message,
			"request_id": requestID,
		},
	})
}

func classifyError(public *domain.PublicError) string {
	switch {
	case public.Code == "invalid_request" || public.Code == "origin_not_allowed":
		return "client"
	case public.Code == "unauthorized":
		return "identity"
	case public.Code == "not_found" || public.Code == "conflict":
		return "lifecycle"
	case public.Code == "rate_limited" || public.Code == "server_busy":
		return "capacity"
	case public.Code == "not_ready":
		return "dependency"
	case strings.HasPrefix(public.Code, "provider_"):
		return "provider"
	default:
		return "internal"
	}
}

func identityUID(request *http.Request) string {
	identity, _ := auth.IdentityFromContext(request.Context())
	return identity.UID
}

func (a *API) authenticate(next http.Handler) http.Handler {
	return http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		header := request.Header.Get("Authorization")
		const prefix = "Bearer "
		if !strings.HasPrefix(header, prefix) || strings.TrimSpace(strings.TrimPrefix(header, prefix)) == "" {
			writeError(response, request, &domain.PublicError{Code: "unauthorized", Message: "A valid bearer token is required.", Status: 401})
			return
		}
		bearer := strings.TrimSpace(strings.TrimPrefix(header, prefix))
		identity, err := a.verifier.Verify(request.Context(), bearer, request.Header.Get("X-Firebase-AppCheck"))
		if err != nil {
			writeError(response, request, &domain.PublicError{Code: "unauthorized", Message: "Authentication failed.", Status: 401, Cause: err})
			return
		}
		next.ServeHTTP(response, request.WithContext(auth.WithIdentity(request.Context(), identity)))
	})
}

func (a *API) bodyLimit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		if request.Body != nil {
			request.Body = http.MaxBytesReader(response, request.Body, a.config.MaxRequestBodyBytes)
		}
		next.ServeHTTP(response, request)
	})
}

func (a *API) concurrencyLimit(next http.Handler) http.Handler {
	slots := make(chan struct{}, a.config.MaxConcurrentRequests)
	return http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		select {
		case slots <- struct{}{}:
			defer func() { <-slots }()
			next.ServeHTTP(response, request)
		default:
			writeError(response, request, &domain.PublicError{Code: "server_busy", Message: "The server is busy. Please retry shortly.", Status: 503, Retryable: true})
		}
	})
}

func (a *API) requestTimeout(next http.Handler) http.Handler {
	return http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		ctx, cancel := context.WithTimeout(request.Context(), a.config.RequestTimeout)
		defer cancel()
		next.ServeHTTP(response, request.WithContext(ctx))
	})
}

type responseRecorder struct {
	http.ResponseWriter
	status     int
	route      string
	errorCode  string
	errorClass string
	retryable  bool
}

func (r *responseRecorder) WriteHeader(status int) {
	if r.status == 0 {
		r.status = status
	}
	r.ResponseWriter.WriteHeader(status)
}

func (r *responseRecorder) Write(body []byte) (int, error) {
	if r.status == 0 {
		r.status = http.StatusOK
	}
	return r.ResponseWriter.Write(body)
}

func (r *responseRecorder) setRoute(pattern string) {
	if len(pattern) > len(r.route) {
		r.route = pattern
	}
}

func (r *responseRecorder) setError(code, class string, retryable bool) {
	r.errorCode = code
	r.errorClass = class
	r.retryable = retryable
}

func (a *API) captureRoute(next http.Handler) http.Handler {
	return http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		next.ServeHTTP(response, request)
		if recorder, ok := response.(*responseRecorder); ok {
			recorder.setRoute(request.Pattern)
		}
	})
}

func (a *API) accessLog(next http.Handler) http.Handler {
	return http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		started := time.Now()
		recorder := &responseRecorder{ResponseWriter: response}
		next.ServeHTTP(recorder, request)
		statusCode := recorder.status
		if statusCode == 0 {
			statusCode = http.StatusOK
		}
		route := recorder.route
		if route == "" {
			route = "unmatched"
		}
		attributes := []any{
			"request_id", requestIDFromContext(request.Context()),
			"method", request.Method,
			"route", route,
			"status", statusCode,
			"duration_ms", time.Since(started).Milliseconds(),
		}
		if recorder.errorCode != "" {
			attributes = append(attributes,
				"error_code", recorder.errorCode,
				"error_class", recorder.errorClass,
				"retryable", recorder.retryable,
			)
		}
		a.logger.InfoContext(request.Context(), "http request", attributes...)
	})
}

func (a *API) recoverPanic(next http.Handler) http.Handler {
	return http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		defer func() {
			if recovered := recover(); recovered != nil {
				a.logger.ErrorContext(request.Context(), "panic recovered", "request_id", requestIDFromContext(request.Context()), "error_class", "panic")
				writeError(response, request, fmt.Errorf("panic recovered"))
			}
		}()
		next.ServeHTTP(response, request)
	})
}

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		response.Header().Set("X-Content-Type-Options", "nosniff")
		response.Header().Set("X-Frame-Options", "DENY")
		response.Header().Set("Referrer-Policy", "no-referrer")
		response.Header().Set("Cache-Control", "no-store")
		response.Header().Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
		next.ServeHTTP(response, request)
	})
}

func (a *API) cors(next http.Handler) http.Handler {
	allowed := make(map[string]struct{}, len(a.config.AllowedOrigins))
	for _, origin := range a.config.AllowedOrigins {
		allowed[origin] = struct{}{}
	}
	return http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		origin := request.Header.Get("Origin")
		if origin != "" {
			if _, ok := allowed[origin]; !ok {
				writeError(response, request, &domain.PublicError{Code: "origin_not_allowed", Message: "This browser origin is not allowed.", Status: 403})
				return
			}
			response.Header().Set("Access-Control-Allow-Origin", origin)
			response.Header().Set("Vary", "Origin")
			response.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Firebase-AppCheck, X-Request-ID")
			response.Header().Set("Access-Control-Allow-Methods", "GET, PATCH, POST, PUT, DELETE, OPTIONS")
			response.Header().Set("Access-Control-Expose-Headers", "X-Request-ID")
			response.Header().Set("Access-Control-Max-Age", "600")
		}
		if request.Method == http.MethodOptions {
			response.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(response, request)
	})
}

var validRequestID = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._-]{7,127}$`)

func requestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		id := request.Header.Get("X-Request-ID")
		if !validRequestID.MatchString(id) {
			var random [16]byte
			if _, err := rand.Read(random[:]); err != nil {
				id = strconv.FormatInt(time.Now().UnixNano(), 36)
			} else {
				id = hex.EncodeToString(random[:])
			}
		}
		response.Header().Set("X-Request-ID", id)
		ctx := requestmeta.WithRequestID(request.Context(), id)
		next.ServeHTTP(response, request.WithContext(ctx))
	})
}

func requestIDFromContext(ctx context.Context) string {
	return requestmeta.RequestID(ctx)
}
