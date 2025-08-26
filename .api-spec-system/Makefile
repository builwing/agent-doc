# API Specification System Makefile
# Go-Zero + OpenAPI Integration

.PHONY: help install generate validate clean mock-server docker-build docker-run

# Variables
SPEC_DIR := ./specs
OUTPUT_DIR := ./generated
SCRIPTS_DIR := ./scripts
DOCKER_IMAGE := api-spec-system
MOCK_PORT := 4010

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# Default target
help:
	@echo "$(GREEN)API Specification System - Available Commands:$(NC)"
	@echo ""
	@echo "  $(YELLOW)make install$(NC)          - Install dependencies"
	@echo "  $(YELLOW)make generate$(NC)         - Generate code for all platforms"
	@echo "  $(YELLOW)make generate-backend$(NC) - Generate Go-Zero backend code"
	@echo "  $(YELLOW)make generate-frontend$(NC)- Generate Next.js frontend code"
	@echo "  $(YELLOW)make generate-mobile$(NC)  - Generate Expo mobile code"
	@echo "  $(YELLOW)make validate$(NC)         - Validate all API specifications"
	@echo "  $(YELLOW)make mock-server$(NC)      - Start mock API server"
	@echo "  $(YELLOW)make clean$(NC)            - Clean generated files"
	@echo "  $(YELLOW)make docker-build$(NC)     - Build Docker image"
	@echo "  $(YELLOW)make docker-run$(NC)       - Run in Docker container"
	@echo ""

# Install dependencies
install:
	@echo "$(GREEN)[Installing dependencies]$(NC)"
	@echo "Installing Node.js dependencies..."
	@npm init -y 2>/dev/null || true
	@npm install --save-dev \
		@apidevtools/swagger-cli \
		@openapitools/openapi-generator-cli \
		js-yaml \
		handlebars \
		zod \
		prettier
	@echo "Installing Go dependencies..."
	@go install github.com/zeromicro/go-zero/tools/goctl@latest
	@echo "$(GREEN)Dependencies installed successfully!$(NC)"

# Generate all code
generate:
	@echo "$(GREEN)[Generating code for all platforms]$(NC)"
	@bash $(SCRIPTS_DIR)/generate.sh all

# Generate backend code only
generate-backend:
	@echo "$(GREEN)[Generating Go-Zero backend code]$(NC)"
	@bash $(SCRIPTS_DIR)/generate.sh backend

# Generate frontend code only
generate-frontend:
	@echo "$(GREEN)[Generating Next.js frontend code]$(NC)"
	@bash $(SCRIPTS_DIR)/generate.sh frontend

# Generate mobile code only
generate-mobile:
	@echo "$(GREEN)[Generating Expo mobile code]$(NC)"
	@bash $(SCRIPTS_DIR)/generate.sh mobile

# Validate specifications
validate:
	@echo "$(GREEN)[Validating API specifications]$(NC)"
	@for spec in $(shell find $(SPEC_DIR) -name "*.yaml" -o -name "*.yml"); do \
		echo "Validating: $$spec"; \
		npx @apidevtools/swagger-cli validate $$spec || exit 1; \
	done
	@echo "$(GREEN)All specifications are valid!$(NC)"

# Start mock server
mock-server:
	@echo "$(GREEN)[Starting mock API server on port $(MOCK_PORT)]$(NC)"
	@if command -v prism >/dev/null 2>&1; then \
		prism mock $(SPEC_DIR)/core/api-spec.yaml -p $(MOCK_PORT); \
	else \
		echo "$(YELLOW)Installing Prism mock server...$(NC)"; \
		npm install -g @stoplight/prism-cli; \
		prism mock $(SPEC_DIR)/core/api-spec.yaml -p $(MOCK_PORT); \
	fi

# Clean generated files
clean:
	@echo "$(RED)[Cleaning generated files]$(NC)"
	@rm -rf $(OUTPUT_DIR)/*
	@echo "$(GREEN)Cleaned successfully!$(NC)"

# Watch for changes and regenerate
watch:
	@echo "$(GREEN)[Watching for specification changes]$(NC)"
	@while true; do \
		fswatch -1 $(SPEC_DIR) && make generate; \
	done

# Docker build
docker-build:
	@echo "$(GREEN)[Building Docker image]$(NC)"
	@docker build -t $(DOCKER_IMAGE) .

# Docker run
docker-run:
	@echo "$(GREEN)[Running in Docker container]$(NC)"
	@docker run -it --rm \
		-v $(PWD)/specs:/app/specs \
		-v $(PWD)/generated:/app/generated \
		$(DOCKER_IMAGE) make generate

# Test generated code
test-backend:
	@echo "$(GREEN)[Testing Go-Zero backend]$(NC)"
	@cd $(OUTPUT_DIR)/backend && go test ./...

test-frontend:
	@echo "$(GREEN)[Testing Next.js frontend]$(NC)"
	@cd $(OUTPUT_DIR)/frontend && npm test

test-mobile:
	@echo "$(GREEN)[Testing Expo mobile]$(NC)"
	@cd $(OUTPUT_DIR)/mobile && npm test

# Generate and test all
all: validate generate test-backend test-frontend test-mobile
	@echo "$(GREEN)All tasks completed successfully!$(NC)"

# Development setup
dev-setup: install
	@echo "$(GREEN)[Setting up development environment]$(NC)"
	@mkdir -p $(SPEC_DIR)/core $(SPEC_DIR)/services
	@mkdir -p $(OUTPUT_DIR)/backend $(OUTPUT_DIR)/frontend $(OUTPUT_DIR)/mobile
	@mkdir -p $(SCRIPTS_DIR)/parsers $(SCRIPTS_DIR)/validators
	@echo "$(GREEN)Development environment ready!$(NC)"

# Generate documentation
docs:
	@echo "$(GREEN)[Generating API documentation]$(NC)"
	@npx @redocly/openapi-cli build-docs $(SPEC_DIR)/core/api-spec.yaml -o docs/index.html
	@echo "$(GREEN)Documentation generated at docs/index.html$(NC)"

# Lint specifications
lint:
	@echo "$(GREEN)[Linting API specifications]$(NC)"
	@npx spectral lint $(SPEC_DIR)/**/*.yaml

# Format code
format:
	@echo "$(GREEN)[Formatting generated code]$(NC)"
	@cd $(OUTPUT_DIR)/backend && gofmt -w .
	@cd $(OUTPUT_DIR)/frontend && npx prettier --write "**/*.{ts,tsx,js,jsx}"
	@cd $(OUTPUT_DIR)/mobile && npx prettier --write "**/*.{ts,tsx,js,jsx}"

# Compliance check
compliance:
	@echo "$(GREEN)[Running compliance check]$(NC)"
	@node $(SCRIPTS_DIR)/compliance-checker.js

# Setup git hooks
setup-hooks:
	@echo "$(GREEN)[Setting up git hooks]$(NC)"
	@git config core.hooksPath .githooks
	@echo "$(GREEN)Git hooks configured!$(NC)"

.DEFAULT_GOAL := help