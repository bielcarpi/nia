package firestorestore

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/bielcarpi/nia/apps/api/internal/domain"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type Store struct {
	client *firestore.Client
}

func New(client *firestore.Client) (*Store, error) {
	if client == nil {
		return nil, errors.New("firestore client is required")
	}
	return &Store{client: client}, nil
}

func (s *Store) Ready(ctx context.Context) error {
	_, err := s.client.Collection("_nia_health").Doc("ready").Get(ctx)
	if status.Code(err) == codes.NotFound {
		return nil
	}
	return err
}

func (s *Store) Close() error { return s.client.Close() }

func (s *Store) GetPreferences(ctx context.Context, uid string) (domain.Preferences, error) {
	snapshot, err := s.user(uid).Get(ctx)
	if status.Code(err) == codes.NotFound {
		return domain.DefaultPreferences(), nil
	}
	if err != nil {
		return domain.Preferences{}, fmt.Errorf("get preferences: %w", err)
	}
	var document struct {
		Preferences domain.Preferences `firestore:"preferences"`
	}
	if err := snapshot.DataTo(&document); err != nil {
		return domain.Preferences{}, fmt.Errorf("decode preferences: %w", err)
	}
	if err := document.Preferences.Validate(); err != nil {
		return domain.Preferences{}, fmt.Errorf("stored preferences are invalid: %w", err)
	}
	return document.Preferences, nil
}

func (s *Store) SavePreferences(ctx context.Context, uid string, preferences domain.Preferences) (domain.Preferences, error) {
	_, err := s.user(uid).Set(ctx, map[string]any{
		"preferences": preferences,
		"updated_at":  firestore.ServerTimestamp,
	}, firestore.MergeAll)
	if err != nil {
		return domain.Preferences{}, fmt.Errorf("save preferences: %w", err)
	}
	return preferences, nil
}

func (s *Store) CreateConversation(ctx context.Context, uid string, summary domain.ConversationSummary) error {
	_, err := s.conversation(uid, summary.ID).Create(ctx, conversationDocument{
		Status:      summary.Status,
		Preferences: summary.Preferences,
		TurnCount:   summary.TurnCount,
		CreatedAt:   summary.CreatedAt,
		UpdatedAt:   summary.UpdatedAt,
	})
	if status.Code(err) == codes.AlreadyExists {
		return domain.Conflict("A conversation with that ID already exists.")
	}
	if err != nil {
		return fmt.Errorf("create conversation: %w", err)
	}
	return nil
}

func (s *Store) ListConversations(ctx context.Context, uid, rawCursor string, limit int) (domain.ConversationPage, error) {
	query := s.conversations(uid).
		OrderBy("updated_at", firestore.Desc).
		OrderBy(firestore.DocumentID, firestore.Desc).
		Limit(limit + 1)
	if rawCursor != "" {
		cursor, err := decodeCursor(rawCursor)
		if err != nil {
			return domain.ConversationPage{}, domain.ValidationError("cursor", "is invalid")
		}
		query = query.StartAfter(cursor.UpdatedAt, cursor.ID)
	}
	iterator := query.Documents(ctx)
	defer iterator.Stop()

	items := make([]domain.ConversationSummary, 0, limit+1)
	for {
		snapshot, err := iterator.Next()
		if err == iteratorDone {
			break
		}
		if err != nil {
			return domain.ConversationPage{}, fmt.Errorf("list conversations: %w", err)
		}
		summary, err := summaryFromSnapshot(snapshot)
		if err != nil {
			return domain.ConversationPage{}, err
		}
		items = append(items, summary)
	}
	page := domain.ConversationPage{Items: items}
	if len(items) > limit {
		page.Items = items[:limit]
		page.NextCursor = encodeCursor(items[limit-1])
	}
	return page, nil
}

