package auth

import (
	"context"
	"errors"
	"strings"

	"firebase.google.com/go/v4/appcheck"
	firebaseauth "firebase.google.com/go/v4/auth"
)

var ErrUnauthenticated = errors.New("unauthenticated")

type Identity struct {
	UID string
}

type Verifier interface {
	Verify(context.Context, string, string) (Identity, error)
}

type DemoVerifier struct{}

func (DemoVerifier) Verify(_ context.Context, bearerToken, _ string) (Identity, error) {
	if bearerToken != "nia-local-demo" {
		return Identity{}, ErrUnauthenticated
	}
	return Identity{UID: "demo-user"}, nil
}

type FirebaseVerifier struct {
	auth            idTokenVerifier
	appCheck        appCheckTokenVerifier
	requireAppCheck bool
}

type idTokenVerifier interface {
	VerifyIDToken(context.Context, string) (*firebaseauth.Token, error)
}

type appCheckTokenVerifier interface {
	VerifyToken(string) (*appcheck.DecodedAppCheckToken, error)
}

func NewFirebaseVerifier(authClient idTokenVerifier, appCheckClient appCheckTokenVerifier, requireAppCheck bool) (*FirebaseVerifier, error) {
	if authClient == nil {
		return nil, errors.New("firebase auth client is required")
	}
	if requireAppCheck && appCheckClient == nil {
		return nil, errors.New("firebase app check client is required")
	}
	return &FirebaseVerifier{auth: authClient, appCheck: appCheckClient, requireAppCheck: requireAppCheck}, nil
}

func (v *FirebaseVerifier) Verify(ctx context.Context, bearerToken, appCheckToken string) (Identity, error) {
	if strings.TrimSpace(bearerToken) == "" {
		return Identity{}, ErrUnauthenticated
	}
	token, err := v.auth.VerifyIDToken(ctx, bearerToken)
	if err != nil || token == nil || token.UID == "" {
		return Identity{}, ErrUnauthenticated
	}
	if v.requireAppCheck {
		if strings.TrimSpace(appCheckToken) == "" {
			return Identity{}, ErrUnauthenticated
		}
		if _, err := v.appCheck.VerifyToken(appCheckToken); err != nil {
			return Identity{}, ErrUnauthenticated
		}
	}
	return Identity{UID: token.UID}, nil
}

type contextKey struct{}

func WithIdentity(ctx context.Context, identity Identity) context.Context {
	return context.WithValue(ctx, contextKey{}, identity)
}

func IdentityFromContext(ctx context.Context) (Identity, bool) {
	identity, ok := ctx.Value(contextKey{}).(Identity)
	return identity, ok && identity.UID != ""
}
