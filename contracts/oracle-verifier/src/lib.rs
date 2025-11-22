#![no_std]

use soroban_sdk::{
    contract, contracterror, contractimpl, contracttype, symbol_short, Address, Bytes, BytesN,
    Env, Map, Symbol, Vec,
};

/// Oracle-based ZK Verifier for INZPEKTOR
///
/// This contract provides a secure bridge between off-chain ZK proof verification
/// and on-chain state. It uses a trusted oracle network to verify proofs and
/// attest results on-chain.
///
/// Security Model:
/// - Multi-sig oracle attestation (M of N required)
/// - Proof commitments stored on-chain for auditability
/// - Challenge period for disputes
/// - All proof data is verifiable off-chain

#[contract]
pub struct OracleVerifier;

#[contracttype]
#[derive(Clone)]
pub struct ProofRequest {
    /// Hash of the proof data
    pub proof_hash: BytesN<32>,
    /// Hash of the verification key
    pub vk_hash: BytesN<32>,
    /// Hash of public inputs
    pub public_inputs_hash: BytesN<32>,
    /// Timestamp when submitted
    pub submitted_at: u64,
    /// Number of oracle attestations received
    pub attestation_count: u32,
    /// Whether verification passed
    pub verified: bool,
    /// Whether finalized (after challenge period)
    pub finalized: bool,
}

#[contracttype]
pub enum DataKey {
    /// Contract admin
    Admin,
    /// List of authorized oracles
    Oracles,
    /// Minimum attestations required
    MinAttestations,
    /// Challenge period in seconds
    ChallengePeriod,
    /// Proof request by request_id
    Request(BytesN<32>),
    /// Track which oracles have attested to which requests
    Attestation(BytesN<32>, Address),
    /// Verified proofs (proof_hash -> true)
    Verified(BytesN<32>),
    /// Counter for total verifications
    TotalVerified,
}

#[contracterror]
#[repr(u32)]
#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum Error {
    /// Caller is not the admin
    NotAdmin = 1,
    /// Caller is not an authorized oracle
    NotOracle = 2,
    /// Oracle has already attested to this request
    AlreadyAttested = 3,
    /// Challenge period has not ended
    ChallengePeriodActive = 4,
    /// Not enough attestations
    InsufficientAttestations = 5,
    /// Request not found
    RequestNotFound = 6,
    /// Already initialized
    AlreadyInitialized = 7,
    /// Request already finalized
    AlreadyFinalized = 8,
}

#[contractimpl]
impl OracleVerifier {
    /// Initialize the contract with admin and oracle configuration
    pub fn initialize(
        env: Env,
        admin: Address,
        oracles: Vec<Address>,
        min_attestations: u32,
        challenge_period_secs: u64,
    ) -> Result<(), Error> {
        // Check not already initialized
        if env.storage().instance().has(&DataKey::Admin) {
            return Err(Error::AlreadyInitialized);
        }

        admin.require_auth();

        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage().instance().set(&DataKey::Oracles, &oracles);
        env.storage()
            .instance()
            .set(&DataKey::MinAttestations, &min_attestations);
        env.storage()
            .instance()
            .set(&DataKey::ChallengePeriod, &challenge_period_secs);
        env.storage()
            .instance()
            .set(&DataKey::TotalVerified, &0u64);

        Ok(())
    }

    /// Submit a proof for verification
    /// Returns the request_id (hash of all inputs)
    pub fn submit_proof(
        env: Env,
        proof_hash: BytesN<32>,
        vk_hash: BytesN<32>,
        public_inputs_hash: BytesN<32>,
    ) -> BytesN<32> {
        // Create unique request ID by hashing all inputs + timestamp
        let timestamp = env.ledger().timestamp();

        let mut hasher_input = Bytes::new(&env);
        hasher_input.append(&Bytes::from_array(&env, &proof_hash.to_array()));
        hasher_input.append(&Bytes::from_array(&env, &vk_hash.to_array()));
        hasher_input.append(&Bytes::from_array(&env, &public_inputs_hash.to_array()));

        // Add timestamp bytes
        let ts_bytes = timestamp.to_be_bytes();
        for b in ts_bytes {
            hasher_input.push_back(b);
        }

        let request_id: BytesN<32> = env.crypto().keccak256(&hasher_input).into();

        let request = ProofRequest {
            proof_hash: proof_hash.clone(),
            vk_hash: vk_hash.clone(),
            public_inputs_hash,
            submitted_at: timestamp,
            attestation_count: 0,
            verified: false,
            finalized: false,
        };

        env.storage()
            .persistent()
            .set(&DataKey::Request(request_id.clone()), &request);

        // Emit event
        env.events().publish(
            (symbol_short!("submit"), request_id.clone()),
            (proof_hash, vk_hash),
        );

        request_id
    }

