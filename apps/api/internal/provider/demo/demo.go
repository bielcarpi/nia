package demo

import (
	"context"
	"time"

	"github.com/bielcarpi/nia/apps/api/internal/domain"
)

type RealtimeIssuer struct{}

func (RealtimeIssuer) Issue(context.Context, string, domain.Preferences) (domain.IssuedRealtimeSecret, error) {
	return domain.IssuedRealtimeSecret{Model: "deterministic-demo"}, nil
}

type FeedbackGenerator struct {
	Now func() time.Time
}

func (g FeedbackGenerator) Generate(_ context.Context, _ string, detail domain.ConversationDetail) (domain.Feedback, error) {
	now := time.Now
	if g.Now != nil {
		now = g.Now
	}
	strengths := []string{
		"You kept the exchange moving with complete thoughts.",
		"Your vocabulary stayed relevant to the selected topic.",
	}
	corrections := make([]domain.Correction, 0, 1)
	for _, turn := range detail.Turns {
		if turn.Role == "user" {
			corrections = append(corrections, domain.Correction{
				Original:    turn.Text,
				Corrected:   turn.Text,
				Explanation: "This sentence was clear. In a real provider session, Nia would explain a specific correction here.",
			})
			break
		}
	}
	return domain.Feedback{
		Summary:     "You completed a focused practice exchange and communicated clearly.",
		Strengths:   strengths,
		Corrections: corrections,
		NextSteps: []string{
			"Repeat the topic with one more detail in every response.",
			"Try the next proficiency level when this feels comfortable.",
		},
		GeneratedAt: now().UTC(),
	}, nil
}
