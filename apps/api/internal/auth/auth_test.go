package auth

import (
	"context"
	"errors"
	"testing"
)

func TestDemoVerifierAcceptsOnlyExplicitLocalToken(t *testing.T) {
	verifier := DemoVerifier{}
	identity, err := verifier.Verify(context.Background(), "nia-local-demo", "")
	if err != nil || identity.UID != "demo-user" {
		t.Fatalf("Verify() = %+v, %v", identity, err)
	}
	for _, token := range []string{"", "demo", "nia-local-demo ", "real-looking-token"} {
		if _, err := verifier.Verify(context.Background(), token, ""); !errors.Is(err, ErrUnauthenticated) {
			t.Fatalf("Verify(%q) error = %v, want ErrUnauthenticated", token, err)
		}
	}
}

func TestIdentityContext(t *testing.T) {
	ctx := WithIdentity(context.Background(), Identity{UID: "user-1"})
	identity, ok := IdentityFromContext(ctx)
	if !ok || identity.UID != "user-1" {
		t.Fatalf("IdentityFromContext() = %+v, %v", identity, ok)
	}
}
