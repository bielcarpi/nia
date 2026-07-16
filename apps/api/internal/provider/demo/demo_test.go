package demo

import (
	"context"
	"testing"
	"time"

	"github.com/bielcarpi/nia/apps/api/internal/domain"
)

func TestFeedbackUsesTranscriptAndKnownCorrection(t *testing.T) {
	generatedAt := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	feedback, err := (FeedbackGenerator{Now: func() time.Time { return generatedAt }}).Generate(
		context.Background(),
		"user",
		domain.ConversationDetail{
			Conversation: domain.ConversationSummary{Preferences: domain.Preferences{
				TargetLanguage: "es", Level: "intermediate", Topic: "Food & culture", CorrectionStyle: "immediate",
			}},
			Turns: []domain.Turn{
				{ID: "turn_learner_one", Role: "user", Text: "Yo soy bien, y cocino paella.", OccurredAt: generatedAt},
				{ID: "turn_assistant", Role: "assistant", Text: "Una corrección…", OccurredAt: generatedAt},
				{ID: "turn_learner_two", Role: "user", Text: "Estoy bien y cocino con mi familia.", OccurredAt: generatedAt},
			},
		},
	)
	if err != nil {
		t.Fatal(err)
	}
	if feedback.Summary != "You completed 2 Spanish learner turns about Food & culture." {
		t.Fatalf("summary = %q", feedback.Summary)
	}
	if len(feedback.Strengths) != 2 || len(feedback.Corrections) != 1 {
		t.Fatalf("feedback = %+v", feedback)
	}
	if correction := feedback.Corrections[0]; correction.Original != "Yo soy bien." || correction.Corrected != "Estoy bien." {
		t.Fatalf("correction = %+v", correction)
	}
	if !feedback.GeneratedAt.Equal(generatedAt) || len(feedback.NextSteps) != 2 {
		t.Fatalf("feedback metadata = %+v", feedback)
	}
}

func TestFeedbackDoesNotInventCorrection(t *testing.T) {
	feedback, err := (FeedbackGenerator{}).Generate(context.Background(), "user", domain.ConversationDetail{
		Conversation: domain.ConversationSummary{Preferences: domain.DefaultPreferences()},
		Turns: []domain.Turn{
			{ID: "turn_learner_clean", Role: "user", Text: "Estoy bien.", OccurredAt: time.Now()},
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(feedback.Corrections) != 0 {
		t.Fatalf("invented corrections: %+v", feedback.Corrections)
	}
}
