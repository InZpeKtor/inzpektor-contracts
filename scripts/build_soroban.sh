#!/bin/bash

# Build Soroban contracts for INZPEKTOR
# Produces optimized WASM files for deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Building Soroban Contracts ==="
echo "Project root: $PROJECT_ROOT"

cd "$PROJECT_ROOT"

# Check Stellar CLI
echo ""
echo "Checking Stellar CLI installation..."
if ! command -v stellar &> /dev/null; then
    echo "ERROR: Stellar CLI not found. Install with:"
    echo "  cargo install --locked stellar-cli --features opt"
    exit 1
fi

STELLAR_VERSION=$(stellar --version | head -1)
echo "Stellar CLI version: $STELLAR_VERSION"

# Check Rust target (Stellar SDK 23+ uses wasm32v1-none)
echo ""
echo "Checking WASM target..."
if rustup target list --installed | grep -q "wasm32v1-none\|wasm32-unknown-unknown"; then
    echo "WASM target available"
else
    echo "Installing wasm32v1-none target..."
    rustup target add wasm32v1-none || rustup target add wasm32-unknown-unknown
fi

# Build all contracts
echo ""
echo "Building contracts..."
stellar contract build

# Find built WASM files
echo ""
echo "=== Build Complete ==="

# Determine WASM directory
WASM_DIR="$PROJECT_ROOT/target/wasm32v1-none/release"
if [ ! -d "$WASM_DIR" ]; then
    WASM_DIR="$PROJECT_ROOT/target/wasm32-unknown-unknown/release"
fi

if [ ! -d "$WASM_DIR" ]; then
    echo "ERROR: No WASM output directory found"
    exit 1
fi

echo "WASM files in $WASM_DIR:"
echo ""

# List and show sizes
for wasm in "$WASM_DIR"/*.wasm; do
    if [ -f "$wasm" ]; then
        size=$(wc -c < "$wasm" | tr -d ' ')
        name=$(basename "$wasm")
        size_kb=$((size / 1024))
        echo "  $name: ${size_kb}KB ($size bytes)"
    fi
done

echo ""
echo "Next steps:"
echo "  1. Run: ./scripts/deploy_testnet.sh"
