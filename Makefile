SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

API_DIR := apps/api
MOBILE_DIR := apps/mobile
OPENAPI_SPEC := contracts/openapi.yaml
REDOCLY_VERSION := 2.39.0
STATICCHECK_VERSION := v0.7.0
GOVULNCHECK_VERSION := v1.6.0
TERRAFORM_DIRS := infra/terraform/bootstrap infra/terraform/service
GO_FILES := $(shell find $(API_DIR) -type f -name '*.go' 2>/dev/null)

.PHONY: help doctor doctor-full bootstrap format format-check lint-go test-go vuln-go mobile-check openapi-lint terraform-check check dev-api dev-mobile firebase-emulators docker-build

help: ## Show the common development commands.
	@awk 'BEGIN {FS = ":.*## "; printf "Nia development targets:\n\n"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

doctor: ## Confirm required local tools are available.
	@for tool in go flutter dart; do command -v "$$tool" >/dev/null && printf 'ok  %s\n' "$$tool"; done

doctor-full: doctor ## Confirm contract, infrastructure, emulator, and container tools too.
	@for tool in node npx terraform jq firebase docker; do command -v "$$tool" >/dev/null && printf 'ok  %s\n' "$$tool"; done

bootstrap: doctor ## Resolve Go and Flutter dependencies.
	go -C $(API_DIR) mod download
	cd $(MOBILE_DIR) && flutter pub get

format: ## Apply Go, Dart, and Terraform formatters.
	gofmt -w $(GO_FILES)
	cd $(MOBILE_DIR) && dart format lib test
	terraform fmt -recursive infra/terraform

format-check: ## Fail when committed Go, Dart, or Terraform files need formatting.
	test -z "$$(gofmt -l $(GO_FILES))"
	cd $(MOBILE_DIR) && dart format --output=none --set-exit-if-changed lib test
	terraform fmt -check -recursive infra/terraform

lint-go: ## Run Go vet and Staticcheck.
	go -C $(API_DIR) vet ./...
	go -C $(API_DIR) run honnef.co/go/tools/cmd/staticcheck@$(STATICCHECK_VERSION) ./...

test-go: ## Run race-enabled Go tests with coverage.
	go -C $(API_DIR) test -race -covermode=atomic -coverprofile=coverage.out ./...

vuln-go: ## Scan reachable Go code for known vulnerabilities.
	go -C $(API_DIR) run golang.org/x/vuln/cmd/govulncheck@$(GOVULNCHECK_VERSION) ./...

mobile-check: ## Analyze, test, and build the credential-free Flutter web app.
	cd $(MOBILE_DIR) && flutter analyze --fatal-infos
	cd $(MOBILE_DIR) && flutter test --coverage
	cd $(MOBILE_DIR) && flutter build web --release \
		--dart-define=NIA_DEMO_MODE=true \
		--dart-define=NIA_API_BASE_URL=http://localhost:8080

openapi-lint: ## Lint the OpenAPI 3.1 contract.
	npx --yes @redocly/cli@$(REDOCLY_VERSION) lint $(OPENAPI_SPEC)

terraform-check: ## Initialize without a backend, then format-check and validate Terraform.
	terraform fmt -check -recursive infra/terraform
	@for dir in $(TERRAFORM_DIRS); do terraform -chdir="$$dir" init -backend=false -input=false && terraform -chdir="$$dir" validate; done

check: format-check lint-go test-go vuln-go mobile-check openapi-lint terraform-check ## Run the complete local CI suite.

dev-api: ## Start the credential-free API on http://localhost:8080.
	@set -a; source .env.example; if [[ -f .env ]]; then source .env; fi; set +a; exec go -C $(API_DIR) run ./cmd/api

dev-mobile: ## Start the credential-free Flutter web demo in Chrome.
	cd $(MOBILE_DIR) && exec flutter run -d chrome \
		--web-hostname=localhost \
		--web-port=3000 \
		--dart-define=NIA_DEMO_MODE=true \
		--dart-define=NIA_LOCAL_STACK=true \
		--dart-define=NIA_API_BASE_URL=http://localhost:8080

firebase-emulators: ## Start isolated Firebase Auth and Firestore emulators.
	@exec firebase emulators:start \
		--project demo-nia \
		--config firebase.json \
		--only auth,firestore

docker-build: ## Build the production API image locally.
	docker build --pull \
		--build-arg VERSION="$$(git rev-parse --short=12 HEAD)" \
		-t nia-api:local $(API_DIR)
