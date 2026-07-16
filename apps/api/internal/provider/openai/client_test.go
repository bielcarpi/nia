package openai

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/bielcarpi/nia/apps/api/internal/domain"
	"github.com/bielcarpi/nia/apps/api/internal/requestmeta"
)

func TestIssueBuildsBoundedRealtimeSession(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/realtime/client_secrets" {
			t.Fatalf("path = %q", request.URL.Path)
		}
		if request.Header.Get("Authorization") != "Bearer test-key" {
			t.Fatal("missing provider authorization")
		}
		identifier := request.Header.Get("OpenAI-Safety-Identifier")
		if len(identifier) != 64 || strings.Contains(identifier, "user-123") {
			t.Fatalf("unsafe safety identifier %q", identifier)
		}
		var body map[string]any
		if err := json.NewDecoder(request.Body).Decode(&body); err != nil {
			t.Fatal(err)
		}
		session := body["session"].(map[string]any)
		if session["model"] != "gpt-realtime-2.1" || !strings.Contains(session["instructions"].(string), "Spanish") {
			t.Fatalf("unexpected session: %#v", session)
		}
		audio := session["audio"].(map[string]any)
		input := audio["input"].(map[string]any)
		if input["transcription"].(map[string]any)["model"] != "gpt-4o-mini-transcribe" {
			t.Fatalf("missing transcription policy: %#v", input)
		}
		response.Header().Set("x-request-id", "provider-request")
		response.Header().Set("Content-Type", "application/json")
		_, _ = response.Write([]byte(`{"value":"ephemeral-test","expires_at":1770000000,"session":{"model":"gpt-realtime-2.1"}}`))
	}))
	defer server.Close()

	client := testClient(t, server.URL)
	secret, err := client.Issue(context.Background(), "user-123", domain.DefaultPreferences())
	if err != nil {
		t.Fatalf("Issue() error = %v", err)
	}
	if secret.Value != "ephemeral-test" || secret.ProviderRequestID != "provider-request" {
		t.Fatalf("unexpected secret: %+v", secret)
	}
}

func TestGenerateParsesStrictFeedback(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/responses" {
			t.Fatalf("path = %q", request.URL.Path)
		}
		var body map[string]any
		if err := json.NewDecoder(request.Body).Decode(&body); err != nil {
			t.Fatal(err)
		}
		if body["store"] != false || body["model"] != "gpt-5.6-terra" {
			t.Fatalf("unexpected Responses request: %#v", body)
		}
		output := `{"summary":"Clear exchange","strengths":["Good topic vocabulary"],"corrections":[{"original":"Yo gusto","corrected":"Me gusta","explanation":"Use gustar with an indirect object."}],"next_steps":["Practise gustar"]}`
		_ = json.NewEncoder(response).Encode(map[string]any{
			"output": []any{map[string]any{"type": "message", "content": []any{map[string]any{"type": "output_text", "text": output}}}},
		})
	}))
	defer server.Close()

	client := testClient(t, server.URL)
	feedback, err := client.Generate(context.Background(), "user", domain.ConversationDetail{
		Conversation: domain.ConversationSummary{Preferences: domain.DefaultPreferences()},
		Turns:        []domain.Turn{{ID: "turn_abcdefgh", Role: "user", Text: "Yo gusto", OccurredAt: time.Now()}},
	})
	if err != nil {
		t.Fatalf("Generate() error = %v", err)
	}
	if feedback.Summary != "Clear exchange" || len(feedback.Corrections) != 1 || feedback.GeneratedAt.IsZero() {
		t.Fatalf("unexpected feedback: %+v", feedback)
	}
}

func TestProviderErrorsDoNotExposeBody(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(response http.ResponseWriter, _ *http.Request) {
		response.WriteHeader(http.StatusBadRequest)
		_, _ = response.Write([]byte(`{"error":{"message":"sensitive provider detail"}}`))
	}))
	defer server.Close()
	client := testClient(t, server.URL)
	_, err := client.Issue(context.Background(), "user", domain.DefaultPreferences())
	if err == nil || strings.Contains(err.Error(), "sensitive provider detail") {
		t.Fatalf("Issue() error = %v", err)
	}
}

func TestProviderLogsRequestCorrelationWithoutPayloads(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(response http.ResponseWriter, _ *http.Request) {
		response.Header().Set("x-request-id", "provider-request-safe")
		response.Header().Set("Content-Type", "application/json")
		_, _ = response.Write([]byte(`{"value":"credential-that-must-not-be-logged","expires_at":1770000000,"session":{"model":"gpt-realtime-2.1"}}`))
	}))
	defer server.Close()

	var logs bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(&logs, nil))
	client := newTestClient(t, server.URL, logger)
	ctx := requestmeta.WithRequestID(context.Background(), "nia-request-safe")
	if _, err := client.Issue(ctx, "private-user-id", domain.DefaultPreferences()); err != nil {
		t.Fatalf("Issue() error = %v", err)
	}

	output := logs.String()
	if !strings.Contains(output, `"provider_request_id":"provider-request-safe"`) || !strings.Contains(output, `"request_id":"nia-request-safe"`) || !strings.Contains(output, `"operation":"realtime/client_secrets"`) {
		t.Fatalf("missing provider correlation metadata: %s", output)
	}
	if strings.Contains(output, "credential-that-must-not-be-logged") || strings.Contains(output, "private-user-id") {
		t.Fatalf("provider log contains sensitive payload data: %s", output)
	}
}

func testClient(t *testing.T, baseURL string) *Client {
	t.Helper()
	return newTestClient(t, baseURL, nil)
}

func newTestClient(t *testing.T, baseURL string, logger *slog.Logger) *Client {
	t.Helper()
	client, err := New(Config{
		APIKey: "test-key", BaseURL: baseURL, ProjectID: "project", RealtimeModel: "gpt-realtime-2.1",
		RealtimeVoice: "marin", TranscriptionModel: "gpt-4o-mini-transcribe", FeedbackModel: "gpt-5.6-terra",
		RealtimeTTL: 10 * time.Minute, SDPEndpoint: "https://api.openai.com/v1/realtime/calls", MaxConcurrency: 2,
		Logger: logger,
	}, serverClient())
	if err != nil {
		t.Fatal(err)
	}
	return client
}

func serverClient() *http.Client { return &http.Client{Timeout: 2 * time.Second} }
