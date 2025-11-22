#!/bin/bash

# Build Noir Circuit for INZPEKTOR
# Generates verification key and proof for UltraHonk

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CIRCUIT_DIR="$PROJECT_ROOT/circuits"
OUTPUT_DIR="$PROJECT_ROOT/proofs"

echo "=== Building Noir Circuit ==="
echo "Circuit directory: $CIRCUIT_DIR"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Navigate to circuit directory
cd "$CIRCUIT_DIR"

# Check Nargo version
echo ""
echo "Checking Nargo installation..."
if ! command -v nargo &> /dev/null; then
    echo "ERROR: Nargo not found. Install with:"
    echo "  curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash && noirup"
    exit 1
fi

NARGO_VERSION=$(nargo --version)
echo "Nargo version: $NARGO_VERSION"

# Check Barretenberg (bb) installation
echo ""
echo "Checking Barretenberg installation..."
if ! command -v bb &> /dev/null; then
    echo "ERROR: Barretenberg (bb) not found."
    echo "Install from: https://github.com/AztecProtocol/aztec-packages/releases"
    echo "Or build from source:"
    echo "  git clone https://github.com/AztecProtocol/aztec-packages.git"
    echo "  cd aztec-packages/barretenberg/cpp && cmake --preset clang16 && cmake --build --preset clang16"
    exit 1
fi

BB_VERSION=$(bb --version 2>&1 || echo "unknown")
echo "Barretenberg version: $BB_VERSION"

# Step 1: Compile circuit
echo ""
echo "Step 1: Compiling circuit..."
nargo compile

echo "Circuit compiled successfully!"

# Step 2: Execute circuit to generate witness
echo ""
echo "Step 2: Executing circuit to generate witness..."
nargo execute

echo "Witness generated at: target/proof_of_clean_hands.gz"

# Step 3: Generate verification key first (required for proof generation)
echo ""
echo "Step 3: Generating verification key..."

bb write_vk \
    -s ultra_honk \
    -b ./target/proof_of_clean_hands.json \
    -o "$OUTPUT_DIR/vk"

echo "Verification key generated at: $OUTPUT_DIR/vk"

# Step 4: Generate UltraHonk proof using Barretenberg
echo ""
echo "Step 4: Generating UltraHonk proof..."

# Generate proof with bb 3.0.0 syntax, specifying the VK path
bb prove \
    -s ultra_honk \
    -b ./target/proof_of_clean_hands.json \
    -w ./target/proof_of_clean_hands.gz \
    -k "$OUTPUT_DIR/vk/vk" \
    -o "$OUTPUT_DIR/proof"

echo "Proof generated at: $OUTPUT_DIR/proof"

# Step 5: Verify proof locally (optional sanity check)
echo ""
echo "Step 5: Verifying proof locally..."

bb verify \
    -s ultra_honk \
    -k "$OUTPUT_DIR/vk/vk" \
    -p "$OUTPUT_DIR/proof/proof" \
    -i "$OUTPUT_DIR/proof/public_inputs"

echo "Local verification: SUCCESS"

# Step 6: Generate JSON format for verification key (for Soroban contract)
# Note: In bb 3.0.0, we need to extract VK fields manually or use the binary VK
echo ""
echo "Step 6: Preparing VK for Soroban..."

# Create a simple JSON wrapper for the VK binary data
VK_HEX=$(xxd -p "$OUTPUT_DIR/vk/vk" | tr -d '\n')
echo "{\"vk_hex\": \"$VK_HEX\"}" > "$OUTPUT_DIR/vk.json"

# Also copy the actual VK file for easier access
cp "$OUTPUT_DIR/vk/vk" "$OUTPUT_DIR/vk_binary"

echo "VK JSON generated at: $OUTPUT_DIR/vk.json"

# Summary
echo ""
echo "=== Build Complete ==="
echo "Output files in $OUTPUT_DIR:"
ls -la "$OUTPUT_DIR"

echo ""
echo "Next steps:"
echo "  1. Run: python3 scripts/extract_proof_data.py"
echo "  2. Run: ./scripts/build_soroban.sh"
echo "  3. Run: ./scripts/deploy_testnet.sh"
