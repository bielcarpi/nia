package firestorestore

import (
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/bielcarpi/nia/apps/api/internal/domain"
	"google.golang.org/api/option"
)

func TestUserDocumentIDIsStableAndOpaque(t *testing.T) {
	first := userDocumentID("firebase/user@example.com")
	second := userDocumentID("firebase/user@example.com")
	if first != second || len(first) != 43 {
		t.Fatalf("userDocumentID() = %q, %q", first, second)
	}
	if first == "firebase/user@example.com" {
		t.Fatal("userDocumentID() exposed the raw identity")
	}
}

func TestCursorRoundTripIncludesStableTieBreaker(t *testing.T) {
	want := domain.ConversationSummary{ID: "conv_abcdefgh", UpdatedAt: time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)}
	got, err := decodeCursor(encodeCursor(want))
	if err != nil {
		t.Fatalf("decodeCursor() error = %v", err)
	}
	if got.ID != want.ID || !got.UpdatedAt.Equal(want.UpdatedAt) {
		t.Fatalf("decodeCursor() = %+v", got)
	}
}

func TestCursorRejectsMissingTieBreaker(t *testing.T) {
	legacy := base64.RawURLEncoding.EncodeToString([]byte(`{"updated_at":"2026-07-16T12:00:00Z"}`))
	if _, err := decodeCursor(legacy); err == nil {
		t.Fatal("decodeCursor() accepted a cursor without a document ID")
	}
}

