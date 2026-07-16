package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/bielcarpi/nia/apps/api/internal/domain"
	"github.com/bielcarpi/nia/apps/api/internal/provider/demo"
	"github.com/bielcarpi/nia/apps/api/internal/store/memory"
)

func TestServiceDemoLifecycle(t *testing.T) {
	store := memory.New()
	application, err := New(Options{
		Store: store, Issuer: demo.RealtimeIssuer{}, Feedback: demo.FeedbackGenerator{},
		Realtime:            domain.RealtimeConnection{Transport: domain.TransportDemo, Endpoint: "demo://local", Model: "deterministic-demo"},
		SessionLimitPerHour: 10, FeedbackLimitPerHour: 10,
	})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	ctx := context.Background()
	grant, err := application.CreateSession(ctx, "user", domain.DefaultPreferences())
	if err != nil {
		t.Fatalf("CreateSession() error = %v", err)
	}
	if grant.ClientSecret != nil || grant.Realtime.Transport != domain.TransportDemo || grant.Conversation.ID == "" {
		t.Fatalf("unexpected grant: %+v", grant)
	}
	turn := domain.Turn{ID: "turn_abcdefgh", Role: "user", Text: "Hola", OccurredAt: time.Now().UTC()}
	if _, err := application.UpsertTurn(ctx, "user", grant.Conversation.ID, turn); err != nil {
		t.Fatalf("UpsertTurn() error = %v", err)
	}
	detail, err := application.CompleteConversation(ctx, "user", grant.Conversation.ID)
	if err != nil {
		t.Fatalf("CompleteConversation() error = %v", err)
	}
	if detail.Feedback == nil || detail.Conversation.Status != domain.StatusCompleted {
		t.Fatalf("unexpected completed detail: %+v", detail)
	}
	second, err := application.CompleteConversation(ctx, "user", grant.Conversation.ID)
	if err != nil || second.Feedback == nil {
		t.Fatalf("idempotent CompleteConversation() = %+v, %v", second, err)
	}
}

func TestWindowLimiter(t *testing.T) {
	limiter := NewWindowLimiter(2, time.Hour)
	now := time.Unix(100, 0)
	limiter.now = func() time.Time { return now }
	if !limiter.Allow("user") {
		t.Fatal("first request should be allowed")
	}
	if !limiter.Allow("user") {
		t.Fatal("second request should be allowed")
	}
	if limiter.Allow("user") {
		t.Fatal("third request should be denied")
	}
	if !limiter.Allow("other") {
		t.Fatal("limits should be per key")
	}
	now = now.Add(time.Hour)
	if !limiter.Allow("user") {
		t.Fatal("new window should reset the limit")
	}
}

func TestEmptyCompletionDoesNotConsumeFeedbackQuota(t *testing.T) {
	application, err := New(Options{
		Store: memory.New(), Issuer: demo.RealtimeIssuer{}, Feedback: demo.FeedbackGenerator{},
		Realtime:            domain.RealtimeConnection{Transport: domain.TransportDemo, Endpoint: "demo://local", Model: "deterministic-demo"},
		SessionLimitPerHour: 10, FeedbackLimitPerHour: 1,
	})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	ctx := context.Background()
	grant, err := application.CreateSession(ctx, "user", domain.DefaultPreferences())
	if err != nil {
		t.Fatalf("CreateSession() error = %v", err)
	}
	if _, err := application.CompleteConversation(ctx, "user", grant.Conversation.ID); err == nil {
		t.Fatal("empty CompleteConversation() succeeded")
	} else {
		var public *domain.PublicError
		if !errors.As(err, &public) || public.Status != 409 {
			t.Fatalf("empty CompleteConversation() error = %v", err)
		}
	}
	turn := domain.Turn{ID: "turn_abcdefgh", Role: "user", Text: "Hola", OccurredAt: time.Now().UTC()}
	if _, err := application.UpsertTurn(ctx, "user", grant.Conversation.ID, turn); err != nil {
		t.Fatalf("UpsertTurn() error = %v", err)
	}
	if _, err := application.CompleteConversation(ctx, "user", grant.Conversation.ID); err != nil {
		t.Fatalf("CompleteConversation() error = %v", err)
	}
}
