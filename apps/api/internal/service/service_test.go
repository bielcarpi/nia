package service

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/bielcarpi/nia/apps/api/internal/domain"
	"github.com/bielcarpi/nia/apps/api/internal/provider/demo"
	"github.com/bielcarpi/nia/apps/api/internal/store/memory"
)

type blockingFeedbackGenerator struct {
	calls   atomic.Int32
	started chan struct{}
	release chan struct{}
	once    sync.Once
}

func (g *blockingFeedbackGenerator) Generate(ctx context.Context, _ string, _ domain.ConversationDetail) (domain.Feedback, error) {
	g.calls.Add(1)
	g.once.Do(func() { close(g.started) })
	select {
	case <-g.release:
		return domain.Feedback{Summary: "Done", NextSteps: []string{"Continue"}, GeneratedAt: time.Now().UTC()}, nil
	case <-ctx.Done():
		return domain.Feedback{}, ctx.Err()
	}
}

type failOnceFeedbackGenerator struct {
	calls atomic.Int32
}

func (g *failOnceFeedbackGenerator) Generate(_ context.Context, _ string, _ domain.ConversationDetail) (domain.Feedback, error) {
	if g.calls.Add(1) == 1 {
		return domain.Feedback{}, domain.ProviderUnavailable(errors.New("temporary failure"))
	}
	return domain.Feedback{Summary: "Done", NextSteps: []string{"Continue"}, GeneratedAt: time.Now().UTC()}, nil
}

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

func TestWindowLimiterPrunesExpiredKeys(t *testing.T) {
	limiter := NewWindowLimiter(2, time.Hour)
	now := time.Unix(100, 0)
	limiter.now = func() time.Time { return now }
	for index := 0; index < 100; index++ {
		if !limiter.Allow(newID("limiter_")) {
			t.Fatal("new key should be allowed")
		}
	}
	if len(limiter.entries) != 100 {
		t.Fatalf("entry count = %d, want 100", len(limiter.entries))
	}
	now = now.Add(time.Hour)
	if !limiter.Allow("current-user") {
		t.Fatal("current key should be allowed")
	}
	if len(limiter.entries) != 1 {
		t.Fatalf("expired limiter entries were retained: %d", len(limiter.entries))
	}
}

func TestTranscriptWritesHavePerUserGuardrail(t *testing.T) {
	application, err := New(Options{
		Store: memory.New(), Issuer: demo.RealtimeIssuer{}, Feedback: demo.FeedbackGenerator{},
		Realtime:           domain.RealtimeConnection{Transport: domain.TransportDemo, Endpoint: "demo://local", Model: "deterministic-demo"},
		TurnLimitPerMinute: 1,
	})
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	grant, err := application.CreateSession(ctx, "bounded-user", domain.DefaultPreferences())
	if err != nil {
		t.Fatal(err)
	}
	for index, wantStatus := range []int{0, 429} {
		_, err := application.UpsertTurn(ctx, "bounded-user", grant.Conversation.ID, domain.Turn{
			ID: newID("turn_"), Role: "user", Text: "Hola", OccurredAt: time.Now().UTC(),
		})
		if wantStatus == 0 && err != nil {
			t.Fatalf("write %d error = %v", index+1, err)
		}
		if wantStatus != 0 {
			var public *domain.PublicError
			if !errors.As(err, &public) || public.Status != wantStatus || !public.Retryable {
				t.Fatalf("write %d error = %v", index+1, err)
			}
		}
	}
	other, err := application.CreateSession(ctx, "other-user", domain.DefaultPreferences())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := application.UpsertTurn(ctx, "other-user", other.Conversation.ID, domain.Turn{
		ID: newID("turn_"), Role: "user", Text: "Hola", OccurredAt: time.Now().UTC(),
	}); err != nil {
		t.Fatalf("one user's guardrail affected another: %v", err)
	}
}