func TestFirestoreEmulatorLifecycle(t *testing.T) {
	store := newEmulatorStore(t)
	ctx := context.Background()
	if err := store.Ready(ctx); err != nil {
		t.Fatalf("Ready() error = %v", err)
	}

	preferences := domain.Preferences{TargetLanguage: "ca", Level: "advanced", Topic: "Architecture", CorrectionStyle: "summary"}
	if got, err := store.SavePreferences(ctx, "user-a", preferences); err != nil || got != preferences {
		t.Fatalf("SavePreferences() = %+v, %v", got, err)
	}
	if got, err := store.GetPreferences(ctx, "user-a"); err != nil || got != preferences {
		t.Fatalf("GetPreferences() = %+v, %v", got, err)
	}
	if got, err := store.GetPreferences(ctx, "user-b"); err != nil || got != domain.DefaultPreferences() {
		t.Fatalf("other user's preferences = %+v, %v", got, err)
	}

	base := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	for _, summary := range []domain.ConversationSummary{
		{ID: "conv_page_a", Status: domain.StatusActive, Preferences: preferences, CreatedAt: base, UpdatedAt: base},
		{ID: "conv_page_b", Status: domain.StatusActive, Preferences: preferences, CreatedAt: base, UpdatedAt: base.Add(time.Minute)},
		{ID: "conv_page_c", Status: domain.StatusActive, Preferences: preferences, CreatedAt: base, UpdatedAt: base.Add(time.Minute)},
	} {
		if err := store.CreateConversation(ctx, "user-a", summary); err != nil {
			t.Fatalf("CreateConversation(%s) error = %v", summary.ID, err)
		}
	}
	if _, err := store.GetConversation(ctx, "user-b", "conv_page_b"); !isStatus(err, 404) {
		t.Fatalf("cross-user GetConversation() error = %v", err)
	}
	first, err := store.ListConversations(ctx, "user-a", "", 2)
	if err != nil || len(first.Items) != 2 || first.Items[0].ID != "conv_page_c" || first.Items[1].ID != "conv_page_b" || first.NextCursor == "" {
		t.Fatalf("first page = %+v, %v", first, err)
	}
	second, err := store.ListConversations(ctx, "user-a", first.NextCursor, 2)
	if err != nil || len(second.Items) != 1 || second.Items[0].ID != "conv_page_a" || second.NextCursor != "" {
		t.Fatalf("second page = %+v, %v", second, err)
	}
	if page, err := store.ListConversations(ctx, "user-b", "", 20); err != nil || len(page.Items) != 0 {
		t.Fatalf("other user's list = %+v, %v", page, err)
	}

	turnTime := base.Add(2 * time.Minute)
	for _, turn := range []domain.Turn{
		{ID: "turn_bbbbbbbb", Role: "assistant", Text: "Bon dia", OccurredAt: turnTime},
		{ID: "turn_aaaaaaaa", Role: "user", Text: "Hola", OccurredAt: turnTime},
	} {
		if _, err := store.UpsertTurn(ctx, "user-a", "conv_page_b", turn); err != nil {
			t.Fatalf("UpsertTurn(%s) error = %v", turn.ID, err)
		}
	}
	updated := domain.Turn{ID: "turn_aaaaaaaa", Role: "user", Text: "Hola de nou", OccurredAt: turnTime}
	if _, err := store.UpsertTurn(ctx, "user-a", "conv_page_b", updated); err != nil {
		t.Fatalf("idempotent UpsertTurn() error = %v", err)
	}
	detail, err := store.GetConversation(ctx, "user-a", "conv_page_b")
	if err != nil || detail.Conversation.TurnCount != 2 || len(detail.Turns) != 2 || detail.Turns[0].ID != "turn_aaaaaaaa" || detail.Turns[0].Text != "Hola de nou" {
		t.Fatalf("detail after turns = %+v, %v", detail, err)
	}

	now := time.Now().UTC()
	lease := domain.CompletionLease{ID: "lease_first", StartedAt: now, ExpiresAt: now.Add(time.Minute)}
	if _, claimed, err := store.ClaimConversationCompletion(ctx, "user-a", "conv_page_b", lease); err != nil || !claimed {
		t.Fatalf("ClaimConversationCompletion() = %v, %v", claimed, err)
	}
	if _, _, err := store.ClaimConversationCompletion(ctx, "user-a", "conv_page_b", domain.CompletionLease{
		ID: "lease_second", StartedAt: now.Add(time.Second), ExpiresAt: now.Add(time.Minute),
	}); !isRetryableStatus(err, 409) {
		t.Fatalf("second completion claim error = %v", err)
	}
	if _, err := store.UpsertTurn(ctx, "user-a", "conv_page_b", domain.Turn{ID: "turn_blocked", Role: "user", Text: "Blocked", OccurredAt: turnTime}); !isRetryableStatus(err, 409) {
		t.Fatalf("turn during completion error = %v", err)
	}
	if err := store.DeleteConversation(ctx, "user-a", "conv_page_b"); !isRetryableStatus(err, 409) {
		t.Fatalf("delete during completion error = %v", err)
	}
	if err := store.ReleaseConversationCompletion(ctx, "user-a", "conv_page_b", "wrong"); err != nil {
		t.Fatal(err)
	}
	if _, _, err := store.ClaimConversationCompletion(ctx, "user-a", "conv_page_b", domain.CompletionLease{
		ID: "lease_still_blocked", StartedAt: now.Add(2 * time.Second), ExpiresAt: now.Add(time.Minute),
	}); !isRetryableStatus(err, 409) {
		t.Fatalf("wrong-token release cleared lease: %v", err)
	}
	if err := store.ReleaseConversationCompletion(ctx, "user-a", "conv_page_b", lease.ID); err != nil {
		t.Fatal(err)
	}

	deleteLease := domain.CompletionLease{ID: "delete_test", StartedAt: now.Add(3 * time.Second), ExpiresAt: now.Add(time.Minute)}
	deletionReference := store.conversation("user-a", "conv_page_c")
	if err := store.claimConversationDeletion(ctx, deletionReference, deleteLease); err != nil {
		t.Fatalf("claimConversationDeletion() error = %v", err)
	}
	if _, err := store.GetConversation(ctx, "user-a", "conv_page_c"); !isStatus(err, 404) {
		t.Fatalf("tombstoned conversation remained readable: %v", err)
	}
	visible, err := store.ListConversations(ctx, "user-a", "", 10)
	if err != nil {
		t.Fatalf("ListConversations() with tombstone error = %v", err)
	}
	for _, item := range visible.Items {
		if item.ID == "conv_page_c" {
			t.Fatal("tombstoned conversation remained visible in history")
		}
	}
	if _, _, err := store.ClaimConversationCompletion(ctx, "user-a", "conv_page_c", domain.CompletionLease{
		ID: "lease_delete_blocked", StartedAt: now.Add(4 * time.Second), ExpiresAt: now.Add(time.Minute),
	}); !isRetryableStatus(err, 409) {
		t.Fatalf("completion during deletion error = %v", err)
	}
	if _, err := store.UpsertTurn(ctx, "user-a", "conv_page_c", domain.Turn{ID: "turn_delete_blocked", Role: "user", Text: "Blocked", OccurredAt: turnTime}); !isRetryableStatus(err, 409) {
		t.Fatalf("turn during deletion error = %v", err)
	}
	if err := store.releaseConversationDeletion(ctx, deletionReference, deleteLease.ID); err != nil {
		t.Fatal(err)
	}
	if _, _, err := store.ClaimConversationCompletion(ctx, "user-a", "conv_page_c", domain.CompletionLease{
		ID: "lease_after_release", StartedAt: now.Add(5 * time.Second), ExpiresAt: now.Add(time.Minute),
	}); !isRetryableStatus(err, 409) {
		t.Fatalf("released deletion reopened conversation: %v", err)
	}
	if err := store.DeleteConversation(ctx, "user-a", "conv_page_c"); err != nil {
		t.Fatalf("resume DeleteConversation() error = %v", err)
	}

	completionLease := domain.CompletionLease{ID: "lease_final", StartedAt: now.Add(5 * time.Second), ExpiresAt: now.Add(time.Minute)}
	if _, claimed, err := store.ClaimConversationCompletion(ctx, "user-a", "conv_page_b", completionLease); err != nil || !claimed {
		t.Fatalf("final completion claim = %v, %v", claimed, err)
	}
	feedback := domain.Feedback{Summary: "Molt bé", Strengths: []string{"Clarity"}, NextSteps: []string{"Continue"}, GeneratedAt: now.Add(6 * time.Second)}
	detail, err = store.CompleteConversation(ctx, "user-a", "conv_page_b", completionLease.ID, feedback)
	if err != nil || detail.Conversation.Status != domain.StatusCompleted || detail.Feedback == nil {
		t.Fatalf("CompleteConversation() = %+v, %v", detail, err)
	}
	if _, claimed, err := store.ClaimConversationCompletion(ctx, "user-a", "conv_page_b", domain.CompletionLease{
		ID: "lease_idempotent", StartedAt: now.Add(7 * time.Second), ExpiresAt: now.Add(time.Minute),
	}); err != nil || claimed {
		t.Fatalf("completed claim = %v, %v", claimed, err)
	}
	if _, err := store.UpsertTurn(ctx, "user-a", "conv_page_b", domain.Turn{ID: "turn_late", Role: "user", Text: "Late", OccurredAt: turnTime}); !isStatus(err, 409) {
		t.Fatalf("turn after completion error = %v", err)
	}
	if err := store.DeleteConversation(ctx, "user-a", "conv_page_b"); err != nil {
		t.Fatalf("DeleteConversation() error = %v", err)
	}
	if _, err := store.GetConversation(ctx, "user-a", "conv_page_b"); !isStatus(err, 404) {
		t.Fatalf("GetConversation() after delete error = %v", err)
	}
	reference := store.conversation("user-a", "conv_page_b")
	turnIterator := reference.Collection("turns").Documents(ctx)
	defer turnIterator.Stop()
	if _, err := turnIterator.Next(); !errors.Is(err, iteratorDone) {
		t.Fatalf("turn documents remain after delete: %v", err)
	}
}