    /// Oracle attests that a proof is valid
    /// Called after the oracle verifies the proof off-chain
    pub fn attest(
        env: Env,
        oracle: Address,
        request_id: BytesN<32>,
        is_valid: bool,
    ) -> Result<(), Error> {
        oracle.require_auth();

        // Verify oracle is authorized
        let oracles: Vec<Address> = env
            .storage()
            .instance()
            .get(&DataKey::Oracles)
            .unwrap_or(Vec::new(&env));

        let mut is_authorized = false;
        for i in 0..oracles.len() {
            if oracles.get(i).unwrap() == oracle {
                is_authorized = true;
                break;
            }
        }
        if !is_authorized {
            return Err(Error::NotOracle);
        }

        // Check not already attested
        let attestation_key = DataKey::Attestation(request_id.clone(), oracle.clone());
        if env.storage().persistent().has(&attestation_key) {
            return Err(Error::AlreadyAttested);
        }

        // Get request
        let mut request: ProofRequest = env
            .storage()
            .persistent()
            .get(&DataKey::Request(request_id.clone()))
            .ok_or(Error::RequestNotFound)?;

        if request.finalized {
            return Err(Error::AlreadyFinalized);
        }

        // Record attestation
        env.storage().persistent().set(&attestation_key, &is_valid);

        // Update request
        if is_valid {
            request.attestation_count += 1;

            // Check if threshold met
            let min_attestations: u32 = env
                .storage()
                .instance()
                .get(&DataKey::MinAttestations)
                .unwrap_or(1);

            if request.attestation_count >= min_attestations {
                request.verified = true;
            }
        }

        env.storage()
            .persistent()
            .set(&DataKey::Request(request_id.clone()), &request);

        // Emit event
        env.events().publish(
            (symbol_short!("attest"), request_id),
            (oracle, is_valid),
        );

        Ok(())
    }

    /// Finalize verification after challenge period
    /// Anyone can call this once the challenge period has passed
    pub fn finalize(env: Env, request_id: BytesN<32>) -> Result<bool, Error> {
        let mut request: ProofRequest = env
            .storage()
            .persistent()
            .get(&DataKey::Request(request_id.clone()))
            .ok_or(Error::RequestNotFound)?;

        if request.finalized {
            return Err(Error::AlreadyFinalized);
        }

        // Check challenge period has passed
        let challenge_period: u64 = env
            .storage()
            .instance()
            .get(&DataKey::ChallengePeriod)
            .unwrap_or(3600);

        let current_time = env.ledger().timestamp();
        if current_time < request.submitted_at + challenge_period {
            return Err(Error::ChallengePeriodActive);
        }

        // Check minimum attestations
        let min_attestations: u32 = env
            .storage()
            .instance()
            .get(&DataKey::MinAttestations)
            .unwrap_or(1);

        if request.attestation_count < min_attestations {
            return Err(Error::InsufficientAttestations);
        }

        // Finalize
        request.finalized = true;
        env.storage()
            .persistent()
            .set(&DataKey::Request(request_id.clone()), &request);

        // If verified, mark proof as verified
        if request.verified {
            env.storage()
                .persistent()
                .set(&DataKey::Verified(request.proof_hash.clone()), &true);

            // Increment counter
            let mut total: u64 = env
                .storage()
                .instance()
                .get(&DataKey::TotalVerified)
                .unwrap_or(0);
            total += 1;
            env.storage()
                .instance()
                .set(&DataKey::TotalVerified, &total);
        }

        // Emit event
        env.events().publish(
            (symbol_short!("finalize"), request_id),
            request.verified,
        );

        Ok(request.verified)
    }

    // ========== View Functions ==========

    /// Check if a proof has been verified
    pub fn is_proof_verified(env: Env, proof_hash: BytesN<32>) -> bool {
        env.storage()
            .persistent()
            .get(&DataKey::Verified(proof_hash))
            .unwrap_or(false)
    }

    /// Get request details
    pub fn get_request(env: Env, request_id: BytesN<32>) -> Option<ProofRequest> {
        env.storage()
            .persistent()
            .get(&DataKey::Request(request_id))
    }

    /// Get admin address
    pub fn get_admin(env: Env) -> Option<Address> {
        env.storage().instance().get(&DataKey::Admin)
    }

    /// Get list of oracles
    pub fn get_oracles(env: Env) -> Vec<Address> {
        env.storage()
            .instance()
            .get(&DataKey::Oracles)
            .unwrap_or(Vec::new(&env))
    }

