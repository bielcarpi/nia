package firestorestore

import (
	"context"
	"crypto/rand"
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
	baseQuery := s.conversations(uid).
		OrderBy("updated_at", firestore.Desc).
		OrderBy(firestore.DocumentID, firestore.Desc)
	var next cursor
	if rawCursor != "" {
		parsed, err := decodeCursor(rawCursor)
		if err != nil {
			return domain.ConversationPage{}, domain.ValidationError("cursor", "is invalid")
		}
		next = parsed
	}

	items := make([]domain.ConversationSummary, 0, limit+1)
	for len(items) < limit+1 {
		query := baseQuery.Limit(limit + 1)
		if !next.UpdatedAt.IsZero() {
			query = query.StartAfter(next.UpdatedAt, next.ID)
		}
		iterator := query.Documents(ctx)
		scanned := 0
		for {
			snapshot, err := iterator.Next()
			if err == iteratorDone {
				break
			}
			if err != nil {
				iterator.Stop()
				return domain.ConversationPage{}, fmt.Errorf("list conversations: %w", err)
			}
			document, err := documentFromSnapshot(snapshot)
			if err != nil {
				iterator.Stop()
				return domain.ConversationPage{}, err
			}
			scanned++
			next = cursor{ID: snapshot.Ref.ID, UpdatedAt: document.UpdatedAt}
			if document.DeletionStartedAt != nil {
				continue
			}
			items = append(items, summaryFromDocument(snapshot.Ref.ID, document))
			if len(items) == limit+1 {
				break
			}
		}
		iterator.Stop()
		if scanned < limit+1 {
			break
		}
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
	document, err := documentFromSnapshot(snapshot)
	if err != nil {
		return domain.ConversationDetail{}, err
	}
	if document.DeletionStartedAt != nil {
		return domain.ConversationDetail{}, domain.NotFound()
	}
	summary := summaryFromDocument(snapshot.Ref.ID, document)

	turnIterator := reference.Collection("turns").
		OrderBy("occurred_at", firestore.Asc).
		OrderBy(firestore.DocumentID, firestore.Asc).
		Documents(ctx)
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
	return domain.ConversationDetail{Conversation: summary, Turns: turns, Feedback: document.Feedback}, nil
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
		now := time.Now().UTC()
		if now.After(document.CreatedAt.Add(domain.MaxActiveConversationAge)) {
			return domain.Conflict("This practice session has expired. Start a new conversation to continue.")
		}
		if document.DeletionStartedAt != nil || document.DeletionLease != nil && document.DeletionLease.ExpiresAt.After(now) {
			return domain.DeletionInProgress()
		}
		if document.CompletionLease != nil && document.CompletionLease.ExpiresAt.After(now) {
			return domain.CompletionInProgress()
		}

		_, turnErr := transaction.Get(turnReference)
		isNew := status.Code(turnErr) == codes.NotFound
		if turnErr != nil && !isNew {
			return turnErr
		}
		if isNew && document.TurnCount >= domain.MaxTurnsPerConversation {
			return domain.Conflict("This conversation reached its 200-turn limit. Complete it or start a new one.")
		}
		if err := transaction.Set(turnReference, map[string]any{
			"role":        turn.Role,
			"text":        turn.Text,
			"occurred_at": turn.OccurredAt,
		}); err != nil {
			return err
		}
		updates := []firestore.Update{{Path: "updated_at", Value: now}}
		if isNew {
			updates = append(updates, firestore.Update{Path: "turn_count", Value: firestore.Increment(1)})
		}
		if document.CompletionLease != nil {
			updates = append(updates, firestore.Update{Path: "completion_lease", Value: firestore.Delete})
		}
		if document.DeletionLease != nil {
			updates = append(updates, firestore.Update{Path: "deletion_lease", Value: firestore.Delete})
		}
		return transaction.Update(conversationReference, updates)
	})
	if err != nil {
		return domain.Turn{}, fmt.Errorf("upsert turn: %w", err)
	}
	return turn, nil
}

