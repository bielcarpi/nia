package config

import (
	"strings"
	"testing"
)

func TestLoadFromLocalDefaults(t *testing.T) {
	config, err := LoadFrom(mapLookup(nil))
	if err != nil {
		t.Fatalf("LoadFrom() error = %v", err)
	}
	if config.Environment != EnvironmentLocal || config.AuthMode != "demo" || config.StoreMode != "memory" || config.ProviderMode != "demo" {
		t.Fatalf("unexpected local defaults: %+v", config)
	}
	if config.RealtimeModel != "gpt-realtime-2.1" || config.FeedbackModel != "gpt-5.6-terra" {
		t.Fatalf("unexpected model defaults: realtime=%q feedback=%q", config.RealtimeModel, config.FeedbackModel)
	}
	if config.TurnLimitPerMinute != 120 {
		t.Fatalf("turn limit default = %d", config.TurnLimitPerMinute)
	}
}

func TestLoadFromProductionFailsClosed(t *testing.T) {
	_, err := LoadFrom(mapLookup(map[string]string{"NIA_ENV": "production"}))
	if err == nil || !strings.Contains(err.Error(), "FIREBASE_PROJECT_ID") {
		t.Fatalf("LoadFrom() error = %v, want missing Firebase project", err)
	}
}

func TestLoadFromProduction(t *testing.T) {
	config, err := LoadFrom(mapLookup(map[string]string{
		"NIA_ENV":                 "production",
		"NIA_FIREBASE_PROJECT_ID": "nia-prod",
		"OPENAI_API_KEY":          "test-only",
		"NIA_ALLOWED_ORIGINS":     "https://nia.example,https://admin.nia.example",
	}))
	if err != nil {
		t.Fatalf("LoadFrom() error = %v", err)
	}
	if !config.RequireAppCheck || len(config.AllowedOrigins) != 2 {
		t.Fatalf("unexpected production config: %+v", config)
	}
}

func TestProductionRejectsUnsafeOverrides(t *testing.T) {
	tests := []map[string]string{
		{"NIA_AUTH_MODE": "demo"},
		{"NIA_REQUIRE_APP_CHECK": "false"},
		{"NIA_ALLOWED_ORIGINS": "http://nia.example"},
		{"NIA_OPENAI_BASE_URL": "https://proxy.example/v1"},
		{"NIA_REALTIME_SDP_ENDPOINT": "http://api.openai.com/v1/realtime/calls"},
		{"NIA_REALTIME_SDP_ENDPOINT": "https://realtime-proxy.example/calls"},
	}
	for _, override := range tests {
		environment := map[string]string{
			"NIA_ENV":                 "production",
			"NIA_FIREBASE_PROJECT_ID": "nia-prod",
			"OPENAI_API_KEY":          "test-only",
			"NIA_ALLOWED_ORIGINS":     "https://nia.example",
		}
		for key, value := range override {
			environment[key] = value
		}
		if _, err := LoadFrom(mapLookup(environment)); err == nil {
			t.Fatalf("LoadFrom(%v) succeeded, want failure", override)
		}
	}
}

func TestAllowedOriginsRejectURLComponentsOutsideOrigin(t *testing.T) {
	for _, origin := range []string{
		"https://nia.example/",
		"https://nia.example/path",
		"https://nia.example?preview=true",
		"https://nia.example#fragment",
		"https://*.nia.example",
	} {
		_, err := LoadFrom(mapLookup(map[string]string{"NIA_ALLOWED_ORIGINS": origin}))
		if err == nil {
			t.Fatalf("LoadFrom() accepted non-origin URL %q", origin)
		}
	}
}

func TestTranscriptWriteLimitMustBePositive(t *testing.T) {
	if _, err := LoadFrom(mapLookup(map[string]string{"NIA_TURN_LIMIT_PER_MINUTE": "0"})); err == nil {
		t.Fatal("LoadFrom() accepted a zero transcript write limit")
	}
}

func mapLookup(values map[string]string) func(string) (string, bool) {
	return func(key string) (string, bool) {
		value, ok := values[key]
		return value, ok
	}
}