func TestFirestoreEmulatorTurnBoundsAreAtomicAndIdempotent(t *testing.T) {
	store := newEmulatorStore(t)
	ctx := context.Background()
	now := time.Now().UTC()
	summary := domain.ConversationSummary{
		ID: "conv_turn_bounds", Status: domain.StatusActive, Preferences: domain.DefaultPreferences(),
		CreatedAt: now, UpdatedAt: now, TurnCount: domain.MaxTurnsPerConversation,
	}
	if err := store.CreateConversation(ctx, "bounded-user", summary); err != nil {
		t.Fatal(err)
	}
	existing := domain.Turn{ID: "turn_existing", Role: "user", Text: "Original", OccurredAt: now}
	if _, err := store.conversation("bounded-user", summary.ID).Collection("turns").Doc(existing.ID).Set(ctx, map[string]any{
		"role": existing.Role, "text": existing.Text, "occurred_at": existing.OccurredAt,
	}); err != nil {
		t.Fatal(err)
	}
	existing.Text = "Retry remains idempotent"
	if _, err := store.UpsertTurn(ctx, "bounded-user", summary.ID, existing); err != nil {
		t.Fatalf("existing turn update at cap failed: %v", err)
	}
	if _, err := store.UpsertTurn(ctx, "bounded-user", summary.ID, domain.Turn{
		ID: "turn_overflow", Role: "assistant", Text: "Too many", OccurredAt: now,
	}); !isStatus(err, 409) {
		t.Fatalf("new turn above cap error = %v", err)
	}
	detail, err := store.GetConversation(ctx, "bounded-user", summary.ID)
	if err != nil || detail.Conversation.TurnCount != domain.MaxTurnsPerConversation || len(detail.Turns) != 1 {
		t.Fatalf("bounded detail = %+v, %v", detail, err)
	}

	expired := domain.ConversationSummary{
		ID: "conv_expired_session", Status: domain.StatusActive, Preferences: domain.DefaultPreferences(),
		CreatedAt: now.Add(-domain.MaxActiveConversationAge - time.Second), UpdatedAt: now,
	}
	if err := store.CreateConversation(ctx, "bounded-user", expired); err != nil {
		t.Fatal(err)
	}
	if _, err := store.UpsertTurn(ctx, "bounded-user", expired.ID, domain.Turn{
		ID: "turn_expired", Role: "user", Text: "Late", OccurredAt: now,
	}); !isStatus(err, 409) {
		t.Fatalf("expired conversation write error = %v", err)
	}
}