func (s *Store) ClaimConversationCompletion(ctx context.Context, uid, id string, lease domain.CompletionLease) (domain.ConversationDetail, bool, error) {
	reference := s.conversation(uid, id)
	claimed := false
	err := s.client.RunTransaction(ctx, func(ctx context.Context, transaction *firestore.Transaction) error {
		// RunTransaction may invoke this callback more than once.
		claimed = false
		snapshot, err := transaction.Get(reference)
		if status.Code(err) == codes.NotFound {
			return domain.NotFound()
		}
		if err != nil {
			return err
		}
		var document conversationDocument
		if err := snapshot.DataTo(&document); err != nil {
			return err
		}
		if document.Status == domain.StatusCompleted && document.Feedback != nil {
			return nil
		}
		if document.DeletionStartedAt != nil || document.DeletionLease != nil && document.DeletionLease.ExpiresAt.After(lease.StartedAt) {
			return domain.DeletionInProgress()
		}
		if document.CompletionLease != nil && document.CompletionLease.ExpiresAt.After(lease.StartedAt) {
			return domain.CompletionInProgress()
		}
		updates := []firestore.Update{{Path: "completion_lease", Value: lease}}
		if document.DeletionLease != nil {
			updates = append(updates, firestore.Update{Path: "deletion_lease", Value: firestore.Delete})
		}
		if err := transaction.Update(reference, updates); err != nil {
			return err
		}
		claimed = true
		return nil
	})
	if err != nil {
		return domain.ConversationDetail{}, false, fmt.Errorf("claim conversation completion: %w", err)
	}
	detail, err := s.GetConversation(ctx, uid, id)
	if err != nil {
		if claimed {
			releaseCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 2*time.Second)
			defer cancel()
			_ = s.ReleaseConversationCompletion(releaseCtx, uid, id, lease.ID)
		}
		return domain.ConversationDetail{}, false, err
	}
	return detail, claimed, nil
}

func (s *Store) CompleteConversation(ctx context.Context, uid, id, leaseID string, feedback domain.Feedback) (domain.ConversationDetail, error) {
	reference := s.conversation(uid, id)
	err := s.client.RunTransaction(ctx, func(ctx context.Context, transaction *firestore.Transaction) error {
		snapshot, err := transaction.Get(reference)
		if status.Code(err) == codes.NotFound {
			return domain.NotFound()
		}
		if err != nil {
			return err
		}
		var document conversationDocument
		if err := snapshot.DataTo(&document); err != nil {
			return err
		}
		if document.Status == domain.StatusCompleted && document.Feedback != nil {
			return nil
		}
		if document.CompletionLease == nil || document.CompletionLease.ID != leaseID {
			return domain.CompletionInProgress()
		}
		return transaction.Update(reference, []firestore.Update{
			{Path: "status", Value: domain.StatusCompleted},
			{Path: "feedback", Value: feedback},
			{Path: "updated_at", Value: feedback.GeneratedAt},
			{Path: "completion_lease", Value: firestore.Delete},
		})
	})
	if err != nil {
		return domain.ConversationDetail{}, fmt.Errorf("complete conversation: %w", err)
	}
	return s.GetConversation(ctx, uid, id)
}

func (s *Store) ReleaseConversationCompletion(ctx context.Context, uid, id, leaseID string) error {
	reference := s.conversation(uid, id)
	err := s.client.RunTransaction(ctx, func(ctx context.Context, transaction *firestore.Transaction) error {
		snapshot, err := transaction.Get(reference)
		if status.Code(err) == codes.NotFound {
			return nil
		}
		if err != nil {
			return err
		}
		var document conversationDocument
		if err := snapshot.DataTo(&document); err != nil {
			return err
		}
		if document.Status == domain.StatusCompleted || document.CompletionLease == nil || document.CompletionLease.ID != leaseID {
			return nil
		}
		return transaction.Update(reference, []firestore.Update{{Path: "completion_lease", Value: firestore.Delete}})
	})
	if err != nil {
		return fmt.Errorf("release conversation completion: %w", err)
	}
	return nil
}

func (s *Store) DeleteConversation(ctx context.Context, uid, id string) error {
	reference := s.conversation(uid, id)
	now := time.Now().UTC()
	leaseID, err := randomLeaseID("delete_")
	if err != nil {
		return fmt.Errorf("create deletion lease: %w", err)
	}
	lease := domain.CompletionLease{ID: leaseID, StartedAt: now, ExpiresAt: now.Add(5 * time.Minute)}
	if err := s.claimConversationDeletion(ctx, reference, lease); err != nil {
		return err
	}
	releaseLease := true
	defer func() {
		if !releaseLease {
			return
		}
		releaseCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 2*time.Second)
		defer cancel()
		_ = s.releaseConversationDeletion(releaseCtx, reference, lease.ID)
	}()

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
		// From this point onward a failed request may have deleted only part of
		// the transcript. Keep the marker until it expires instead of reopening
		// a partially deleted conversation for writes.
		releaseLease = false
		jobs = append(jobs, job)
	}
	iterator.Stop()
	bulkWriter.End()
	for _, job := range jobs {
		if _, err := job.Results(); err != nil {
			return fmt.Errorf("delete turn: %w", err)
		}
	}
	if err := s.finishConversationDeletion(ctx, reference, lease.ID); err != nil {
		return err
	}
	releaseLease = false
	return nil
}

