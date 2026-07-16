package memory

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"sort"
	"sync"
	"time"

	"github.com/bielcarpi/nia/apps/api/internal/domain"
)

type conversationRecord struct {
	summary  domain.ConversationSummary
	turns    map[string]domain.Turn
	feedback *domain.Feedback
}

type Store struct {
	mu            sync.RWMutex
	preferences   map[string]domain.Preferences
	conversations map[string]map[string]*conversationRecord
}

func New() *Store {
	return &Store{
		preferences:   make(map[string]domain.Preferences),
		conversations: make(map[string]map[string]*conversationRecord),
	}
}

func (s *Store) Ready(context.Context) error { return nil }
func (s *Store) Close() error                { return nil }

func (s *Store) GetPreferences(_ context.Context, uid string) (domain.Preferences, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	preferences, ok := s.preferences[uid]
	if !ok {
		return domain.DefaultPreferences(), nil
	}
	return preferences, nil
}

func (s *Store) SavePreferences(_ context.Context, uid string, preferences domain.Preferences) (domain.Preferences, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.preferences[uid] = preferences
	return preferences, nil
}

func (s *Store) CreateConversation(_ context.Context, uid string, summary domain.ConversationSummary) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.conversations[uid] == nil {
		s.conversations[uid] = make(map[string]*conversationRecord)
	}
	if _, exists := s.conversations[uid][summary.ID]; exists {
		return domain.Conflict("A conversation with that ID already exists.")
	}
	s.conversations[uid][summary.ID] = &conversationRecord{
		summary: summary,
		turns:   make(map[string]domain.Turn),
	}
	return nil
}

func (s *Store) ListConversations(_ context.Context, uid, rawCursor string, limit int) (domain.ConversationPage, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	items := make([]domain.ConversationSummary, 0, len(s.conversations[uid]))
	for _, record := range s.conversations[uid] {
		items = append(items, record.summary)
	}
	sort.Slice(items, func(i, j int) bool {
		if items[i].UpdatedAt.Equal(items[j].UpdatedAt) {
			return items[i].ID > items[j].ID
		}
		return items[i].UpdatedAt.After(items[j].UpdatedAt)
	})

	start := 0
	if rawCursor != "" {
		cursor, err := decodeCursor(rawCursor)
		if err != nil {
			return domain.ConversationPage{}, domain.ValidationError("cursor", "is invalid")
		}
		start = len(items)
		for index, item := range items {
			if item.ID == cursor.ID && item.UpdatedAt.Equal(cursor.UpdatedAt) {
				start = index + 1
				break
			}
		}
	}
	if start > len(items) {
		start = len(items)
	}
	end := start + limit
	if end > len(items) {
		end = len(items)
	}
	page := domain.ConversationPage{Items: append([]domain.ConversationSummary(nil), items[start:end]...)}
	if end < len(items) && end > start {
		page.NextCursor = encodeCursor(items[end-1])
	}
	return page, nil
}

func (s *Store) GetConversation(_ context.Context, uid, id string) (domain.ConversationDetail, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	record := s.record(uid, id)
	if record == nil {
		return domain.ConversationDetail{}, domain.NotFound()
	}
	return copyDetail(record), nil
}

func (s *Store) UpsertTurn(_ context.Context, uid, conversationID string, turn domain.Turn) (domain.Turn, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	record := s.record(uid, conversationID)
	if record == nil {
		return domain.Turn{}, domain.NotFound()
	}
	if record.summary.Status == domain.StatusCompleted {
		return domain.Turn{}, domain.Conflict("Completed conversations cannot be changed.")
	}
	if _, exists := record.turns[turn.ID]; !exists {
		record.summary.TurnCount++
	}
	record.turns[turn.ID] = turn
	record.summary.UpdatedAt = time.Now().UTC()
	return turn, nil
}

func (s *Store) CompleteConversation(_ context.Context, uid, id string, feedback domain.Feedback) (domain.ConversationDetail, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	record := s.record(uid, id)
	if record == nil {
		return domain.ConversationDetail{}, domain.NotFound()
	}
	feedbackCopy := copyFeedback(feedback)
	record.feedback = &feedbackCopy
	record.summary.Status = domain.StatusCompleted
	record.summary.UpdatedAt = feedback.GeneratedAt.UTC()
	return copyDetail(record), nil
}

func (s *Store) DeleteConversation(_ context.Context, uid, id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.record(uid, id) == nil {
		return domain.NotFound()
	}
	delete(s.conversations[uid], id)
	return nil
}

func (s *Store) record(uid, id string) *conversationRecord {
	if s.conversations[uid] == nil {
		return nil
	}
	return s.conversations[uid][id]
}

func copyDetail(record *conversationRecord) domain.ConversationDetail {
	turns := make([]domain.Turn, 0, len(record.turns))
	for _, turn := range record.turns {
		turns = append(turns, turn)
	}
	sort.Slice(turns, func(i, j int) bool {
		if turns[i].OccurredAt.Equal(turns[j].OccurredAt) {
			return turns[i].ID < turns[j].ID
		}
		return turns[i].OccurredAt.Before(turns[j].OccurredAt)
	})
	detail := domain.ConversationDetail{Conversation: record.summary, Turns: turns}
	if record.feedback != nil {
		feedback := copyFeedback(*record.feedback)
		detail.Feedback = &feedback
	}
	return detail
}

func copyFeedback(feedback domain.Feedback) domain.Feedback {
	feedback.Strengths = append([]string(nil), feedback.Strengths...)
	feedback.Corrections = append([]domain.Correction(nil), feedback.Corrections...)
	feedback.NextSteps = append([]string(nil), feedback.NextSteps...)
	return feedback
}

type cursor struct {
	ID        string    `json:"id"`
	UpdatedAt time.Time `json:"updated_at"`
}

func encodeCursor(summary domain.ConversationSummary) string {
	encoded, _ := json.Marshal(cursor{ID: summary.ID, UpdatedAt: summary.UpdatedAt})
	return base64.RawURLEncoding.EncodeToString(encoded)
}

func decodeCursor(value string) (cursor, error) {
	decoded, err := base64.RawURLEncoding.DecodeString(value)
	if err != nil {
		return cursor{}, err
	}
	var parsed cursor
	if err := json.Unmarshal(decoded, &parsed); err != nil || parsed.ID == "" || parsed.UpdatedAt.IsZero() {
		return cursor{}, domain.ValidationError("cursor", "is invalid")
	}
	return parsed, nil
}
