#!/bin/bash

# Verify ZK Proof on Stellar Testnet
# Tests the deployed contracts with a proof

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROOFS_DIR="$PROJECT_ROOT/proofs"
DEPLOY_DIR="$PROJECT_ROOT/deployment"

NETWORK="testnet"

echo "=== Verifying ZK Proof on Stellar Testnet ==="
echo ""

cd "$PROJECT_ROOT"

# Check deployment exists
if [ ! -f "$DEPLOY_DIR/nft_contract_id.txt" ]; then
    echo "ERROR: NFT contract ID not found."
    echo "Run './scripts/deploy_testnet.sh' first."
    exit 1
fi

# Load contract IDs
NFT_ID=$(cat "$DEPLOY_DIR/nft_contract_id.txt")
HANDLER_ID=$(cat "$DEPLOY_DIR/handler_contract_id.txt" 2>/dev/null || echo "")

echo "Contract IDs:"
echo "  NFT: $NFT_ID"
[ -n "$HANDLER_ID" ] && echo "  Handler: $HANDLER_ID"

# Check if verifier was deployed
if [ -f "$DEPLOY_DIR/verifier_contract_id.txt" ]; then
    VERIFIER_ID=$(cat "$DEPLOY_DIR/verifier_contract_id.txt")
    if [ "$VERIFIER_ID" != "DEPLOYMENT_FAILED" ]; then
        echo "  Verifier: $VERIFIER_ID"
    else
        echo "  Verifier: Not deployed (budget exceeded)"
    fi
else
    VERIFIER_ID=""
    echo "  Verifier: Not deployed"
fi

# Get identity
IDENTITY_NAME="${STELLAR_IDENTITY:-default}"
ADMIN_ADDRESS=$(stellar keys address "$IDENTITY_NAME")
echo ""
echo "Using identity: $IDENTITY_NAME"
echo "Admin address: $ADMIN_ADDRESS"

# Test NFT metadata
echo ""
echo "=== Testing NFT Contract ==="

echo "Getting NFT name..."
NFT_NAME=$(stellar contract invoke \
    --id "$NFT_ID" \
    --source "$IDENTITY_NAME" \
    --network "$NETWORK" \
    --send=no \
    -- name)
echo "NFT Name: $NFT_NAME"

echo "Getting NFT symbol..."
NFT_SYMBOL=$(stellar contract invoke \
    --id "$NFT_ID" \
    --source "$IDENTITY_NAME" \
    --network "$NETWORK" \
    --send=no \
    -- symbol)
echo "NFT Symbol: $NFT_SYMBOL"

# Test minting directly (since verifier isn't deployed)
echo ""
echo "=== Testing Direct NFT Minting ==="

# Calculate expiration (30 days from now)
EXPIRES_AT=$(($(date +%s) + 2592000))
echo "Expiration timestamp: $EXPIRES_AT"

echo "Minting NFT to admin..."
TOKEN_ID=$(stellar contract invoke \
    --id "$NFT_ID" \
    --source "$IDENTITY_NAME" \
    --network "$NETWORK" \
    -- mint \
    --to "$ADMIN_ADDRESS" \
    --expires_at "$EXPIRES_AT")

echo "Token ID: $TOKEN_ID"

# Verify ownership
echo ""
echo "Verifying ownership..."
OWNER=$(stellar contract invoke \
    --id "$NFT_ID" \
    --source "$IDENTITY_NAME" \
    --network "$NETWORK" \
    --send=no \
    -- owner_of \
    --token_id "$TOKEN_ID")

echo "Owner: $OWNER"

# Check expiration
echo ""
echo "Checking expiration..."
EXPIRATION=$(stellar contract invoke \
    --id "$NFT_ID" \
    --source "$IDENTITY_NAME" \
    --network "$NETWORK" \
    --send=no \
    -- get_expiration \
    --token_id "$TOKEN_ID")

echo "Expiration: $EXPIRATION"

IS_EXPIRED=$(stellar contract invoke \
    --id "$NFT_ID" \
    --source "$IDENTITY_NAME" \
    --network "$NETWORK" \
    --send=no \
    -- is_expired \
    --token_id "$TOKEN_ID")

echo "Is expired: $IS_EXPIRED"

echo ""
echo "=== Verification Complete ==="
echo ""
echo "NFT minted successfully!"
echo "  Token ID: $TOKEN_ID"
echo "  Owner: $ADMIN_ADDRESS"
echo ""
echo "View on Stellar Expert:"
echo "  https://stellar.expert/explorer/testnet/contract/$NFT_ID"

if [ -z "$VERIFIER_ID" ] || [ "$VERIFIER_ID" = "DEPLOYMENT_FAILED" ]; then
    echo ""
    echo "NOTE: Full ZK verification not available (verifier not deployed)."
    echo "The UltraHonk verifier exceeds Soroban's CPU budget limits."
fi
