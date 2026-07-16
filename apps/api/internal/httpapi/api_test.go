package httpapi

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/bielcarpi/nia/apps/api/internal/auth"
	"github.com/bielcarpi/nia/apps/api/internal/domain"
	"github.com/bielcarpi/nia/apps/api/internal/provider/demo"
	"github.com/bielcarpi/nia/apps/api/internal/requestmeta"
	"github.com/bielcarpi/nia/apps/api/internal/service"
	"github.com/bielcarpi/nia/apps/api/internal/store/memory"
)

func TestCredentialFreeHTTPFlow(t *testing.T) {
	server := testServer(t)
	defer server.Close()

	health := request(t, server, http.MethodGet, "/healthz", nil, "")
	if health.StatusCode != http.StatusOK || health.Header.Get("X-Request-ID") == "" || health.Header.Get("Cache-Control") != "no-store" {
		t.Fatalf("health response status=%d headers=%v", health.StatusCode, health.Header)
	}
	closeBody(health)

	unauthorized := request(t, server, http.MethodGet, "/api/v1/me/preferences", nil, "")
	if unauthorized.StatusCode != http.StatusUnauthorized {
		t.Fatalf("unauthorized status = %d", unauthorized.StatusCode)
	}
	closeBody(unauthorized)

	create := request(t, server, http.MethodPost, "/api/v1/realtime/sessions", map[string]any{
		"preferences": domain.DefaultPreferences(),
	}, "nia-local-demo")
	if create.StatusCode != http.StatusCreated {
		t.Fatalf("create status = %d body=%s", create.StatusCode, readBody(create))
	}
	var grant domain.RealtimeGrant
	decodeResponse(t, create, &grant)
	if grant.ClientSecret != nil || grant.Realtime.Transport != domain.TransportDemo || grant.Conversation.ID == "" {
		t.Fatalf("unexpected grant: %+v", grant)
	}

	turnPath := "/api/v1/conversations/" + grant.Conversation.ID + "/turns/turn_abcdefgh"
	turn := request(t, server, http.MethodPut, turnPath, map[string]any{
		"role": "user", "text": "Hola", "occurred_at": time.Now().UTC(),
	}, "nia-local-demo")
	if turn.StatusCode != http.StatusOK {
		t.Fatalf("turn status = %d body=%s", turn.StatusCode, readBody(turn))
	}
	closeBody(turn)

	complete := request(t, server, http.MethodPost, "/api/v1/conversations/"+grant.Conversation.ID+"/complete", nil, "nia-local-demo")
	if complete.StatusCode != http.StatusOK {
		t.Fatalf("complete status = %d body=%s", complete.StatusCode, readBody(complete))
	}
	var detail domain.ConversationDetail
	decodeResponse(t, complete, &detail)
	if detail.Feedback == nil || detail.Conversation.Status != domain.StatusCompleted || len(detail.Turns) != 1 {
		t.Fatalf("unexpected detail: %+v", detail)
	}

	list := request(t, server, http.MethodGet, "/api/v1/conversations", nil, "nia-local-demo")
	var page domain.ConversationPage
	decodeResponse(t, list, &page)
	if len(page.Items) != 1 {
		t.Fatalf("unexpected page: %+v", page)
	}

	deleted := request(t, server, http.MethodDelete, "/api/v1/conversations/"+grant.Conversation.ID, nil, "nia-local-demo")
	if deleted.StatusCode != http.StatusNoContent {
		t.Fatalf("delete status = %d", deleted.StatusCode)
	}
	closeBody(deleted)

	missing := request(t, server, http.MethodGet, "/api/v1/conversations/"+grant.Conversation.ID, nil, "nia-local-demo")
	if missing.StatusCode != http.StatusNotFound {
		t.Fatalf("missing status = %d", missing.StatusCode)
	}
	closeBody(missing)
}

