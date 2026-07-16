package firestorestore

import (
	"encoding/base64"
	"testing"
	"time"

	"github.com/bielcarpi/nia/apps/api/internal/domain"
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
