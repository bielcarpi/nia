package memory

import (
	"context"
	"errors"
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
	feedback := domain.Feedback{Summary: "Good", Strengths: []string{"Clear"}, NextSteps: []string{"Continue"}, GeneratedAt: now.Add(time.Minute)}
	detail, err = store.CompleteConversation(ctx, "user-a", summary.ID, feedback)
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
