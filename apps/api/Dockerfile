# syntax=docker/dockerfile:1.12@sha256:93bfd3b68c109427185cd78b4779fc82b484b0b7618e36d0f104d4d801e66d25
FROM docker.io/library/golang:1.26.5-alpine3.24@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2 AS build

ARG VERSION=dev

WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
	CGO_ENABLED=0 GOOS=linux go build \
	-trimpath -ldflags="-s -w -buildid= -X main.version=${VERSION}" \
	-o /out/nia-api ./cmd/api

FROM gcr.io/distroless/static-debian12:nonroot@sha256:aef9602f8710ec12bde19d593fed1f76c708531bb7aba205110f1029786ead7b

ARG VERSION=dev
LABEL org.opencontainers.image.title="Nia API" \
      org.opencontainers.image.description="Secure control plane for Nia language practice" \
      org.opencontainers.image.source="https://github.com/bielcarpi/nia" \
      org.opencontainers.image.revision="${VERSION}"

COPY --from=build --chown=nonroot:nonroot /out/nia-api /nia-api
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/nia-api"]