func (s *Store) GetConversation(ctx context.Context, uid, id string) (domain.ConversationDetail, error) {
	reference := s.conversation(uid, id)
	snapshot, err := reference.Get(ctx)
	if status.Code(err) == codes.NotFound {
		return domain.ConversationDetail{}, domain.NotFound()
	}
	if err != nil {
		return domain.ConversationDetail{}, fmt.Errorf("get conversation: %w", err)
	}
	summary, feedback, err := detailFromSnapshot(snapshot)
	if err != nil {
		return domain.ConversationDetail{}, err
	}

	turnIterator := reference.Collection("turns").OrderBy("occurred_at", firestore.Asc).Documents(ctx)
	defer turnIterator.Stop()
	turns := make([]domain.Turn, 0, summary.TurnCount)
	for {
		turnSnapshot, err := turnIterator.Next()
		if err == iteratorDone {
			break
		}
		if err != nil {
			return domain.ConversationDetail{}, fmt.Errorf("list turns: %w", err)
		}
		var turn domain.Turn
		if err := turnSnapshot.DataTo(&turn); err != nil {
			return domain.ConversationDetail{}, fmt.Errorf("decode turn: %w", err)
		}
		turn.ID = turnSnapshot.Ref.ID
		turns = append(turns, turn)
	}
	return domain.ConversationDetail{Conversation: summary, Turns: turns, Feedback: feedback}, nil
}

func (s *Store) UpsertTurn(ctx context.Context, uid, conversationID string, turn domain.Turn) (domain.Turn, error) {
	conversationReference := s.conversation(uid, conversationID)
	turnReference := conversationReference.Collection("turns").Doc(turn.ID)
	err := s.client.RunTransaction(ctx, func(ctx context.Context, transaction *firestore.Transaction) error {
		conversationSnapshot, err := transaction.Get(conversationReference)
		if status.Code(err) == codes.NotFound {
			return domain.NotFound()
		}
		if err != nil {
			return err
		}
		var document conversationDocument
		if err := conversationSnapshot.DataTo(&document); err != nil {
			return err
		}
		if document.Status == domain.StatusCompleted {
			return domain.Conflict("Completed conversations cannot be changed.")
		}

		_, turnErr := transaction.Get(turnReference)
		isNew := status.Code(turnErr) == codes.NotFound
		if turnErr != nil && !isNew {
			return turnErr
		}
		if err := transaction.Set(turnReference, map[string]any{
			"role":        turn.Role,
			"text":        turn.Text,
			"occurred_at": turn.OccurredAt,
		}); err != nil {
			return err
		}
		updates := []firestore.Update{{Path: "updated_at", Value: time.Now().UTC()}}
		if isNew {
			updates = append(updates, firestore.Update{Path: "turn_count", Value: firestore.Increment(1)})
		}
		return transaction.Update(conversationReference, updates)
	})
	if err != nil {
		return domain.Turn{}, fmt.Errorf("upsert turn: %w", err)
	}
	return turn, nil
}

func (s *Store) CompleteConversation(ctx context.Context, uid, id string, feedback domain.Feedback) (domain.ConversationDetail, error) {
	reference := s.conversation(uid, id)
	_, err := reference.Update(ctx, []firestore.Update{
		{Path: "status", Value: domain.StatusCompleted},
		{Path: "feedback", Value: feedback},
		{Path: "updated_at", Value: feedback.GeneratedAt},
	})
	if status.Code(err) == codes.NotFound {
		return domain.ConversationDetail{}, domain.NotFound()
	}
	if err != nil {
		return domain.ConversationDetail{}, fmt.Errorf("complete conversation: %w", err)
	}
	return s.GetConversation(ctx, uid, id)
}

