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

func mapLookup(values map[string]string) func(string) (string, bool) {
	return func(key string) (string, bool) {
		value, ok := values[key]
		return value, ok
	}
}
