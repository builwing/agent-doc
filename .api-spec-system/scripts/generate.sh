#!/bin/bash

# API Specification Code Generator
# Go-Zero + OpenAPI Integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SPEC_DIR="./specs"
TEMPLATE_DIR="./templates"
OUTPUT_DIR="./generated"

# Function to print colored output
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
validate_environment() {
    log_info "Validating environment..."
    
    # Check for required tools
    command -v node >/dev/null 2>&1 || { log_error "Node.js is required but not installed."; exit 1; }
    command -v go >/dev/null 2>&1 || { log_error "Go is required but not installed."; exit 1; }
    
    # Check directories
    [ ! -d "$SPEC_DIR" ] && { log_error "Spec directory not found: $SPEC_DIR"; exit 1; }
    [ ! -d "$TEMPLATE_DIR" ] && { log_error "Template directory not found: $TEMPLATE_DIR"; exit 1; }
    
    # Create output directories if they don't exist
    mkdir -p "$OUTPUT_DIR/backend"
    mkdir -p "$OUTPUT_DIR/frontend"
    mkdir -p "$OUTPUT_DIR/mobile"
    
    log_info "Environment validation completed"
}

# Generate Go-Zero backend code
generate_backend() {
    local spec_file=$1
    log_info "Generating Go-Zero backend code from: $spec_file"
    
    # Parse OpenAPI spec and generate Go-Zero API file
    node scripts/parsers/openapi-to-gozero.js "$spec_file" "$OUTPUT_DIR/backend"
    
    # Generate handlers and logic
    cd "$OUTPUT_DIR/backend"
    
    # Use goctl to generate code structure
    if command -v goctl >/dev/null 2>&1; then
        goctl api go -api api.api -dir . --style=goZero
        log_info "Go-Zero code generated successfully"
    else
        log_warn "goctl not found. Install with: go install github.com/zeromicro/go-zero/tools/goctl@latest"
    fi
    
    cd - > /dev/null
}

# Generate Next.js frontend code
generate_frontend() {
    local spec_file=$1
    log_info "Generating Next.js 15 frontend code from: $spec_file"
    
    # Generate TypeScript types and API client
    node scripts/parsers/openapi-to-nextjs.js "$spec_file" "$OUTPUT_DIR/frontend"
    
    # Format generated code
    if command -v prettier >/dev/null 2>&1; then
        prettier --write "$OUTPUT_DIR/frontend/**/*.{ts,tsx}"
    fi
    
    log_info "Next.js code generated successfully"
}

# Generate Expo mobile code
generate_mobile() {
    local spec_file=$1
    log_info "Generating Expo mobile code from: $spec_file"
    
    # Generate React Native/Expo API service
    node scripts/parsers/openapi-to-expo.js "$spec_file" "$OUTPUT_DIR/mobile"
    
    # Format generated code
    if command -v prettier >/dev/null 2>&1; then
        prettier --write "$OUTPUT_DIR/mobile/**/*.{ts,tsx}"
    fi
    
    log_info "Expo code generated successfully"
}

# Validate OpenAPI specification
validate_spec() {
    local spec_file=$1
    log_info "Validating OpenAPI specification: $spec_file"
    
    if command -v swagger-cli >/dev/null 2>&1; then
        swagger-cli validate "$spec_file"
    else
        log_warn "swagger-cli not found. Install with: npm install -g @apidevtools/swagger-cli"
        # Basic validation using Node.js
        node scripts/validators/validate-spec.js "$spec_file"
    fi
}

# Main generation function
generate_all() {
    local spec_pattern=${1:-"**/*.yaml"}
    
    log_info "Starting code generation..."
    log_info "Looking for specs matching: $spec_pattern"
    
    # Find all spec files
    while IFS= read -r spec_file; do
        log_info "Processing: $spec_file"
        
        # Validate spec
        validate_spec "$spec_file"
        
        # Generate code for each platform
        generate_backend "$spec_file"
        generate_frontend "$spec_file"
        generate_mobile "$spec_file"
        
        log_info "Completed processing: $spec_file"
        echo ""
    done < <(find "$SPEC_DIR" -name "*.yaml" -o -name "*.yml")
    
    log_info "Code generation completed successfully!"
}

# Parse command line arguments
case "${1:-all}" in
    backend)
        validate_environment
        spec_file=${2:-"$SPEC_DIR/core/api-spec.yaml"}
        generate_backend "$spec_file"
        ;;
    frontend)
        validate_environment
        spec_file=${2:-"$SPEC_DIR/core/api-spec.yaml"}
        generate_frontend "$spec_file"
        ;;
    mobile)
        validate_environment
        spec_file=${2:-"$SPEC_DIR/core/api-spec.yaml"}
        generate_mobile "$spec_file"
        ;;
    validate)
        validate_environment
        spec_file=${2:-"$SPEC_DIR/core/api-spec.yaml"}
        validate_spec "$spec_file"
        ;;
    all)
        validate_environment
        generate_all "${2:-**/*.yaml}"
        ;;
    *)
        echo "Usage: $0 {all|backend|frontend|mobile|validate} [spec-file]"
        exit 1
        ;;
esac