func TestFirestoreEmulatorCompletionAndDeletionClaimsAreMutuallyExclusive(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST to run Firestore integration tests")
	}
	projectID := fmt.Sprintf("nia-api-race-%d", time.Now().UnixNano())
	firstStore := newEmulatorStoreForProject(t, projectID)
	secondStore := newEmulatorStoreForProject(t, projectID)
	ctx := context.Background()
	now := time.Now().UTC()
	for index := 0; index < 10; index++ {
		id := fmt.Sprintf("conv_race_%02d", index)
		if err := firstStore.CreateConversation(ctx, "race-user", domain.ConversationSummary{
			ID: id, Status: domain.StatusActive, Preferences: domain.DefaultPreferences(), CreatedAt: now, UpdatedAt: now,
		}); err != nil {
			t.Fatal(err)
		}
		start := make(chan struct{})
		results := make(chan error, 2)
		completionLease := domain.CompletionLease{ID: fmt.Sprintf("completion_%02d", index), StartedAt: now, ExpiresAt: now.Add(time.Minute)}
		deletionLease := domain.CompletionLease{ID: fmt.Sprintf("deletion_%02d", index), StartedAt: now, ExpiresAt: now.Add(time.Minute)}
		go func() {
			<-start
			_, _, err := firstStore.ClaimConversationCompletion(ctx, "race-user", id, completionLease)
			results <- err
		}()
		go func() {
			<-start
			results <- secondStore.claimConversationDeletion(ctx, secondStore.conversation("race-user", id), deletionLease)
		}()
		close(start)
		first, second := <-results, <-results
		if (first == nil) == (second == nil) {
			t.Fatalf("race %d results = %v, %v; exactly one claim must win", index, first, second)
		}
		if first != nil && !isRetryableStatus(first, 409) {
			t.Fatalf("race %d first error = %v", index, first)
		}
		if second != nil && !isRetryableStatus(second, 409) {
			t.Fatalf("race %d second error = %v", index, second)
		}
		_ = firstStore.ReleaseConversationCompletion(ctx, "race-user", id, completionLease.ID)
		_ = secondStore.releaseConversationDeletion(ctx, secondStore.conversation("race-user", id), deletionLease.ID)
		if err := firstStore.DeleteConversation(ctx, "race-user", id); err != nil {
			t.Fatal(err)
		}
	}
}

func newEmulatorStore(t *testing.T) *Store {
	t.Helper()
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST to run Firestore integration tests")
	}
	projectID := fmt.Sprintf("nia-api-test-%d", time.Now().UnixNano())
	return newEmulatorStoreForProject(t, projectID)
}

func newEmulatorStoreForProject(t *testing.T, projectID string) *Store {
	t.Helper()
	ctx := context.Background()
	client, err := firestore.NewClient(ctx, projectID, option.WithoutAuthentication())
	if err != nil {
		t.Fatalf("firestore.NewClient() error = %v", err)
	}
	store, err := New(client)
	if err != nil {
		_ = client.Close()
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = store.Close() })
	return store
}

func isStatus(err error, want int) bool {
	var public *domain.PublicError
	return errors.As(err, &public) && public.Status == want
}

func isRetryableStatus(err error, want int) bool {
	var public *domain.PublicError
	return errors.As(err, &public) && public.Status == want && public.Retryable
}
