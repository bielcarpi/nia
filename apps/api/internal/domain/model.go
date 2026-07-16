package domain

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"time"
)

const (
	StatusActive    = "active"
	StatusCompleted = "completed"

	TransportDemo   = "demo"
	TransportWebRTC = "webrtc"
)

var identifierPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9_-]{7,127}$`)

type Preferences struct {
	TargetLanguage  string `json:"target_language" firestore:"target_language"`
	Level           string `json:"level" firestore:"level"`
	Topic           string `json:"topic" firestore:"topic"`
	CorrectionStyle string `json:"correction_style" firestore:"correction_style"`
}

func DefaultPreferences() Preferences {
	return Preferences{
		TargetLanguage:  "es",
		Level:           "intermediate",
		Topic:           "Everyday life",
		CorrectionStyle: "gentle",
	}
}

func (p Preferences) Validate() error {
	switch p.TargetLanguage {
	case "en", "es", "ca":
	default:
		return ValidationError("target_language", "must be one of en, es, or ca")
	}
	switch p.Level {
	case "beginner", "intermediate", "advanced":
	default:
		return ValidationError("level", "must be beginner, intermediate, or advanced")
	}
	topic := strings.TrimSpace(p.Topic)
	if len(topic) < 1 || len(topic) > 120 {
		return ValidationError("topic", "must contain between 1 and 120 characters")
	}
	switch p.CorrectionStyle {
	case "gentle", "immediate", "summary":
	default:
		return ValidationError("correction_style", "must be gentle, immediate, or summary")
	}
	return nil
}

func (p Preferences) Normalized() Preferences {
	p.Topic = strings.TrimSpace(p.Topic)
	p.TargetLanguage = strings.ToLower(strings.TrimSpace(p.TargetLanguage))
	p.Level = strings.ToLower(strings.TrimSpace(p.Level))
	p.CorrectionStyle = strings.ToLower(strings.TrimSpace(p.CorrectionStyle))
	return p
}

type PreferencesPatch struct {
	TargetLanguage  *string `json:"target_language"`
	Level           *string `json:"level"`
	Topic           *string `json:"topic"`
	CorrectionStyle *string `json:"correction_style"`
}

func (p PreferencesPatch) Empty() bool {
	return p.TargetLanguage == nil && p.Level == nil && p.Topic == nil && p.CorrectionStyle == nil
}

func (p PreferencesPatch) Apply(base Preferences) Preferences {
	if p.TargetLanguage != nil {
		base.TargetLanguage = *p.TargetLanguage
	}
	if p.Level != nil {
		base.Level = *p.Level
	}
	if p.Topic != nil {
		base.Topic = *p.Topic
	}
	if p.CorrectionStyle != nil {
		base.CorrectionStyle = *p.CorrectionStyle
	}
	return base.Normalized()
}

type ConversationSummary struct {
	ID          string      `json:"id" firestore:"-"`
	Status      string      `json:"status" firestore:"status"`
	Preferences Preferences `json:"preferences" firestore:"preferences"`
	TurnCount   int         `json:"turn_count" firestore:"turn_count"`
	CreatedAt   time.Time   `json:"created_at" firestore:"created_at"`
	UpdatedAt   time.Time   `json:"updated_at" firestore:"updated_at"`
}

type Turn struct {
	ID         string    `json:"id" firestore:"-"`
	Role       string    `json:"role" firestore:"role"`
	Text       string    `json:"text" firestore:"text"`
	OccurredAt time.Time `json:"occurred_at" firestore:"occurred_at"`
}

func (t Turn) Validate() error {
	if !identifierPattern.MatchString(t.ID) {
		return ValidationError("turn_id", "must be 8-128 URL-safe characters")
	}
	if t.Role != "user" && t.Role != "assistant" {
		return ValidationError("role", "must be user or assistant")
	}
	t.Text = strings.TrimSpace(t.Text)
	if len(t.Text) < 1 || len(t.Text) > 8000 {
		return ValidationError("text", "must contain between 1 and 8000 characters")
	}
	if t.OccurredAt.IsZero() {
		return ValidationError("occurred_at", "must be a valid timestamp")
	}
	if t.OccurredAt.After(time.Now().Add(5 * time.Minute)) {
		return ValidationError("occurred_at", "must not be in the future")
	}
	return nil
}

type Correction struct {
	Original    string `json:"original" firestore:"original"`
	Corrected   string `json:"corrected" firestore:"corrected"`
	Explanation string `json:"explanation" firestore:"explanation"`
}

type Feedback struct {
	Summary     string       `json:"summary" firestore:"summary"`
	Strengths   []string     `json:"strengths" firestore:"strengths"`
	Corrections []Correction `json:"corrections" firestore:"corrections"`
	NextSteps   []string     `json:"next_steps" firestore:"next_steps"`
	GeneratedAt time.Time    `json:"generated_at" firestore:"generated_at"`
}

type ConversationDetail struct {
	Conversation ConversationSummary `json:"conversation"`
	Turns        []Turn              `json:"turns"`
	Feedback     *Feedback           `json:"feedback"`
}

type ConversationPage struct {
	Items      []ConversationSummary `json:"items"`
	NextCursor string                `json:"next_cursor,omitempty"`
}

type ClientSecret struct {
	Value     string `json:"value"`
	ExpiresAt int64  `json:"expires_at"`
}

type RealtimeConnection struct {
	Transport string `json:"transport"`
	Endpoint  string `json:"endpoint"`
	Model     string `json:"model"`
}

type RealtimeGrant struct {
	Conversation ConversationSummary `json:"conversation"`
	ClientSecret *ClientSecret       `json:"client_secret"`
	Realtime     RealtimeConnection  `json:"realtime"`
}

type IssuedRealtimeSecret struct {
	Value             string
	ExpiresAt         int64
	Model             string
	ProviderRequestID string
}

type ConversationStore interface {
	Ready(context.Context) error
	GetPreferences(context.Context, string) (Preferences, error)
	SavePreferences(context.Context, string, Preferences) (Preferences, error)
	CreateConversation(context.Context, string, ConversationSummary) error
	ListConversations(context.Context, string, string, int) (ConversationPage, error)
	GetConversation(context.Context, string, string) (ConversationDetail, error)
	UpsertTurn(context.Context, string, string, Turn) (Turn, error)
	CompleteConversation(context.Context, string, string, Feedback) (ConversationDetail, error)
	DeleteConversation(context.Context, string, string) error
	Close() error
}

type RealtimeSessionIssuer interface {
	Issue(context.Context, string, Preferences) (IssuedRealtimeSecret, error)
}

type FeedbackGenerator interface {
	Generate(context.Context, string, ConversationDetail) (Feedback, error)
}

type PublicError struct {
	Code      string
	Message   string
	Status    int
	Retryable bool
	Cause     error
}

func (e *PublicError) Error() string {
	if e.Cause == nil {
		return e.Code
	}
	return fmt.Sprintf("%s: %v", e.Code, e.Cause)
}

func (e *PublicError) Unwrap() error { return e.Cause }

func ValidationError(field, detail string) error {
	return &PublicError{
		Code:    "invalid_request",
		Message: field + " " + detail,
		Status:  400,
	}
}

func AsPublicError(err error) *PublicError {
	var public *PublicError
	if errors.As(err, &public) {
		return public
	}
	return &PublicError{
		Code:      "internal_error",
		Message:   "The server could not complete this request.",
		Status:    500,
		Retryable: true,
		Cause:     err,
	}
}

func NotFound() error {
	return &PublicError{Code: "not_found", Message: "Conversation not found.", Status: 404}
}

func Conflict(message string) error {
	return &PublicError{Code: "conflict", Message: message, Status: 409}
}

func RateLimited() error {
	return &PublicError{
		Code:      "rate_limited",
		Message:   "Please try again later.",
		Status:    429,
		Retryable: true,
	}
}

func ProviderUnavailable(cause error) error {
	return &PublicError{
		Code:      "provider_unavailable",
		Message:   "The tutoring provider is temporarily unavailable.",
		Status:    503,
		Retryable: true,
		Cause:     cause,
	}
}

func ProviderRejected(cause error) error {
	return &PublicError{
		Code:      "provider_error",
		Message:   "The tutoring provider could not complete this request.",
		Status:    502,
		Retryable: false,
		Cause:     cause,
	}
}
