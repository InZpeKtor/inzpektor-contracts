# INZPEKTOR Contracts

Smart contracts for INZPEKTOR - a zero-knowledge proof based identity verification system on Stellar/Soroban blockchain. This project is a product of the **Proof of Clean Hands Protocol** based on ZK on Stellar/Soroban.

## Overview

INZPEKTOR is a decentralized identity verification system that uses zero-knowledge proofs (UltraHonk) to verify user credentials without revealing sensitive information. Upon successful verification, users receive an INZPEKTOR-ID NFT with an expiration timestamp, serving as a verifiable credential.

## Architecture

The system consists of three main smart contracts:

### 1. UltraHonk ZK Verifier (`ultrahonk-zk`)
- Verifies zero-knowledge proofs using the UltraHonk proving system
- Validates verification keys and proof blobs
- Returns a proof ID upon successful verification
- Uses Barretenberg's UltraHonk verifier implementation

### 2. INZPEKTOR-ID NFT (`inzpektor-id-nft`)
- ERC-721 compatible NFT contract using OpenZeppelin Stellar Contracts
- Each NFT has a unique expiration timestamp (e.g., 1 year validity)
- Sequential token minting starting from token ID 0
- Implements enumerable extension for token tracking
- Owner-only minting with expiration parameter
- Built on `stellar-tokens` v0.5.0

**Key Features:**
- Per-token expiration timestamps
- `get_expiration(token_id)` - Returns expiration timestamp
- `is_expired(token_id)` - Checks if token is expired
- Standard NFT functionality (transfer, approve, balance, etc.)

### 3. Handler/Orchestrator (`inzpektor-handler`)
- Coordinates ZK verification and NFT minting
- Validates proofs through the verifier contract
- Mints NFTs with expiration upon successful verification
- Admin-controlled for security
- Provides getter functions for cross-contract queries

## Project Structure

```
inzpektor-contracts/
├── contracts/
│   ├── ultrahonk-zk/        # Zero-knowledge proof verifier
│   ├── inzpektor-id-nft/     # Identity NFT with expiration
│   └── inzpektor-handler/    # Orchestrator contract
├── Cargo.toml                # Workspace configuration
├── Makefile                  # Build and test commands
└── README.md
```

## Prerequisites

- Rust 1.70+ with `wasm32-unknown-unknown` target
- Soroban CLI
- Stellar SDK

## Installation

```bash
# Clone the repository
git clone https://github.com/INZPEKTOR/inzpektor-contracts.git
cd inzpektor-contracts

# Add wasm target
rustup target add wasm32-unknown-unknown

# Install Soroban CLI
cargo install --locked soroban-cli
```

## Building

```bash
# Build all contracts
make build

# Or use cargo directly
cargo build --target wasm32v1-none --release
```

Compiled WASM files will be in `target/wasm32v1-none/release/`

## Testing

```bash
# Run all tests
make test

# Run tests for specific contract
cargo test -p inzpektor-id-nft
cargo test -p ultrahonk-zk
cargo test -p hello-world  # handler contract
```

**Test Coverage:**
- ✅ 10 NFT contract tests (minting, expiration, ownership, metadata)
- ✅ 7 Handler contract tests (initialization, minting, getters)
- ✅ 17 total tests passing

## Usage Flow

1. **Setup Phase:**
   - Deploy all three contracts
   - Initialize handler with admin address and contract references
   - Initialize NFT contract with owner address

2. **Verification & Minting:**
   ```rust
   // User generates ZK proof off-chain
   let vk_json = generate_verification_key();
   let proof_blob = generate_proof(user_credentials);

   // Call handler to verify and mint
   let token_id = handler.mint_inzpektor_id(
       user_address,
       current_time + ONE_YEAR,  // expiration
       vk_json,
       proof_blob
   );
   ```

3. **Token Lifecycle:**
   ```rust
   // Check expiration
   let expiration = nft.get_expiration(token_id);
   let is_expired = nft.is_expired(token_id);

   // Transfer token (expiration transfers with it)
   nft.transfer_from(from, to, token_id);
   ```

## Configuration

### Workspace Dependencies (Cargo.toml)
- `soroban-sdk`: 23.2.1
- `stellar-tokens`: 0.5.0 (OpenZeppelin-compatible NFTs)
- `stellar-access`: 0.5.0 (Access control)
- `stellar-macros`: 0.5.0 (Helper macros)

### Contract Metadata
- **NFT Name:** INZPEKTOR-ID
- **NFT Symbol:** IZK
- **Base URI:** https://www.inzpektor.com/ids/
- **License:** MIT

## Key Functions

### Handler Contract
- `initialize(admin, verifier, nft_contract)` - Setup contract references
- `mint_inzpektor_id(user, expires_at, vk_json, proof_blob)` - Verify proof and mint NFT
- `get_nft_expiration(token_id)` - Query token expiration
- `is_nft_expired(token_id)` - Check if token expired

### NFT Contract
- `initialize(owner)` - Initialize contract with owner
- `mint(to, expires_at)` - Mint NFT with expiration (owner only)
- `get_expiration(token_id)` - Get token expiration timestamp
- `is_expired(token_id)` - Check if token is expired
- Standard ERC-721 functions (transfer, approve, balance, etc.)

### Verifier Contract
- `verify_proof(vk_json, proof_blob)` - Verify ZK proof
- `is_verified(proof_id)` - Check if proof was verified

## Development

```bash
# Format code
cargo fmt --all

# Check formatting
make fmt

# Run clippy
cargo clippy --all-targets --all-features
```

## Security Considerations

- ⚠️ Handler contract has admin-only minting for security
- ⚠️ NFT contract uses owner-only minting pattern
- ⚠️ Expiration timestamps are set at mint time and immutable
- ⚠️ Expired NFTs can still be transferred (expiration is informational)
- ⚠️ ZK proof verification happens on-chain

## Contributing

Contributions are welcome! Please ensure:
- All tests pass (`make test`)
- Code is formatted (`cargo fmt`)
- New features include tests
- Documentation is updated

## License

MIT License - see LICENSE file for details

## Links

- [Soroban Documentation](https://soroban.stellar.org/docs)
- [Stellar Network](https://stellar.org)
- [OpenZeppelin Stellar Contracts](https://github.com/OpenZeppelin/openzeppelin-soroban-contracts)

## Contact

For questions or support, please open an issue in the repository.
