package service

import (
	"context"
	"crypto/rand"
	"encoding/base32"
	"fmt"
	"strings"
	"time"

	"github.com/bielcarpi/nia/apps/api/internal/domain"
)

type Service struct {
	store           domain.ConversationStore
	issuer          domain.RealtimeSessionIssuer
	feedback        domain.FeedbackGenerator
	realtime        domain.RealtimeConnection
	sessionLimiter  *WindowLimiter
	feedbackLimiter *WindowLimiter
	now             func() time.Time
}

type Options struct {
	Store                domain.ConversationStore
	Issuer               domain.RealtimeSessionIssuer
	Feedback             domain.FeedbackGenerator
	Realtime             domain.RealtimeConnection
	SessionLimitPerHour  int
	FeedbackLimitPerHour int
}

func New(options Options) (*Service, error) {
	if options.Store == nil || options.Issuer == nil || options.Feedback == nil {
		return nil, fmt.Errorf("service dependencies must not be nil")
	}
	if options.Realtime.Transport != domain.TransportDemo && options.Realtime.Transport != domain.TransportWebRTC {
		return nil, fmt.Errorf("unsupported realtime transport %q", options.Realtime.Transport)
	}
	return &Service{
		store:           options.Store,
		issuer:          options.Issuer,
		feedback:        options.Feedback,
		realtime:        options.Realtime,
		sessionLimiter:  NewWindowLimiter(options.SessionLimitPerHour, time.Hour),
		feedbackLimiter: NewWindowLimiter(options.FeedbackLimitPerHour, time.Hour),
		now:             time.Now,
	}, nil
}

func (s *Service) Ready(ctx context.Context) error { return s.store.Ready(ctx) }

func (s *Service) GetPreferences(ctx context.Context, uid string) (domain.Preferences, error) {
	return s.store.GetPreferences(ctx, uid)
}

func (s *Service) PatchPreferences(ctx context.Context, uid string, patch domain.PreferencesPatch) (domain.Preferences, error) {
	if patch.Empty() {
		return domain.Preferences{}, domain.ValidationError("body", "must include at least one preference")
	}
	current, err := s.store.GetPreferences(ctx, uid)
	if err != nil {
		return domain.Preferences{}, err
	}
	updated := patch.Apply(current)
	if err := updated.Validate(); err != nil {
		return domain.Preferences{}, err
	}
	return s.store.SavePreferences(ctx, uid, updated)
}

func (s *Service) CreateSession(ctx context.Context, uid string, preferences domain.Preferences) (domain.RealtimeGrant, error) {
	preferences = preferences.Normalized()
	if err := preferences.Validate(); err != nil {
		return domain.RealtimeGrant{}, err
	}
	if !s.sessionLimiter.Allow(uid) {
		return domain.RealtimeGrant{}, domain.RateLimited()
	}

	now := s.now().UTC()
	conversation := domain.ConversationSummary{
		ID:          newID("conv_"),
		Status:      domain.StatusActive,
		Preferences: preferences,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	if err := s.store.CreateConversation(ctx, uid, conversation); err != nil {
		return domain.RealtimeGrant{}, err
	}

	secret, err := s.issuer.Issue(ctx, uid, preferences)
	if err != nil {
		// Do not leave a misleading active record when issuance never succeeded.
		cleanupCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 2*time.Second)
		defer cancel()
		_ = s.store.DeleteConversation(cleanupCtx, uid, conversation.ID)
		return domain.RealtimeGrant{}, err
	}
	grant := domain.RealtimeGrant{
		Conversation: conversation,
		Realtime:     s.realtime,
	}
	if secret.Value != "" {
		grant.ClientSecret = &domain.ClientSecret{Value: secret.Value, ExpiresAt: secret.ExpiresAt}
		if secret.Model != "" {
			grant.Realtime.Model = secret.Model
		}
	}
	return grant, nil
}

func (s *Service) ListConversations(ctx context.Context, uid, cursor string, limit int) (domain.ConversationPage, error) {
	if limit == 0 {
		limit = 20
	}
	if limit < 1 || limit > 50 {
		return domain.ConversationPage{}, domain.ValidationError("limit", "must be between 1 and 50")
	}
	return s.store.ListConversations(ctx, uid, cursor, limit)
}

func (s *Service) GetConversation(ctx context.Context, uid, id string) (domain.ConversationDetail, error) {
	if err := validateID("conversation_id", id); err != nil {
		return domain.ConversationDetail{}, err
	}
	return s.store.GetConversation(ctx, uid, id)
}

func (s *Service) UpsertTurn(ctx context.Context, uid, conversationID string, turn domain.Turn) (domain.Turn, error) {
	if err := validateID("conversation_id", conversationID); err != nil {
		return domain.Turn{}, err
	}
	turn.Text = strings.TrimSpace(turn.Text)
	if err := turn.Validate(); err != nil {
		return domain.Turn{}, err
	}
	return s.store.UpsertTurn(ctx, uid, conversationID, turn)
}

func (s *Service) CompleteConversation(ctx context.Context, uid, id string) (domain.ConversationDetail, error) {
	if err := validateID("conversation_id", id); err != nil {
		return domain.ConversationDetail{}, err
	}
	detail, err := s.store.GetConversation(ctx, uid, id)
	if err != nil {
		return domain.ConversationDetail{}, err
	}
	if detail.Feedback != nil && detail.Conversation.Status == domain.StatusCompleted {
		return detail, nil
	}
	hasLearnerTurn := false
	for _, turn := range detail.Turns {
		if turn.Role == "user" {
			hasLearnerTurn = true
			break
		}
	}
	if !hasLearnerTurn {
		return domain.ConversationDetail{}, domain.Conflict("Add at least one learner turn before completing the conversation.")
	}
	if !s.feedbackLimiter.Allow(uid) {
		return domain.ConversationDetail{}, domain.RateLimited()
	}
	feedback, err := s.feedback.Generate(ctx, uid, detail)
	if err != nil {
		return domain.ConversationDetail{}, err
	}
	if feedback.GeneratedAt.IsZero() {
		feedback.GeneratedAt = s.now().UTC()
	}
	return s.store.CompleteConversation(ctx, uid, id, feedback)
}

func (s *Service) DeleteConversation(ctx context.Context, uid, id string) error {
	if err := validateID("conversation_id", id); err != nil {
		return err
	}
	return s.store.DeleteConversation(ctx, uid, id)
}

func (s *Service) Close() error { return s.store.Close() }

func newID(prefix string) string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		panic("crypto/rand unavailable: " + err.Error())
	}
	return prefix + strings.ToLower(base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(raw[:]))
}

func validateID(field, id string) error {
	if len(id) < 8 || len(id) > 128 {
		return domain.ValidationError(field, "must be 8-128 URL-safe characters")
	}
	for _, char := range id {
		if (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || (char >= '0' && char <= '9') || char == '_' || char == '-' {
			continue
		}
		return domain.ValidationError(field, "must contain only letters, numbers, underscores, or hyphens")
	}
	return nil
}