func TestCompletionWithoutLearnerTurnDoesNotConsumeFeedbackQuota(t *testing.T) {
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
	assistantTurn := domain.Turn{ID: "turn_assistant", Role: "assistant", Text: "Hola", OccurredAt: time.Now().UTC()}
	if _, err := application.UpsertTurn(ctx, "user", grant.Conversation.ID, assistantTurn); err != nil {
		t.Fatalf("UpsertTurn(assistant) error = %v", err)
	}
	if _, err := application.CompleteConversation(ctx, "user", grant.Conversation.ID); err == nil {
		t.Fatal("assistant-only CompleteConversation() succeeded")
	} else {
		var public *domain.PublicError
		if !errors.As(err, &public) || public.Status != 409 {
			t.Fatalf("assistant-only CompleteConversation() error = %v", err)
		}
	}
	turn := domain.Turn{ID: "turn_abcdefgh", Role: "user", Text: "Quiero practicar", OccurredAt: time.Now().UTC()}
	if _, err := application.UpsertTurn(ctx, "user", grant.Conversation.ID, turn); err != nil {
		t.Fatalf("UpsertTurn() error = %v", err)
	}
	if _, err := application.CompleteConversation(ctx, "user", grant.Conversation.ID); err != nil {
		t.Fatalf("CompleteConversation() error = %v", err)
	}
}

func TestConcurrentCompletionGeneratesFeedbackOnce(t *testing.T) {
	store := memory.New()
	generator := &blockingFeedbackGenerator{started: make(chan struct{}), release: make(chan struct{})}
	application, err := New(Options{
		Store: store, Issuer: demo.RealtimeIssuer{}, Feedback: generator,
		Realtime:            domain.RealtimeConnection{Transport: domain.TransportDemo, Endpoint: "demo://local", Model: "deterministic-demo"},
		SessionLimitPerHour: 10, FeedbackLimitPerHour: 10,
	})
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	grant, err := application.CreateSession(ctx, "user", domain.DefaultPreferences())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := application.UpsertTurn(ctx, "user", grant.Conversation.ID, domain.Turn{
		ID: "turn_concurrent", Role: "user", Text: "Hola", OccurredAt: time.Now().UTC(),
	}); err != nil {
		t.Fatal(err)
	}
	firstResult := make(chan error, 1)
	go func() {
		_, err := application.CompleteConversation(ctx, "user", grant.Conversation.ID)
		firstResult <- err
	}()
	<-generator.started
	_, secondErr := application.CompleteConversation(ctx, "user", grant.Conversation.ID)
	var public *domain.PublicError
	if !errors.As(secondErr, &public) || public.Status != 409 || !public.Retryable {
		t.Fatalf("concurrent completion error = %v", secondErr)
	}
	close(generator.release)
	if err := <-firstResult; err != nil {
		t.Fatalf("first completion error = %v", err)
	}
	if calls := generator.calls.Load(); calls != 1 {
		t.Fatalf("feedback calls = %d, want 1", calls)
	}
	if detail, err := application.CompleteConversation(ctx, "user", grant.Conversation.ID); err != nil || detail.Feedback == nil {
		t.Fatalf("completed retry = %+v, %v", detail, err)
	}
}

func TestProviderFailureReleasesCompletionLease(t *testing.T) {
	store := memory.New()
	generator := &failOnceFeedbackGenerator{}
	application, err := New(Options{
		Store: store, Issuer: demo.RealtimeIssuer{}, Feedback: generator,
		Realtime:            domain.RealtimeConnection{Transport: domain.TransportDemo, Endpoint: "demo://local", Model: "deterministic-demo"},
		SessionLimitPerHour: 10, FeedbackLimitPerHour: 10,
	})
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	grant, err := application.CreateSession(ctx, "user", domain.DefaultPreferences())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := application.UpsertTurn(ctx, "user", grant.Conversation.ID, domain.Turn{
		ID: "turn_retryable", Role: "user", Text: "Hola", OccurredAt: time.Now().UTC(),
	}); err != nil {
		t.Fatal(err)
	}
	if _, err := application.CompleteConversation(ctx, "user", grant.Conversation.ID); err == nil {
		t.Fatal("first completion succeeded")
	}
	if detail, err := application.CompleteConversation(ctx, "user", grant.Conversation.ID); err != nil || detail.Feedback == nil {
		t.Fatalf("completion after provider recovery = %+v, %v", detail, err)
	}
	if calls := generator.calls.Load(); calls != 2 {
		t.Fatalf("feedback calls = %d, want 2", calls)
	}
}
