# Proof of Clean Hands - NOIR Circuit

This directory contains the zero-knowledge circuit implementation for the Proof of Clean Hands Protocol using NOIR.

## Overview

The circuit verifies that a user passes all required compliance checks without revealing which specific checks were performed or their individual results. This ensures privacy while maintaining regulatory compliance.

## Compliance Checks

The circuit verifies three critical flags:

1. **KYC (Know Your Customer)**: User has completed identity verification
2. **OFAC Sanctions**: User is NOT on the OFAC (Office of Foreign Assets Control) sanctions list
3. **USDC Blacklist**: User is NOT on the USDC stablecoin blacklist

## Circuit Logic

The circuit returns `true` (proof of clean hands) **only if ALL three checks pass**:

```
result = kyc_passed AND ofac_passed AND usdc_not_blacklisted
```

If any check fails, the circuit returns `false`, but the specific failing check remains private.

## Privacy Guarantees

- **Private Inputs**: All compliance check results are private witness values
- **Public Output**: Only the final result (pass/fail) is revealed
- **Zero-Knowledge**: The verifier learns nothing about which specific checks failed
- **No User Identifier**: Circuit focuses purely on compliance verification without linking to specific identities

## Prerequisites

Install the NOIR toolchain:

```bash
curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
noirup
```

Verify installation:

```bash
nargo --version
```

## Building the Circuit

Compile the circuit:

```bash
cd circuits
nargo check
```

Run tests:

```bash
nargo test
```

## Generating Proofs

### 1. Edit Input Values

Edit `Prover.toml` with actual values:

```toml
kyc_passed = true
ofac_passed = true
usdc_not_blacklisted = true
```

### 2. Generate Proof

```bash
nargo prove
```

This creates:
- `proofs/proof_of_clean_hands.proof` - The zero-knowledge proof
- `Verifier.toml` - Public inputs for verification

### 3. Verify Proof

```bash
nargo verify
```

## Circuit Structure

### Private Inputs (Witness)
- `kyc_passed`: Boolean flag for KYC verification
- `ofac_passed`: Boolean flag for OFAC check
- `usdc_not_blacklisted`: Boolean flag for USDC blacklist check

### Output
- `pub bool`: Returns `true` if all checks pass, `false` otherwise

## Integration with Soroban

The generated proof is verified by the `ultrahonk-zk` Soroban contract. The wallet address is linked at the Soroban level when minting the NFT:

```rust
// On Soroban (simplified)
let proof_valid = verify_ultrahonk_proof(&verification_key, &proof, &public_inputs);

if proof_valid {
    // Mint INZPEKTOR-ID NFT to the caller's wallet with expiration
    let token_id = nft_contract.mint(caller_wallet, expires_at);
}
```

## Test Cases

The circuit includes 5 test cases:

1. ✅ All checks passed - Returns `true`
2. ❌ KYC failed - Returns `false`
3. ❌ OFAC failed - Returns `false`
4. ❌ USDC blacklist failed - Returns `false`
5. ❌ Multiple failures - Returns `false`

Run tests:

```bash
nargo test --show-output
```

## Upgrading to UltraHonk

To use the UltraHonk backend (required for Soroban integration):

```bash
# Generate witness
nargo execute

# Generate UltraHonk proof (requires bb - Barretenberg)
bb prove -b ./target/proof_of_clean_hands.json -w ./target/witness.gz -o ./proofs/proof

# Verify UltraHonk proof
bb verify -k ./target/vk -p ./proofs/proof
```

## Security Considerations

1. **Data Integrity**: Ensure compliance data sources are trustworthy and tamper-proof
2. **Timestamp Validity**: Add timestamp checks to ensure compliance data is recent
3. **Revocation**: Implement a mechanism to revoke proofs if compliance status changes
4. **Proof Freshness**: Limit the validity period of generated proofs

## Future Enhancements

- [ ] Add timestamp constraints for data freshness
- [ ] Add public input for wallet address binding at circuit level
- [ ] Add support for additional compliance checks (AML, sanctions lists)
- [ ] Implement proof batching for multiple users
- [ ] Add revocation mechanism using nullifiers
- [ ] Implement signature verification for compliance data providers

## Resources

- [NOIR Documentation](https://noir-lang.org/)
- [Barretenberg (UltraHonk)](https://github.com/AztecProtocol/barretenberg)
- [NOIR Standard Library](https://noir-lang.org/docs/standard_library/array_methods)
- [Zero-Knowledge Proofs Guide](https://z.cash/technology/zksnarks/)

## License

Same as parent project (INZPEKTOR Contracts)