func TestHTTPValidationAndCORS(t *testing.T) {
	server := testServer(t)
	defer server.Close()

	badJSON := request(t, server, http.MethodPost, "/api/v1/realtime/sessions", map[string]any{
		"preferences": map[string]any{
			"target_language": "fr", "level": "expert", "topic": "", "correction_style": "never",
		},
	}, "nia-local-demo")
	if badJSON.StatusCode != http.StatusBadRequest {
		t.Fatalf("invalid request status = %d", badJSON.StatusCode)
	}
	var envelope struct {
		Error map[string]string `json:"error"`
	}
	decodeResponse(t, badJSON, &envelope)
	if envelope.Error["request_id"] == "" || envelope.Error["code"] != "invalid_request" {
		t.Fatalf("unexpected error envelope: %+v", envelope)
	}

	disallowed, err := http.NewRequest(http.MethodGet, server.URL+"/healthz", nil)
	if err != nil {
		t.Fatal(err)
	}
	disallowed.Header.Set("Origin", "https://evil.example")
	response, err := server.Client().Do(disallowed)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusForbidden || response.Header.Get("Access-Control-Allow-Origin") != "" {
		t.Fatalf("disallowed origin status=%d headers=%v", response.StatusCode, response.Header)
	}
	closeBody(response)

	preflight, err := http.NewRequest(http.MethodOptions, server.URL+"/api/v1/realtime/sessions", nil)
	if err != nil {
		t.Fatal(err)
	}
	preflight.Header.Set("Origin", "http://localhost:3000")
	response, err = server.Client().Do(preflight)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusNoContent || response.Header.Get("Access-Control-Allow-Origin") != "http://localhost:3000" {
		t.Fatalf("preflight status=%d headers=%v", response.StatusCode, response.Header)
	}
	closeBody(response)
}

func TestAccessLogUsesRouteTemplate(t *testing.T) {
	var logs bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(&logs, nil))
	server := testServerWithLogger(t, logger)
	defer server.Close()

	const conversationID = "conv_sensitiveidentifier"
	response := request(t, server, http.MethodGet, "/api/v1/conversations/"+conversationID, nil, "nia-local-demo")
	if response.StatusCode != http.StatusNotFound {
		t.Fatalf("response status = %d", response.StatusCode)
	}
	closeBody(response)

	output := logs.String()
	if strings.Contains(output, conversationID) {
		t.Fatalf("access log contains a resource identifier: %s", output)
	}
	if !strings.Contains(output, `"route":"GET /api/v1/conversations/{conversation_id}"`) {
		t.Fatalf("access log does not contain the route template: %s", output)
	}
	if !strings.Contains(output, `"error_code":"not_found"`) || !strings.Contains(output, `"error_class":"lifecycle"`) {
		t.Fatalf("access log does not contain sanitized error metadata: %s", output)
	}
}

func TestAccessLogNeverIncludesInternalErrorCause(t *testing.T) {
	var logs bytes.Buffer
	api := &API{logger: slog.New(slog.NewJSONHandler(&logs, nil))}
	const sensitive = "raw provider response and transcript"
	handler := requestID(api.accessLog(http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		writeError(response, request, domain.ProviderUnavailable(errors.New(sensitive)))
	})))

	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httptest.NewRequest(http.MethodPost, "/api/v1/test", nil))
	if response.Code != http.StatusServiceUnavailable {
		t.Fatalf("response status = %d", response.Code)
	}
	output := logs.String()
	if strings.Contains(output, sensitive) {
		t.Fatalf("access log leaked the internal cause: %s", output)
	}
	for _, field := range []string{`"error_code":"provider_unavailable"`, `"error_class":"provider"`, `"retryable":true`} {
		if !strings.Contains(output, field) {
			t.Fatalf("access log missing %s: %s", field, output)
		}
	}
}

func TestRateLimitDoesNotInventRetryDelay(t *testing.T) {
	response := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodPost, "/api/v1/test", nil)
	request = request.WithContext(requestmeta.WithRequestID(request.Context(), "nia-request-rate-limit"))
	writeError(response, request, domain.RateLimited())
	if response.Code != http.StatusTooManyRequests {
		t.Fatalf("response status = %d", response.Code)
	}
	if delay := response.Header().Get("Retry-After"); delay != "" {
		t.Fatalf("fabricated Retry-After = %q", delay)
	}
}

type blockingApplication struct {
	Application
	started chan struct{}
	release chan struct{}
}

func (a *blockingApplication) GetPreferences(ctx context.Context, _ string) (domain.Preferences, error) {
	select {
	case a.started <- struct{}{}:
	default:
	}
	select {
	case <-a.release:
		return domain.DefaultPreferences(), nil
	case <-ctx.Done():
		return domain.Preferences{}, ctx.Err()
	}
}

