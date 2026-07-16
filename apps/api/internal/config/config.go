package config

import (
	"fmt"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	EnvironmentLocal            = "local"
	EnvironmentProduction       = "production"
	officialRealtimeSDPEndpoint = "https://api.openai.com/v1/realtime/calls"
)

type Config struct {
	Environment           string
	Port                  int
	AuthMode              string
	StoreMode             string
	ProviderMode          string
	FirebaseProjectID     string
	RequireAppCheck       bool
	AllowedOrigins        []string
	OpenAIAPIKey          string
	OpenAIBaseURL         string
	RealtimeModel         string
	RealtimeVoice         string
	TranscriptionModel    string
	FeedbackModel         string
	RealtimeSDPEndpoint   string
	RealtimeTTL           time.Duration
	ProviderTimeout       time.Duration
	RequestTimeout        time.Duration
	MaxRequestBodyBytes   int64
	MaxConcurrentRequests int
	SessionLimitPerHour   int
	FeedbackLimitPerHour  int
	TurnLimitPerMinute    int
	LogLevel              string
}

func Load() (Config, error) { return LoadFrom(os.LookupEnv) }

func LoadFrom(lookup func(string) (string, bool)) (Config, error) {
	environment := value(lookup, "NIA_ENV", EnvironmentLocal)
	production := environment == EnvironmentProduction

	config := Config{
		Environment:           environment,
		Port:                  intValue(lookup, "PORT", 8080),
		AuthMode:              value(lookup, "NIA_AUTH_MODE", choose(production, "firebase", "demo")),
		StoreMode:             value(lookup, "NIA_STORE_MODE", choose(production, "firestore", "memory")),
		ProviderMode:          value(lookup, "NIA_PROVIDER_MODE", choose(production, "openai", "demo")),
		FirebaseProjectID:     value(lookup, "NIA_FIREBASE_PROJECT_ID", ""),
		RequireAppCheck:       boolValue(lookup, "NIA_REQUIRE_APP_CHECK", production),
		AllowedOrigins:        splitCSV(value(lookup, "NIA_ALLOWED_ORIGINS", choose(production, "", "http://localhost:3000"))),
		OpenAIAPIKey:          value(lookup, "OPENAI_API_KEY", ""),
		OpenAIBaseURL:         strings.TrimRight(value(lookup, "NIA_OPENAI_BASE_URL", "https://api.openai.com/v1"), "/"),
		RealtimeModel:         value(lookup, "NIA_REALTIME_MODEL", "gpt-realtime-2.1"),
		RealtimeVoice:         value(lookup, "NIA_REALTIME_VOICE", "marin"),
		TranscriptionModel:    value(lookup, "NIA_TRANSCRIPTION_MODEL", "gpt-4o-mini-transcribe"),
		FeedbackModel:         value(lookup, "NIA_FEEDBACK_MODEL", "gpt-5.6-terra"),
		RealtimeSDPEndpoint:   value(lookup, "NIA_REALTIME_SDP_ENDPOINT", officialRealtimeSDPEndpoint),
		RealtimeTTL:           durationValue(lookup, "NIA_REALTIME_TTL", 10*time.Minute),
		ProviderTimeout:       durationValue(lookup, "NIA_PROVIDER_TIMEOUT", 15*time.Second),
		RequestTimeout:        durationValue(lookup, "NIA_REQUEST_TIMEOUT", 30*time.Second),
		MaxRequestBodyBytes:   int64(intValue(lookup, "NIA_MAX_REQUEST_BODY_BYTES", 64<<10)),
		MaxConcurrentRequests: intValue(lookup, "NIA_MAX_CONCURRENT_REQUESTS", 64),
		SessionLimitPerHour:   intValue(lookup, "NIA_SESSION_LIMIT_PER_HOUR", 12),
		FeedbackLimitPerHour:  intValue(lookup, "NIA_FEEDBACK_LIMIT_PER_HOUR", 12),
		TurnLimitPerMinute:    intValue(lookup, "NIA_TURN_LIMIT_PER_MINUTE", 120),
		LogLevel:              value(lookup, "NIA_LOG_LEVEL", "info"),
	}
	if err := config.Validate(); err != nil {
		return Config{}, err
	}
	return config, nil
}

