package app

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	firebase "firebase.google.com/go/v4"
	"github.com/bielcarpi/nia/apps/api/internal/auth"
	"github.com/bielcarpi/nia/apps/api/internal/config"
	"github.com/bielcarpi/nia/apps/api/internal/domain"
	"github.com/bielcarpi/nia/apps/api/internal/httpapi"
	"github.com/bielcarpi/nia/apps/api/internal/provider/demo"
	openaiadapter "github.com/bielcarpi/nia/apps/api/internal/provider/openai"
	"github.com/bielcarpi/nia/apps/api/internal/service"
	firestorestore "github.com/bielcarpi/nia/apps/api/internal/store/firestore"
	"github.com/bielcarpi/nia/apps/api/internal/store/memory"
)

type Runtime struct {
	Handler http.Handler
	service *service.Service
}

func Build(ctx context.Context, cfg config.Config, logger *slog.Logger) (*Runtime, error) {
	var firebaseApp *firebase.App
	if cfg.AuthMode == "firebase" || cfg.StoreMode == "firestore" {
		var err error
		firebaseApp, err = firebase.NewApp(ctx, &firebase.Config{ProjectID: cfg.FirebaseProjectID})
		if err != nil {
			return nil, fmt.Errorf("initialize firebase: %w", err)
		}
	}

	var verifier auth.Verifier
	switch cfg.AuthMode {
	case "demo":
		verifier = auth.DemoVerifier{}
	case "firebase":
		authClient, err := firebaseApp.Auth(ctx)
		if err != nil {
			return nil, fmt.Errorf("initialize firebase auth: %w", err)
		}
		appCheckClient, err := firebaseApp.AppCheck(ctx)
		if err != nil {
			return nil, fmt.Errorf("initialize firebase app check: %w", err)
		}
		verifier, err = auth.NewFirebaseVerifier(authClient, appCheckClient, cfg.RequireAppCheck)
		if err != nil {
			return nil, err
		}
	default:
		return nil, fmt.Errorf("unsupported auth mode %q", cfg.AuthMode)
	}

	var store domain.ConversationStore
	switch cfg.StoreMode {
	case "memory":
		store = memory.New()
	case "firestore":
		firestoreClient, err := firebaseApp.Firestore(ctx)
		if err != nil {
			return nil, fmt.Errorf("initialize firestore: %w", err)
		}
		store, err = firestorestore.New(firestoreClient)
		if err != nil {
			_ = firestoreClient.Close()
			return nil, err
		}
	default:
		return nil, fmt.Errorf("unsupported store mode %q", cfg.StoreMode)
	}

	var issuer domain.RealtimeSessionIssuer
	var feedback domain.FeedbackGenerator
	realtime := domain.RealtimeConnection{
		Transport: domain.TransportDemo,
		Endpoint:  "demo://local",
		Model:     "deterministic-demo",
	}
	switch cfg.ProviderMode {
	case "demo":
		issuer = demo.RealtimeIssuer{}
		feedback = demo.FeedbackGenerator{}
	case "openai":
		projectID := cfg.FirebaseProjectID
		if projectID == "" {
			projectID = "nia-local"
		}
		provider, err := openaiadapter.New(openaiadapter.Config{
			APIKey:             cfg.OpenAIAPIKey,
			BaseURL:            cfg.OpenAIBaseURL,
			ProjectID:          projectID,
			RealtimeModel:      cfg.RealtimeModel,
			RealtimeVoice:      cfg.RealtimeVoice,
			TranscriptionModel: cfg.TranscriptionModel,
			FeedbackModel:      cfg.FeedbackModel,
			RealtimeTTL:        cfg.RealtimeTTL,
			SDPEndpoint:        cfg.RealtimeSDPEndpoint,
			MaxConcurrency:     8,
			Logger:             logger,
		}, &http.Client{Timeout: cfg.ProviderTimeout})
		if err != nil {
			_ = store.Close()
			return nil, err
		}
		issuer = provider
		feedback = provider
		realtime = domain.RealtimeConnection{
			Transport: domain.TransportWebRTC,
			Endpoint:  cfg.RealtimeSDPEndpoint,
			Model:     cfg.RealtimeModel,
		}
	default:
		_ = store.Close()
		return nil, fmt.Errorf("unsupported provider mode %q", cfg.ProviderMode)
	}

	application, err := service.New(service.Options{
		Store:                store,
		Issuer:               issuer,
		Feedback:             feedback,
		Realtime:             realtime,
		SessionLimitPerHour:  cfg.SessionLimitPerHour,
		FeedbackLimitPerHour: cfg.FeedbackLimitPerHour,
		TurnLimitPerMinute:   cfg.TurnLimitPerMinute,
		CompletionLease:      cfg.RequestTimeout + 30*time.Second,
	})
	if err != nil {
		_ = store.Close()
		return nil, err
	}
	api, err := httpapi.New(application, verifier, logger, httpapi.Config{
		AllowedOrigins:        cfg.AllowedOrigins,
		MaxRequestBodyBytes:   cfg.MaxRequestBodyBytes,
		MaxConcurrentRequests: cfg.MaxConcurrentRequests,
		RequestTimeout:        cfg.RequestTimeout,
	})
	if err != nil {
		_ = application.Close()
		return nil, err
	}
	return &Runtime{Handler: api.Handler(), service: application}, nil
}

func (r *Runtime) Close() error {
	if r == nil || r.service == nil {
		return nil
	}
	return r.service.Close()
}