    /// Get minimum attestations required
    pub fn get_min_attestations(env: Env) -> u32 {
        env.storage()
            .instance()
            .get(&DataKey::MinAttestations)
            .unwrap_or(1)
    }

    /// Get challenge period in seconds
    pub fn get_challenge_period(env: Env) -> u64 {
        env.storage()
            .instance()
            .get(&DataKey::ChallengePeriod)
            .unwrap_or(3600)
    }

    /// Get total number of verified proofs
    pub fn get_total_verified(env: Env) -> u64 {
        env.storage()
            .instance()
            .get(&DataKey::TotalVerified)
            .unwrap_or(0)
    }

    // ========== Admin Functions ==========

    /// Add a new oracle (admin only)
    pub fn add_oracle(env: Env, admin: Address, oracle: Address) -> Result<(), Error> {
        admin.require_auth();

        let stored_admin: Address = env
            .storage()
            .instance()
            .get(&DataKey::Admin)
            .ok_or(Error::NotAdmin)?;

        if admin != stored_admin {
            return Err(Error::NotAdmin);
        }

        let mut oracles: Vec<Address> = env
            .storage()
            .instance()
            .get(&DataKey::Oracles)
            .unwrap_or(Vec::new(&env));

        oracles.push_back(oracle.clone());
        env.storage().instance().set(&DataKey::Oracles, &oracles);

        env.events()
            .publish((symbol_short!("oracle"), symbol_short!("add")), oracle);

        Ok(())
    }

    /// Update minimum attestations (admin only)
    pub fn set_min_attestations(
        env: Env,
        admin: Address,
        min_attestations: u32,
    ) -> Result<(), Error> {
        admin.require_auth();

        let stored_admin: Address = env
            .storage()
            .instance()
            .get(&DataKey::Admin)
            .ok_or(Error::NotAdmin)?;

        if admin != stored_admin {
            return Err(Error::NotAdmin);
        }

        env.storage()
            .instance()
            .set(&DataKey::MinAttestations, &min_attestations);

        Ok(())
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use soroban_sdk::testutils::{Address as _, Ledger};

    #[test]
    fn test_initialize() {
        let env = Env::default();
        let contract_id = env.register(OracleVerifier, ());
        let client = OracleVerifierClient::new(&env, &contract_id);

        let admin = Address::generate(&env);
        let oracle1 = Address::generate(&env);
        let oracle2 = Address::generate(&env);

        env.mock_all_auths();

        let oracles = Vec::from_array(&env, [oracle1.clone(), oracle2.clone()]);
        client.initialize(&admin, &oracles, &2, &3600);

        assert_eq!(client.get_admin(), Some(admin));
        assert_eq!(client.get_min_attestations(), 2);
        assert_eq!(client.get_challenge_period(), 3600);
    }

    #[test]
    fn test_full_verification_flow() {
        let env = Env::default();
        let contract_id = env.register(OracleVerifier, ());
        let client = OracleVerifierClient::new(&env, &contract_id);

        let admin = Address::generate(&env);
        let oracle1 = Address::generate(&env);
        let oracle2 = Address::generate(&env);

        env.mock_all_auths();

        // Initialize
        let oracles = Vec::from_array(&env, [oracle1.clone(), oracle2.clone()]);
        client.initialize(&admin, &oracles, &2, &100);

        // Submit proof
        let proof_hash = BytesN::from_array(&env, &[1u8; 32]);
        let vk_hash = BytesN::from_array(&env, &[2u8; 32]);
        let inputs_hash = BytesN::from_array(&env, &[3u8; 32]);

        let request_id = client.submit_proof(&proof_hash, &vk_hash, &inputs_hash);

        // Oracle 1 attests
        client.attest(&oracle1, &request_id, &true);

        // Check not yet verified (need 2 attestations)
        let request = client.get_request(&request_id).unwrap();
        assert_eq!(request.attestation_count, 1);
        assert!(!request.verified);

        // Oracle 2 attests
        client.attest(&oracle2, &request_id, &true);

        // Now verified
        let request = client.get_request(&request_id).unwrap();
        assert_eq!(request.attestation_count, 2);
        assert!(request.verified);

        // Advance time past challenge period
        env.ledger().with_mut(|li| {
            li.timestamp = 200;
        });

        // Finalize
        let result = client.finalize(&request_id);
        assert!(result);

        // Check proof is verified
        assert!(client.is_proof_verified(&proof_hash));
        assert_eq!(client.get_total_verified(), 1);
    }
}