func (s *Store) DeleteConversation(ctx context.Context, uid, id string) error {
	reference := s.conversation(uid, id)
	if _, err := reference.Get(ctx); status.Code(err) == codes.NotFound {
		return domain.NotFound()
	} else if err != nil {
		return fmt.Errorf("get conversation before delete: %w", err)
	}

	iterator := reference.Collection("turns").Documents(ctx)
	bulkWriter := s.client.BulkWriter(ctx)
	jobs := make([]*firestore.BulkWriterJob, 0)
	for {
		snapshot, err := iterator.Next()
		if err == iteratorDone {
			break
		}
		if err != nil {
			iterator.Stop()
			bulkWriter.End()
			return fmt.Errorf("list turns for delete: %w", err)
		}
		job, err := bulkWriter.Delete(snapshot.Ref)
		if err != nil {
			iterator.Stop()
			bulkWriter.End()
			return fmt.Errorf("queue turn delete: %w", err)
		}
		jobs = append(jobs, job)
	}
	iterator.Stop()
	bulkWriter.End()
	for _, job := range jobs {
		if _, err := job.Results(); err != nil {
			return fmt.Errorf("delete turn: %w", err)
		}
	}
	if _, err := reference.Delete(ctx); err != nil {
		return fmt.Errorf("delete conversation: %w", err)
	}
	return nil
}

type conversationDocument struct {
	Status      string             `firestore:"status"`
	Preferences domain.Preferences `firestore:"preferences"`
	TurnCount   int                `firestore:"turn_count"`
	CreatedAt   time.Time          `firestore:"created_at"`
	UpdatedAt   time.Time          `firestore:"updated_at"`
	Feedback    *domain.Feedback   `firestore:"feedback,omitempty"`
}

func summaryFromSnapshot(snapshot *firestore.DocumentSnapshot) (domain.ConversationSummary, error) {
	var document conversationDocument
	if err := snapshot.DataTo(&document); err != nil {
		return domain.ConversationSummary{}, fmt.Errorf("decode conversation: %w", err)
	}
	return domain.ConversationSummary{
		ID:          snapshot.Ref.ID,
		Status:      document.Status,
		Preferences: document.Preferences,
		TurnCount:   document.TurnCount,
		CreatedAt:   document.CreatedAt,
		UpdatedAt:   document.UpdatedAt,
	}, nil
}

func detailFromSnapshot(snapshot *firestore.DocumentSnapshot) (domain.ConversationSummary, *domain.Feedback, error) {
	var document conversationDocument
	if err := snapshot.DataTo(&document); err != nil {
		return domain.ConversationSummary{}, nil, fmt.Errorf("decode conversation: %w", err)
	}
	summary := domain.ConversationSummary{
		ID:          snapshot.Ref.ID,
		Status:      document.Status,
		Preferences: document.Preferences,
		TurnCount:   document.TurnCount,
		CreatedAt:   document.CreatedAt,
		UpdatedAt:   document.UpdatedAt,
	}
	return summary, document.Feedback, nil
}

func (s *Store) user(uid string) *firestore.DocumentRef {
	return s.client.Collection("users").Doc(userDocumentID(uid))
}

func userDocumentID(uid string) string {
	digest := sha256.Sum256([]byte(uid))
	return base64.RawURLEncoding.EncodeToString(digest[:])
}

func (s *Store) conversations(uid string) *firestore.CollectionRef {
	return s.user(uid).Collection("conversations")
}

func (s *Store) conversation(uid, id string) *firestore.DocumentRef {
	return s.conversations(uid).Doc(id)
}

type cursor struct {
	ID        string    `json:"id"`
	UpdatedAt time.Time `json:"updated_at"`
}

func encodeCursor(summary domain.ConversationSummary) string {
	encoded, _ := json.Marshal(cursor{ID: summary.ID, UpdatedAt: summary.UpdatedAt})
	return base64.RawURLEncoding.EncodeToString(encoded)
}

func decodeCursor(raw string) (cursor, error) {
	decoded, err := base64.RawURLEncoding.DecodeString(raw)
	if err != nil {
		return cursor{}, err
	}
	var parsed cursor
	if err := json.Unmarshal(decoded, &parsed); err != nil || parsed.ID == "" || parsed.UpdatedAt.IsZero() {
		return cursor{}, errors.New("invalid cursor")
	}
	return parsed, nil
}

var iteratorDone = iterator.Done