func (c Config) Validate() error {
	if c.Environment != EnvironmentLocal && c.Environment != EnvironmentProduction {
		return fmt.Errorf("NIA_ENV must be local or production")
	}
	if c.Port < 1 || c.Port > 65535 {
		return fmt.Errorf("PORT must be between 1 and 65535")
	}
	if c.MaxRequestBodyBytes < 1024 || c.MaxRequestBodyBytes > 1<<20 {
		return fmt.Errorf("NIA_MAX_REQUEST_BODY_BYTES must be between 1024 and 1048576")
	}
	if c.MaxConcurrentRequests < 1 || c.MaxConcurrentRequests > 1000 {
		return fmt.Errorf("NIA_MAX_CONCURRENT_REQUESTS must be between 1 and 1000")
	}
	if c.SessionLimitPerHour < 1 || c.FeedbackLimitPerHour < 1 || c.TurnLimitPerMinute < 1 {
		return fmt.Errorf("session, feedback, and turn limits must be positive")
	}
	if c.RequestTimeout < time.Second || c.ProviderTimeout < time.Second {
		return fmt.Errorf("request and provider timeouts must be at least one second")
	}
	if c.RealtimeTTL < time.Minute || c.RealtimeTTL > time.Hour {
		return fmt.Errorf("NIA_REALTIME_TTL must be between 1m and 1h")
	}
	sdpEndpoint, err := validatedHTTPURL(c.RealtimeSDPEndpoint)
	if err != nil {
		return fmt.Errorf("NIA_REALTIME_SDP_ENDPOINT: %w", err)
	}
	baseURL, err := validatedHTTPURL(c.OpenAIBaseURL)
	if err != nil {
		return fmt.Errorf("NIA_OPENAI_BASE_URL: %w", err)
	}
	for _, origin := range c.AllowedOrigins {
		parsed, err := validatedHTTPURL(origin)
		if err != nil || parsed.Path != "" || parsed.RawQuery != "" || parsed.Fragment != "" || strings.Contains(origin, "*") {
			return fmt.Errorf("NIA_ALLOWED_ORIGINS contains invalid exact origin %q", origin)
		}
		if c.Environment == EnvironmentProduction && parsed.Scheme != "https" {
			return fmt.Errorf("production origins must use https")
		}
	}
	if c.Environment == EnvironmentProduction {
		if c.AuthMode != "firebase" || c.StoreMode != "firestore" || c.ProviderMode != "openai" {
			return fmt.Errorf("production requires firebase auth, firestore storage, and openai provider modes")
		}
		if c.FirebaseProjectID == "" {
			return fmt.Errorf("NIA_FIREBASE_PROJECT_ID is required in production")
		}
		if c.OpenAIAPIKey == "" {
			return fmt.Errorf("OPENAI_API_KEY is required in production")
		}
		if !c.RequireAppCheck {
			return fmt.Errorf("NIA_REQUIRE_APP_CHECK cannot be disabled in production")
		}
		if len(c.AllowedOrigins) == 0 {
			return fmt.Errorf("NIA_ALLOWED_ORIGINS is required in production")
		}
		if baseURL.String() != "https://api.openai.com/v1" {
			return fmt.Errorf("production NIA_OPENAI_BASE_URL must be https://api.openai.com/v1")
		}
		if sdpEndpoint.String() != officialRealtimeSDPEndpoint {
			return fmt.Errorf("production NIA_REALTIME_SDP_ENDPOINT must be %s", officialRealtimeSDPEndpoint)
		}
	}
	if c.Environment == EnvironmentLocal {
		if c.AuthMode != "demo" && c.AuthMode != "firebase" {
			return fmt.Errorf("unsupported local auth mode %q", c.AuthMode)
		}
		if c.StoreMode != "memory" && c.StoreMode != "firestore" {
			return fmt.Errorf("unsupported local store mode %q", c.StoreMode)
		}
		if c.ProviderMode != "demo" && c.ProviderMode != "openai" {
			return fmt.Errorf("unsupported local provider mode %q", c.ProviderMode)
		}
		if c.ProviderMode == "openai" && c.OpenAIAPIKey == "" {
			return fmt.Errorf("OPENAI_API_KEY is required when NIA_PROVIDER_MODE=openai")
		}
	}
	return nil
}

func validatedHTTPURL(raw string) (*url.URL, error) {
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Host == "" || parsed.User != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		return nil, fmt.Errorf("must be an absolute http(s) URL without user info")
	}
	return parsed, nil
}

func value(lookup func(string) (string, bool), key, fallback string) string {
	if raw, ok := lookup(key); ok && strings.TrimSpace(raw) != "" {
		return strings.TrimSpace(raw)
	}
	return fallback
}

func intValue(lookup func(string) (string, bool), key string, fallback int) int {
	raw, ok := lookup(key)
	if !ok || strings.TrimSpace(raw) == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(strings.TrimSpace(raw))
	if err != nil {
		return -1
	}
	return parsed
}

func boolValue(lookup func(string) (string, bool), key string, fallback bool) bool {
	raw, ok := lookup(key)
	if !ok || strings.TrimSpace(raw) == "" {
		return fallback
	}
	parsed, err := strconv.ParseBool(strings.TrimSpace(raw))
	if err != nil {
		return false
	}
	return parsed
}

func durationValue(lookup func(string) (string, bool), key string, fallback time.Duration) time.Duration {
	raw, ok := lookup(key)
	if !ok || strings.TrimSpace(raw) == "" {
		return fallback
	}
	parsed, err := time.ParseDuration(strings.TrimSpace(raw))
	if err != nil {
		return 0
	}
	return parsed
}

func splitCSV(raw string) []string {
	if strings.TrimSpace(raw) == "" {
		return nil
	}
	seen := make(map[string]struct{})
	result := make([]string, 0)
	for _, part := range strings.Split(raw, ",") {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		if _, exists := seen[part]; exists {
			continue
		}
		seen[part] = struct{}{}
		result = append(result, part)
	}
	return result
}

func choose(condition bool, whenTrue, whenFalse string) string {
	if condition {
		return whenTrue
	}
	return whenFalse
}
