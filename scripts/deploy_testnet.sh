#!/bin/bash

# Deploy INZPEKTOR contracts to Stellar Testnet
# Deploys: NFT and Handler contracts (Verifier may exceed budget)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPLOY_DIR="$PROJECT_ROOT/deployment"

# Network configuration
NETWORK="testnet"

echo "=== Deploying INZPEKTOR to Stellar Testnet ==="
echo ""

# Create deployment directory
mkdir -p "$DEPLOY_DIR"

cd "$PROJECT_ROOT"

# Check Stellar CLI
if ! command -v stellar &> /dev/null; then
    echo "ERROR: Stellar CLI not found. Install with:"
    echo "  cargo install --locked stellar-cli --features opt"
    exit 1
fi

# Check or create identity
IDENTITY_NAME="${STELLAR_IDENTITY:-default}"
echo "Checking identity: $IDENTITY_NAME"

if ! stellar keys address "$IDENTITY_NAME" &>/dev/null; then
    echo "Creating new identity..."
    stellar keys generate "$IDENTITY_NAME" --network "$NETWORK"
fi

# Get admin address
ADMIN_ADDRESS=$(stellar keys address "$IDENTITY_NAME")
echo "Admin address: $ADMIN_ADDRESS"

# Fund account
echo ""
echo "Funding account via Friendbot..."
stellar keys fund "$IDENTITY_NAME" --network "$NETWORK" 2>/dev/null || echo "Account already funded or funding failed"

# Find WASM directory
WASM_DIR="$PROJECT_ROOT/target/wasm32v1-none/release"
if [ ! -d "$WASM_DIR" ]; then
    WASM_DIR="$PROJECT_ROOT/target/wasm32-unknown-unknown/release"
fi

if [ ! -d "$WASM_DIR" ]; then
    echo "ERROR: WASM directory not found. Run './scripts/build_soroban.sh' first."
    exit 1
fi

# Deploy NFT Contract
echo ""
echo "=== Deploying INZPEKTOR-ID NFT Contract ==="

NFT_WASM="$WASM_DIR/inzpektor_id_nft.wasm"
if [ ! -f "$NFT_WASM" ]; then
    echo "ERROR: NFT WASM not found at $NFT_WASM"
    exit 1
fi

NFT_ID=$(stellar contract deploy \
    --wasm "$NFT_WASM" \
    --source "$IDENTITY_NAME" \
    --network "$NETWORK")

echo "NFT Contract ID: $NFT_ID"
echo "$NFT_ID" > "$DEPLOY_DIR/nft_contract_id.txt"

# Deploy Handler Contract
echo ""
echo "=== Deploying Handler Contract ==="

HANDLER_WASM="$WASM_DIR/inzpektor_handler.wasm"
if [ ! -f "$HANDLER_WASM" ]; then
    echo "ERROR: Handler WASM not found at $HANDLER_WASM"
    exit 1
fi

HANDLER_ID=$(stellar contract deploy \
    --wasm "$HANDLER_WASM" \
    --source "$IDENTITY_NAME" \
    --network "$NETWORK")

echo "Handler Contract ID: $HANDLER_ID"
echo "$HANDLER_ID" > "$DEPLOY_DIR/handler_contract_id.txt"

# Try to deploy Verifier Contract (may fail due to budget limits)
echo ""
echo "=== Deploying UltraHonk Verifier Contract ==="
echo "NOTE: This contract is large (163KB) and may exceed Soroban budget limits."

VERIFIER_WASM="$WASM_DIR/ultrahonk_zk.wasm"
VERIFIER_ID=""

if [ -f "$VERIFIER_WASM" ]; then
    if stellar contract deploy \
        --wasm "$VERIFIER_WASM" \
        --source "$IDENTITY_NAME" \
        --network "$NETWORK" > "$DEPLOY_DIR/verifier_output.txt" 2>&1; then
        VERIFIER_ID=$(cat "$DEPLOY_DIR/verifier_output.txt")
        echo "Verifier Contract ID: $VERIFIER_ID"
        echo "$VERIFIER_ID" > "$DEPLOY_DIR/verifier_contract_id.txt"
    else
        echo "WARNING: Verifier deployment failed (budget exceeded)"
        echo "This is expected - UltraHonk verification exceeds Soroban limits."
        echo "Error details saved to: $DEPLOY_DIR/verifier_output.txt"
        VERIFIER_ID="DEPLOYMENT_FAILED"
    fi
else
    echo "WARNING: Verifier WASM not found at $VERIFIER_WASM"
    VERIFIER_ID="NOT_FOUND"
fi

# Initialize NFT Contract
echo ""
echo "=== Initializing NFT Contract ==="

stellar contract invoke \
    --id "$NFT_ID" \
    --source "$IDENTITY_NAME" \
    --network "$NETWORK" \
    -- initialize \
    --owner "$ADMIN_ADDRESS"

echo "NFT contract initialized with owner: $ADMIN_ADDRESS"

# Initialize Handler Contract (only if verifier deployed)
if [ "$VERIFIER_ID" != "DEPLOYMENT_FAILED" ] && [ "$VERIFIER_ID" != "NOT_FOUND" ]; then
    echo ""
    echo "=== Initializing Handler Contract ==="

    stellar contract invoke \
        --id "$HANDLER_ID" \
        --source "$IDENTITY_NAME" \
        --network "$NETWORK" \
        -- initialize \
        --admin "$ADMIN_ADDRESS" \
        --verifier_contract "$VERIFIER_ID" \
        --inzpektor_id_contract "$NFT_ID"

    echo "Handler contract initialized!"
else
    echo ""
    echo "=== Skipping Handler Initialization ==="
    echo "Handler requires verifier contract to be deployed first."
fi

# Save deployment summary
cat > "$DEPLOY_DIR/deployment_summary.json" << EOF
{
  "network": "$NETWORK",
  "admin_address": "$ADMIN_ADDRESS",
  "contracts": {
    "nft": "$NFT_ID",
    "handler": "$HANDLER_ID",
    "verifier": "$VERIFIER_ID"
  },
  "deployed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo ""
echo "=== Deployment Summary ==="
echo ""
echo "Deployment saved to: $DEPLOY_DIR/deployment_summary.json"
echo ""
echo "Contract IDs:"
echo "  NFT:      $NFT_ID"
echo "  Handler:  $HANDLER_ID"
echo "  Verifier: $VERIFIER_ID"
echo ""
echo "Admin: $ADMIN_ADDRESS"
echo ""
echo "View on Stellar Expert:"
echo "  https://stellar.expert/explorer/testnet/contract/$NFT_ID"
echo "  https://stellar.expert/explorer/testnet/contract/$HANDLER_ID"

if [ "$VERIFIER_ID" = "DEPLOYMENT_FAILED" ]; then
    echo ""
    echo "=== IMPORTANT ==="
    echo "The UltraHonk verifier exceeded Soroban's CPU budget."
    echo "Consider using a mock verifier for testing purposes."
fi
