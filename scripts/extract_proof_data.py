#!/usr/bin/env python3
"""
Extract and format proof data for Soroban contract invocation.

Converts binary proof and verification key to hex format suitable for
the UltraHonk Soroban verifier contract.
"""

import os
import json
import sys

def read_binary_file(filepath):
    """Read binary file and return hex string."""
    with open(filepath, 'rb') as f:
        return f.read().hex()

def read_json_file(filepath):
    """Read JSON file and return content."""
    with open(filepath, 'r') as f:
        return json.load(f)

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    proofs_dir = os.path.join(project_root, 'proofs')

    print("=== Extracting Proof Data for Soroban ===")
    print(f"Proofs directory: {proofs_dir}")

    # Check required files exist (bb 3.0.0 creates subdirectories)
    proof_file = os.path.join(proofs_dir, 'proof', 'proof')
    vk_file = os.path.join(proofs_dir, 'vk', 'vk')
    vk_json_file = os.path.join(proofs_dir, 'vk.json')
    public_inputs_file = os.path.join(proofs_dir, 'proof', 'public_inputs')

    missing_files = []
    if not os.path.exists(proof_file):
        missing_files.append(proof_file)
    if not os.path.exists(vk_file):
        missing_files.append(vk_file)
    if not os.path.exists(vk_json_file):
        missing_files.append(vk_json_file)

    if missing_files:
        print("\nERROR: Missing required files:")
        for f in missing_files:
            print(f"  - {f}")
        print("\nRun './scripts/build_noir.sh' first to generate these files.")
        sys.exit(1)

    # Read and convert proof to hex
    print("\n1. Converting proof to hex...")
    proof_hex = read_binary_file(proof_file)
    proof_size = len(proof_hex) // 2  # bytes
    print(f"   Proof size: {proof_size} bytes")

    # Read and convert VK to hex
    print("\n2. Converting verification key to hex...")
    vk_hex = read_binary_file(vk_file)
    vk_size = len(vk_hex) // 2  # bytes
    print(f"   VK size: {vk_size} bytes")

    # Read VK JSON
    print("\n3. Reading VK JSON...")
    vk_json = read_json_file(vk_json_file)
    print(f"   VK JSON fields: {len(vk_json) if isinstance(vk_json, list) else 'object'}")

    # Create output data file
    output_data = {
        "proof_hex": proof_hex,
        "proof_size_bytes": proof_size,
        "vk_hex": vk_hex,
        "vk_size_bytes": vk_size,
        "vk_json": vk_json
    }

    output_file = os.path.join(proofs_dir, 'soroban_data.json')
    with open(output_file, 'w') as f:
        json.dump(output_data, f, indent=2)

    print(f"\n4. Data saved to: {output_file}")

    # Create shell-friendly export file
    export_file = os.path.join(proofs_dir, 'proof_data.sh')
    with open(export_file, 'w') as f:
        f.write("#!/bin/bash\n")
        f.write("# Auto-generated proof data for Soroban deployment\n\n")
        f.write(f'export PROOF_HEX="{proof_hex}"\n')
        f.write(f'export PROOF_SIZE={proof_size}\n')
        f.write(f'export VK_HEX="{vk_hex}"\n')
        f.write(f'export VK_SIZE={vk_size}\n')

    print(f"5. Shell exports saved to: {export_file}")

    # Print summary for manual use
    print("\n=== Summary ===")
    print(f"Proof (first 64 chars): {proof_hex[:64]}...")
    print(f"VK (first 64 chars): {vk_hex[:64]}...")

    print("\n=== For Stellar CLI Usage ===")
    print("To use with stellar contract invoke:")
    print(f'  --proof_blob "{proof_hex}"')
    print(f'  --vk_json (use content from vk.json)')

    print("\nNext steps:")
    print("  1. Run: ./scripts/build_soroban.sh")
    print("  2. Run: ./scripts/deploy_testnet.sh")

if __name__ == "__main__":
    main()
