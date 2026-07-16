package domain

import (
	"strings"
	"testing"
	"time"
)

func TestPreferencesValidation(t *testing.T) {
	valid := DefaultPreferences()
	if err := valid.Validate(); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
	for name, mutate := range map[string]func(*Preferences){
		"language":   func(p *Preferences) { p.TargetLanguage = "fr" },
		"level":      func(p *Preferences) { p.Level = "expert" },
		"topic":      func(p *Preferences) { p.Topic = "" },
		"correction": func(p *Preferences) { p.CorrectionStyle = "sometimes" },
	} {
		t.Run(name, func(t *testing.T) {
			preferences := valid
			mutate(&preferences)
			if err := preferences.Validate(); err == nil {
				t.Fatal("Validate() succeeded, want error")
			}
		})
	}
}

func TestPreferencesTopicLimitCountsCharacters(t *testing.T) {
	preferences := DefaultPreferences()
	preferences.Topic = strings.Repeat("à", 120)
	if err := preferences.Validate(); err != nil {
		t.Fatalf("120 multibyte characters rejected: %v", err)
	}
	preferences.Topic += "à"
	if err := preferences.Validate(); err == nil {
		t.Fatal("121-character topic accepted")
	}
}

func TestTurnValidation(t *testing.T) {
	turn := Turn{ID: "turn_abcdefgh", Role: "user", Text: "Hello", OccurredAt: time.Now().UTC()}
	if err := turn.Validate(); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
	turn.Text = ""
	if err := turn.Validate(); err == nil {
		t.Fatal("Validate() succeeded for empty text")
	}
}

func TestTurnTextLimitCountsCharacters(t *testing.T) {
	turn := Turn{
		ID:         "turn_multibyte",
		Role:       "user",
		Text:       strings.Repeat("語", 8000),
		OccurredAt: time.Now().UTC(),
	}
	if err := turn.Validate(); err != nil {
		t.Fatalf("8000 multibyte characters rejected: %v", err)
	}
	turn.Text += "語"
	if err := turn.Validate(); err == nil {
		t.Fatal("8001-character turn accepted")
	}
}
