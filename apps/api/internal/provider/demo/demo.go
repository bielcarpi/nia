package demo

import (
	"context"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

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
	learnerTurns := make([]domain.Turn, 0, len(detail.Turns))
	for _, turn := range detail.Turns {
		if turn.Role == "user" {
			learnerTurns = append(learnerTurns, turn)
		}
	}
	count := len(learnerTurns)
	language := languageLabel(detail.Conversation.Preferences.TargetLanguage)
	strengths := make([]string, 0, 2)
	if count > 0 {
		strengths = append(strengths,
			fmt.Sprintf("You kept the exchange moving for %d learner %s.", count, plural(count, "turn", "turns")),
			fmt.Sprintf("Your latest idea was specific: “%s”", excerpt(learnerTurns[count-1].Text)),
		)
	}
	corrections := make([]domain.Correction, 0, 1)
	for _, turn := range learnerTurns {
		if correction, ok := knownCorrection(detail.Conversation.Preferences.TargetLanguage, turn.Text); ok {
			corrections = append(corrections, correction)
			break
		}
	}
	return domain.Feedback{
		Summary: fmt.Sprintf(
			"You completed %d %s learner %s about %s.",
			count,
			language,
			plural(count, "turn", "turns"),
			detail.Conversation.Preferences.Topic,
		),
		Strengths:   strengths,
		Corrections: corrections,
		NextSteps:   nextSteps(detail.Conversation.Preferences),
		GeneratedAt: now().UTC(),
	}, nil
}

func knownCorrection(language, learnerText string) (domain.Correction, bool) {
	text := strings.ToLower(strings.TrimSpace(learnerText))
	switch {
	case language == "es" && strings.Contains(text, "yo soy bien"):
		return domain.Correction{
			Original: "Yo soy bien.", Corrected: "Estoy bien.",
			Explanation: "Use “estar” for a temporary state or feeling.",
		}, true
	case language == "en" && strings.Contains(text, "i am agree"):
		return domain.Correction{
			Original: "I am agree.", Corrected: "I agree.",
			Explanation: "“Agree” is a verb, so it does not take “am”.",
		}, true
	case language == "ca" && (strings.Contains(text, "jo soc bé") || strings.Contains(text, "jo sóc bé")):
		return domain.Correction{
			Original: "Jo soc bé.", Corrected: "Estic bé.",
			Explanation: "Fes servir “estar” per expressar com et trobes.",
		}, true
	default:
		return domain.Correction{}, false
	}
}

func nextSteps(preferences domain.Preferences) []string {
	topic := strings.ToLower(preferences.Topic)
	switch preferences.TargetLanguage {
	case "es":
		return []string{
			"Responde otra vez añadiendo cuándo, dónde y por qué.",
			fmt.Sprintf("Practica una pregunta de seguimiento sobre %s.", topic),
		}
	case "ca":
		return []string{
			"Torna a respondre afegint quan, on i per què.",
			fmt.Sprintf("Practica una pregunta de seguiment sobre %s.", topic),
		}
	default:
		return []string{
			"Answer again with when, where, and why.",
			fmt.Sprintf("Practise a follow-up question about %s.", topic),
		}
	}
}

func languageLabel(language string) string {
	switch language {
	case "es":
		return "Spanish"
	case "ca":
		return "Catalan"
	default:
		return "English"
	}
}

func plural(count int, singular, plural string) string {
	if count == 1 {
		return singular
	}
	return plural
}

func excerpt(text string) string {
	singleLine := strings.Join(strings.Fields(text), " ")
	if utf8.RuneCountInString(singleLine) <= 84 {
		return singleLine
	}
	runes := []rune(singleLine)
	return string(runes[:81]) + "…"
}
