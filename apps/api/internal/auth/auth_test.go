package auth

import (
	"context"
	"errors"
	"testing"

	"firebase.google.com/go/v4/appcheck"
	firebaseauth "firebase.google.com/go/v4/auth"
)

type fakeIDTokenVerifier struct {
	token *firebaseauth.Token
	err   error
	got   string
}

func (f *fakeIDTokenVerifier) VerifyIDToken(_ context.Context, token string) (*firebaseauth.Token, error) {
	f.got = token
	return f.token, f.err
}

type fakeAppCheckVerifier struct {
	token *appcheck.DecodedAppCheckToken
	err   error
	got   string
}

func (f *fakeAppCheckVerifier) VerifyToken(token string) (*appcheck.DecodedAppCheckToken, error) {
	f.got = token
	return f.token, f.err
}

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

func TestFirebaseVerifierRequiresConfiguredClients(t *testing.T) {
	if _, err := NewFirebaseVerifier(nil, nil, false); err == nil {
		t.Fatal("NewFirebaseVerifier() accepted a nil auth verifier")
	}
	authVerifier := &fakeIDTokenVerifier{}
	if _, err := NewFirebaseVerifier(authVerifier, nil, true); err == nil {
		t.Fatal("NewFirebaseVerifier() accepted a nil required App Check verifier")
	}
}

func TestFirebaseVerifierVerifiesIDAndAppCheckTokens(t *testing.T) {
	authVerifier := &fakeIDTokenVerifier{token: &firebaseauth.Token{UID: "firebase-user"}}
	appCheckVerifier := &fakeAppCheckVerifier{token: &appcheck.DecodedAppCheckToken{AppID: "app-id"}}
	verifier, err := NewFirebaseVerifier(authVerifier, appCheckVerifier, true)
	if err != nil {
		t.Fatalf("NewFirebaseVerifier() error = %v", err)
	}
	identity, err := verifier.Verify(context.Background(), "id-token", "app-check-token")
	if err != nil || identity.UID != "firebase-user" {
		t.Fatalf("Verify() = %+v, %v", identity, err)
	}
	if authVerifier.got != "id-token" || appCheckVerifier.got != "app-check-token" {
		t.Fatalf("verified tokens = %q, %q", authVerifier.got, appCheckVerifier.got)
	}
}

func TestFirebaseVerifierFailsClosed(t *testing.T) {
	tests := []struct {
		name          string
		bearer        string
		appCheck      string
		authToken     *firebaseauth.Token
		authErr       error
		appCheckToken *appcheck.DecodedAppCheckToken
		appCheckErr   error
	}{
		{name: "missing bearer", appCheck: "app-check", authToken: &firebaseauth.Token{UID: "user"}},
		{name: "invalid bearer", bearer: "id-token", appCheck: "app-check", authErr: errors.New("invalid")},
		{name: "empty uid", bearer: "id-token", appCheck: "app-check", authToken: &firebaseauth.Token{}},
		{name: "missing app check", bearer: "id-token", authToken: &firebaseauth.Token{UID: "user"}},
		{name: "invalid app check", bearer: "id-token", appCheck: "app-check", authToken: &firebaseauth.Token{UID: "user"}, appCheckErr: errors.New("invalid")},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			authVerifier := &fakeIDTokenVerifier{token: test.authToken, err: test.authErr}
			appCheckVerifier := &fakeAppCheckVerifier{token: test.appCheckToken, err: test.appCheckErr}
			verifier, err := NewFirebaseVerifier(authVerifier, appCheckVerifier, true)
			if err != nil {
				t.Fatal(err)
			}
			if _, err := verifier.Verify(context.Background(), test.bearer, test.appCheck); !errors.Is(err, ErrUnauthenticated) {
				t.Fatalf("Verify() error = %v, want ErrUnauthenticated", err)
			}
		})
	}
}
