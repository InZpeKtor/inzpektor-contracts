#!/bin/bash

# Set Verification Key in UltraHonk Verifier Contract
# Must be run after deployment and proof generation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROOFS_DIR="$PROJECT_ROOT/proofs"
DEPLOY_DIR="$PROJECT_ROOT/deployment"

# Network configuration
NETWORK="testnet"

echo "=== Setting Verification Key ==="
echo ""

# Check deployment exists
if [ ! -f "$DEPLOY_DIR/verifier_contract_id.txt" ]; then
    echo "ERROR: Verifier contract ID not found."
    echo "Run './scripts/deploy_testnet.sh' first."
    exit 1
fi

VERIFIER_ID=$(cat "$DEPLOY_DIR/verifier_contract_id.txt")
echo "Verifier Contract: $VERIFIER_ID"

# Check VK JSON exists
VK_JSON_FILE="$PROOFS_DIR/vk.json"
if [ ! -f "$VK_JSON_FILE" ]; then
    echo "ERROR: VK JSON not found at $VK_JSON_FILE"
    echo "Run './scripts/build_noir.sh' first."
    exit 1
fi

# Get identity
IDENTITY_NAME="${STELLAR_IDENTITY:-default}"
echo "Using identity: $IDENTITY_NAME"

# Read VK JSON content
echo ""
echo "Reading verification key..."
VK_JSON=$(cat "$VK_JSON_FILE")

# Convert to bytes for Soroban (hex encoding)
VK_HEX=$(echo -n "$VK_JSON" | xxd -p | tr -d '\n')

echo "VK JSON size: $(echo -n "$VK_JSON" | wc -c | tr -d ' ') bytes"
echo "VK HEX size: $((${#VK_HEX} / 2)) bytes"

# Set VK in verifier contract
echo ""
echo "Setting verification key in contract..."

VK_HASH=$(stellar contract invoke \
    --id "$VERIFIER_ID" \
    --source "$IDENTITY_NAME" \
    --network "$NETWORK" \
    -- set_vk \
    --vk_json "$VK_HEX")

echo ""
echo "=== Verification Key Set ==="
echo "VK Hash: $VK_HASH"
echo ""
echo "Next step: ./scripts/verify_proof.sh"
