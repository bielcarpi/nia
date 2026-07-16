package memory

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"github.com/bielcarpi/nia/apps/api/internal/domain"
)

func TestStoreConversationLifecycleAndOwnership(t *testing.T) {
	store := New()
	ctx := context.Background()
	now := time.Now().UTC()
	summary := domain.ConversationSummary{
		ID: "conv_abcdefgh", Status: domain.StatusActive, Preferences: domain.DefaultPreferences(), CreatedAt: now, UpdatedAt: now,
	}
	if err := store.CreateConversation(ctx, "user-a", summary); err != nil {
		t.Fatalf("CreateConversation() error = %v", err)
	}
	if _, err := store.GetConversation(ctx, "user-b", summary.ID); err == nil {
		t.Fatal("cross-user GetConversation() succeeded")
	}
	turn := domain.Turn{ID: "turn_abcdefgh", Role: "user", Text: "Hola", OccurredAt: now}
	if _, err := store.UpsertTurn(ctx, "user-a", summary.ID, turn); err != nil {
		t.Fatalf("UpsertTurn() error = %v", err)
	}
	turn.Text = "Hola de nuevo"
	if _, err := store.UpsertTurn(ctx, "user-a", summary.ID, turn); err != nil {
		t.Fatalf("idempotent UpsertTurn() error = %v", err)
	}
	detail, err := store.GetConversation(ctx, "user-a", summary.ID)
	if err != nil {
		t.Fatalf("GetConversation() error = %v", err)
	}
	if len(detail.Turns) != 1 || detail.Conversation.TurnCount != 1 || detail.Turns[0].Text != "Hola de nuevo" {
		t.Fatalf("unexpected detail after upsert: %+v", detail)
	}
	lease := domain.CompletionLease{ID: "lease_abcdefgh", StartedAt: now, ExpiresAt: now.Add(time.Minute)}
	detail, claimed, err := store.ClaimConversationCompletion(ctx, "user-a", summary.ID, lease)
	if err != nil || !claimed || len(detail.Turns) != 1 {
		t.Fatalf("ClaimConversationCompletion() = %+v, %v, %v", detail, claimed, err)
	}
	if _, _, err := store.ClaimConversationCompletion(ctx, "user-a", summary.ID, domain.CompletionLease{
		ID: "lease_ijklmnop", StartedAt: now.Add(time.Second), ExpiresAt: now.Add(time.Minute),
	}); err == nil {
		t.Fatal("a second active completion lease was acquired")
	}
	feedback := domain.Feedback{Summary: "Good", Strengths: []string{"Clear"}, NextSteps: []string{"Continue"}, GeneratedAt: now.Add(time.Minute)}
	detail, err = store.CompleteConversation(ctx, "user-a", summary.ID, lease.ID, feedback)
	if err != nil || detail.Conversation.Status != domain.StatusCompleted || detail.Feedback == nil {
		t.Fatalf("CompleteConversation() = %+v, %v", detail, err)
	}
	if _, err := store.UpsertTurn(ctx, "user-a", summary.ID, domain.Turn{ID: "turn_ijklmnop", Role: "user", Text: "Late", OccurredAt: now}); err == nil {
		t.Fatal("UpsertTurn() succeeded after completion")
	}
	if err := store.DeleteConversation(ctx, "user-a", summary.ID); err != nil {
		t.Fatalf("DeleteConversation() error = %v", err)
	}
	if _, err := store.GetConversation(ctx, "user-a", summary.ID); err == nil {
		t.Fatal("GetConversation() succeeded after deletion")
	}
}

func TestStoreTurnBoundsAllowIdempotentRetry(t *testing.T) {
	store := New()
	ctx := context.Background()
	now := time.Now().UTC()
	summary := domain.ConversationSummary{
		ID: "conv_turn_bounds", Status: domain.StatusActive, Preferences: domain.DefaultPreferences(), CreatedAt: now, UpdatedAt: now,
	}
	if err := store.CreateConversation(ctx, "user", summary); err != nil {
		t.Fatal(err)
	}
	for index := 0; index < domain.MaxTurnsPerConversation; index++ {
		turn := domain.Turn{ID: fmt.Sprintf("turn_%08d", index), Role: "user", Text: "Hola", OccurredAt: now}
		if _, err := store.UpsertTurn(ctx, "user", summary.ID, turn); err != nil {
			t.Fatalf("turn %d: %v", index, err)
		}
	}
	retry := domain.Turn{ID: "turn_00000000", Role: "user", Text: "Hola de nou", OccurredAt: now}
	if _, err := store.UpsertTurn(ctx, "user", summary.ID, retry); err != nil {
		t.Fatalf("idempotent retry at cap failed: %v", err)
	}
	if _, err := store.UpsertTurn(ctx, "user", summary.ID, domain.Turn{
		ID: "turn_overflow", Role: "assistant", Text: "Too many", OccurredAt: now,
	}); !isPublicStatus(err, 409) {
		t.Fatalf("new turn above cap error = %v", err)
	}
	detail, err := store.GetConversation(ctx, "user", summary.ID)
	if err != nil || detail.Conversation.TurnCount != domain.MaxTurnsPerConversation || len(detail.Turns) != domain.MaxTurnsPerConversation {
		t.Fatalf("bounded detail = %+v, %v", detail.Conversation, err)
	}
}