func (s *Store) claimConversationDeletion(ctx context.Context, reference *firestore.DocumentRef, lease domain.CompletionLease) error {
	err := s.client.RunTransaction(ctx, func(ctx context.Context, transaction *firestore.Transaction) error {
		snapshot, err := transaction.Get(reference)
		if status.Code(err) == codes.NotFound {
			return domain.NotFound()
		}
		if err != nil {
			return err
		}
		var document conversationDocument
		if err := snapshot.DataTo(&document); err != nil {
			return err
		}
		if document.CompletionLease != nil && document.CompletionLease.ExpiresAt.After(lease.StartedAt) {
			return domain.CompletionInProgress()
		}
		if document.DeletionLease != nil && document.DeletionLease.ExpiresAt.After(lease.StartedAt) {
			return domain.DeletionInProgress()
		}
		updates := []firestore.Update{{Path: "deletion_lease", Value: lease}}
		if document.DeletionStartedAt == nil {
			updates = append(updates, firestore.Update{Path: "deletion_started_at", Value: lease.StartedAt})
		}
		if document.CompletionLease != nil {
			updates = append(updates, firestore.Update{Path: "completion_lease", Value: firestore.Delete})
		}
		return transaction.Update(reference, updates)
	})
	if err != nil {
		return fmt.Errorf("claim conversation deletion: %w", err)
	}
	return nil
}

func (s *Store) releaseConversationDeletion(ctx context.Context, reference *firestore.DocumentRef, leaseID string) error {
	err := s.client.RunTransaction(ctx, func(ctx context.Context, transaction *firestore.Transaction) error {
		snapshot, err := transaction.Get(reference)
		if status.Code(err) == codes.NotFound {
			return nil
		}
		if err != nil {
			return err
		}
		var document conversationDocument
		if err := snapshot.DataTo(&document); err != nil {
			return err
		}
		if document.DeletionLease == nil || document.DeletionLease.ID != leaseID {
			return nil
		}
		return transaction.Update(reference, []firestore.Update{{Path: "deletion_lease", Value: firestore.Delete}})
	})
	if err != nil {
		return fmt.Errorf("release conversation deletion: %w", err)
	}
	return nil
}

func (s *Store) finishConversationDeletion(ctx context.Context, reference *firestore.DocumentRef, leaseID string) error {
	err := s.client.RunTransaction(ctx, func(ctx context.Context, transaction *firestore.Transaction) error {
		snapshot, err := transaction.Get(reference)
		if status.Code(err) == codes.NotFound {
			return nil
		}
		if err != nil {
			return err
		}
		var document conversationDocument
		if err := snapshot.DataTo(&document); err != nil {
			return err
		}
		if document.DeletionLease == nil || document.DeletionLease.ID != leaseID {
			return domain.DeletionInProgress()
		}
		return transaction.Delete(reference)
	})
	if err != nil {
		return fmt.Errorf("delete conversation: %w", err)
	}
	return nil
}

func randomLeaseID(prefix string) (string, error) {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "", err
	}
	return prefix + base64.RawURLEncoding.EncodeToString(raw[:]), nil
}

type conversationDocument struct {
	Status            string                  `firestore:"status"`
	Preferences       domain.Preferences      `firestore:"preferences"`
	TurnCount         int                     `firestore:"turn_count"`
	CreatedAt         time.Time               `firestore:"created_at"`
	UpdatedAt         time.Time               `firestore:"updated_at"`
	Feedback          *domain.Feedback        `firestore:"feedback,omitempty"`
	CompletionLease   *domain.CompletionLease `firestore:"completion_lease,omitempty"`
	DeletionLease     *domain.CompletionLease `firestore:"deletion_lease,omitempty"`
	DeletionStartedAt *time.Time              `firestore:"deletion_started_at,omitempty"`
}

func documentFromSnapshot(snapshot *firestore.DocumentSnapshot) (conversationDocument, error) {
	var document conversationDocument
	if err := snapshot.DataTo(&document); err != nil {
		return conversationDocument{}, fmt.Errorf("decode conversation: %w", err)
	}
	return document, nil
}

func summaryFromDocument(id string, document conversationDocument) domain.ConversationSummary {
	return domain.ConversationSummary{
		ID:          id,
		Status:      document.Status,
		Preferences: document.Preferences,
		TurnCount:   document.TurnCount,
		CreatedAt:   document.CreatedAt,
		UpdatedAt:   document.UpdatedAt,
	}
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
