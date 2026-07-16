# syntax=docker/dockerfile:1.12@sha256:93bfd3b68c109427185cd78b4779fc82b484b0b7618e36d0f104d4d801e66d25
FROM docker.io/library/golang:1.25.12-alpine3.24@sha256:56961d79ea8129efddcc0b8643fd8a5416b4e6228cfd477e3fd61deb2672c587 AS build

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
      org.opencontainers.image.description="Go API for Nia language practice" \
      org.opencontainers.image.source="https://github.com/bielcarpi/nia" \
      org.opencontainers.image.revision="${VERSION}"

COPY --from=build --chown=nonroot:nonroot /out/nia-api /nia-api
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/nia-api"]