func TestHealthAndReadinessBypassApplicationConcurrencyLimit(t *testing.T) {
	application, err := service.New(service.Options{
		Store: memory.New(), Issuer: demo.RealtimeIssuer{}, Feedback: demo.FeedbackGenerator{},
		Realtime: domain.RealtimeConnection{Transport: domain.TransportDemo, Endpoint: "demo://local", Model: "deterministic-demo"},
	})
	if err != nil {
		t.Fatal(err)
	}
	blocking := &blockingApplication{Application: application, started: make(chan struct{}, 1), release: make(chan struct{})}
	api, err := New(blocking, auth.DemoVerifier{}, slog.New(slog.NewJSONHandler(io.Discard, nil)), Config{
		AllowedOrigins: []string{"http://localhost:3000"}, MaxRequestBodyBytes: 64 << 10,
		MaxConcurrentRequests: 1, RequestTimeout: 5 * time.Second,
	})
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(api.Handler())
	defer server.Close()
	firstDone := make(chan *http.Response, 1)
	firstError := make(chan error, 1)
	go func() {
		request, requestErr := http.NewRequest(http.MethodGet, server.URL+"/api/v1/me/preferences", nil)
		if requestErr == nil {
			request.Header.Set("Authorization", "Bearer nia-local-demo")
		}
		if requestErr != nil {
			firstError <- requestErr
			return
		}
		response, requestErr := server.Client().Do(request)
		if requestErr != nil {
			firstError <- requestErr
			return
		}
		firstDone <- response
	}()
	select {
	case <-blocking.started:
	case <-time.After(time.Second):
		t.Fatal("first request did not occupy the application slot")
	}

	for _, path := range []string{"/healthz", "/readyz"} {
		response := request(t, server, http.MethodGet, path, nil, "")
		if response.StatusCode != http.StatusOK {
			t.Fatalf("%s status under saturation = %d", path, response.StatusCode)
		}
		closeBody(response)
	}
	busy := request(t, server, http.MethodGet, "/api/v1/me/preferences", nil, "nia-local-demo")
	if busy.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("second application request status = %d", busy.StatusCode)
	}
	closeBody(busy)
	close(blocking.release)
	select {
	case response := <-firstDone:
		if response.StatusCode != http.StatusOK {
			t.Fatalf("first request status = %d", response.StatusCode)
		}
		closeBody(response)
	case err := <-firstError:
		t.Fatal(err)
	case <-time.After(time.Second):
		t.Fatal("first request did not finish")
	}
}

func testServer(t *testing.T) *httptest.Server {
	t.Helper()
	return testServerWithLogger(t, slog.New(slog.NewJSONHandler(io.Discard, nil)))
}

func testServerWithLogger(t *testing.T, logger *slog.Logger) *httptest.Server {
	t.Helper()
	application, err := service.New(service.Options{
		Store: memory.New(), Issuer: demo.RealtimeIssuer{}, Feedback: demo.FeedbackGenerator{},
		Realtime:            domain.RealtimeConnection{Transport: domain.TransportDemo, Endpoint: "demo://local", Model: "deterministic-demo"},
		SessionLimitPerHour: 20, FeedbackLimitPerHour: 20,
	})
	if err != nil {
		t.Fatal(err)
	}
	api, err := New(application, auth.DemoVerifier{}, logger, Config{
		AllowedOrigins: []string{"http://localhost:3000"}, MaxRequestBodyBytes: 64 << 10,
		MaxConcurrentRequests: 8, RequestTimeout: 5 * time.Second,
	})
	if err != nil {
		t.Fatal(err)
	}
	return httptest.NewServer(api.Handler())
}

func request(t *testing.T, server *httptest.Server, method, path string, body any, token string) *http.Response {
	t.Helper()
	var reader io.Reader
	if body != nil {
		encoded, err := json.Marshal(body)
		if err != nil {
			t.Fatal(err)
		}
		reader = bytes.NewReader(encoded)
	}
	request, err := http.NewRequest(method, server.URL+path, reader)
	if err != nil {
		t.Fatal(err)
	}
	if body != nil {
		request.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		request.Header.Set("Authorization", "Bearer "+token)
	}
	response, err := server.Client().Do(request)
	if err != nil {
		t.Fatal(err)
	}
	return response
}

func decodeResponse(t *testing.T, response *http.Response, target any) {
	t.Helper()
	defer response.Body.Close()
	if err := json.NewDecoder(response.Body).Decode(target); err != nil {
		t.Fatalf("decode response: %v", err)
	}
}

func closeBody(response *http.Response) {
	_, _ = io.Copy(io.Discard, response.Body)
	_ = response.Body.Close()
}

func readBody(response *http.Response) string {
	body, _ := io.ReadAll(response.Body)
	_ = response.Body.Close()
	return string(body)
}