func TestStoreRejectsWritesToExpiredConversation(t *testing.T) {
	store := New()
	ctx := context.Background()
	now := time.Now().UTC()
	summary := domain.ConversationSummary{
		ID: "conv_expired_session", Status: domain.StatusActive, Preferences: domain.DefaultPreferences(),
		CreatedAt: now.Add(-domain.MaxActiveConversationAge - time.Second), UpdatedAt: now,
	}
	if err := store.CreateConversation(ctx, "user", summary); err != nil {
		t.Fatal(err)
	}
	if _, err := store.UpsertTurn(ctx, "user", summary.ID, domain.Turn{
		ID: "turn_expired", Role: "user", Text: "Late", OccurredAt: now,
	}); !isPublicStatus(err, 409) {
		t.Fatalf("expired conversation write error = %v", err)
	}
}

func TestCompletionLeaseReleaseAndExpiry(t *testing.T) {
	store := New()
	ctx := context.Background()
	now := time.Now().UTC()
	summary := domain.ConversationSummary{
		ID: "conv_lease_test", Status: domain.StatusActive, Preferences: domain.DefaultPreferences(), CreatedAt: now, UpdatedAt: now,
	}
	if err := store.CreateConversation(ctx, "user", summary); err != nil {
		t.Fatal(err)
	}
	first := domain.CompletionLease{ID: "lease_first", StartedAt: now, ExpiresAt: now.Add(time.Minute)}
	if _, claimed, err := store.ClaimConversationCompletion(ctx, "user", summary.ID, first); err != nil || !claimed {
		t.Fatalf("first claim = %v, %v", claimed, err)
	}
	if err := store.ReleaseConversationCompletion(ctx, "user", summary.ID, "wrong-lease"); err != nil {
		t.Fatal(err)
	}
	if _, _, err := store.ClaimConversationCompletion(ctx, "user", summary.ID, domain.CompletionLease{
		ID: "lease_blocked", StartedAt: now.Add(time.Second), ExpiresAt: now.Add(time.Minute),
	}); err == nil {
		t.Fatal("wrong-token release cleared the active lease")
	}
	if err := store.ReleaseConversationCompletion(ctx, "user", summary.ID, first.ID); err != nil {
		t.Fatal(err)
	}
	second := domain.CompletionLease{ID: "lease_second", StartedAt: now.Add(2 * time.Second), ExpiresAt: now.Add(time.Minute)}
	if _, claimed, err := store.ClaimConversationCompletion(ctx, "user", summary.ID, second); err != nil || !claimed {
		t.Fatalf("claim after release = %v, %v", claimed, err)
	}
	expiredReplacement := domain.CompletionLease{ID: "lease_replacement", StartedAt: second.ExpiresAt, ExpiresAt: second.ExpiresAt.Add(time.Minute)}
	if _, claimed, err := store.ClaimConversationCompletion(ctx, "user", summary.ID, expiredReplacement); err != nil || !claimed {
		t.Fatalf("claim after expiry = %v, %v", claimed, err)
	}
}

func TestStorePagination(t *testing.T) {
	store := New()
	ctx := context.Background()
	for index := 0; index < 3; index++ {
		summary := domain.ConversationSummary{
			ID: "conv_page_" + string(rune('a'+index)), Status: domain.StatusActive, Preferences: domain.DefaultPreferences(),
			CreatedAt: time.Unix(int64(index+1), 0), UpdatedAt: time.Unix(int64(index+1), 0),
		}
		if err := store.CreateConversation(ctx, "user", summary); err != nil {
			t.Fatal(err)
		}
	}
	first, err := store.ListConversations(ctx, "user", "", 2)
	if err != nil || len(first.Items) != 2 || first.NextCursor == "" {
		t.Fatalf("first page = %+v, %v", first, err)
	}
	second, err := store.ListConversations(ctx, "user", first.NextCursor, 2)
	if err != nil || len(second.Items) != 1 || second.NextCursor != "" {
		t.Fatalf("second page = %+v, %v", second, err)
	}
	_, err = store.ListConversations(ctx, "user", "not-a-cursor", 2)
	var public *domain.PublicError
	if !errors.As(err, &public) || public.Status != 400 {
		t.Fatalf("invalid cursor error = %v", err)
	}
}

func isPublicStatus(err error, status int) bool {
	var public *domain.PublicError
	return errors.As(err, &public) && public.Status == status
}
