#![no_std]

use soroban_sdk::{Address, Bytes, BytesN, Env, IntoVal, String, Symbol, contract, contractimpl, contracttype, vec};

// Create a DataKey type for storing admin and contract addresses
#[contracttype]
enum DataKey {
    Admin,
    ZKVerifierContract,
    InzpektorIDNFTContract,
}


#[contract]
pub struct InzpektorHandlerContract;

#[contractimpl]
impl InzpektorHandlerContract {
    pub fn __constructor(e: &Env, admin: Address, verifier_contract: Address, inzpektor_id_contract: Address) {
        admin.require_auth();
        // Initialization logic can be added here if needed
        e.storage().instance().set(&DataKey::Admin, &admin);
        e.storage().instance().set(&DataKey::ZKVerifierContract, &verifier_contract);
        e.storage().instance().set(&DataKey::InzpektorIDNFTContract, &inzpektor_id_contract);
    }

    pub fn mint_inzpektor_id(e: Env, user: Address, _nft_expires_at: u64, vk_json: Bytes, proof_blob: Bytes) -> String {
      let actual_admin: Address = e.storage().instance().get(&DataKey::Admin).expect("admin not set");
      actual_admin.require_auth();

      // Verify proof by calling the verifier contract
      let verifier_contract_address: Address = e.storage().instance().get(&DataKey::ZKVerifierContract).expect("verifier not set");

      // Call verify_proof on the ultrahonk verifier contract
      let verify_fn = Symbol::new(&e, "verify_proof");
      let _proof_id: BytesN<32> = e.invoke_contract(
          &verifier_contract_address,
          &verify_fn,
          vec![&e, vk_json.into_val(&e), proof_blob.into_val(&e)]
      );

      // Proof verified successfully, mint INZPEKTOR-ID NFT
      let inzpektor_id_contract_address: Address = e.storage().instance().get(&DataKey::InzpektorIDNFTContract).expect("INZPEKTOR-ID contract not set");

      // Call mint on the NFT contract
      let mint_fn = Symbol::new(&e, "mint");
      let token_id: u32 = 1; // In practice, this should be unique
      let _: () = e.invoke_contract(
          &inzpektor_id_contract_address,
          &mint_fn,
          vec![&e, user.into_val(&e), token_id.into_val(&e)]
      );

      String::from_str(&e, "Minted INZPEKTOR-ID NFT successfully")
    }

    pub fn get_nft_balance(e: Env, user: Address) -> u32 {
        let inzpektor_id_contract_address: Address = e.storage().instance().get(&DataKey::InzpektorIDNFTContract).expect("INZPEKTOR-ID contract not set");
        
        let balance_fn = Symbol::new(&e, "balance");
        let balance: u32 = e.invoke_contract(
            &inzpektor_id_contract_address,
            &balance_fn,
            vec![&e, user.into_val(&e)]
        );
        
        balance
    }

    pub fn get_admin(e: Env) -> Address {
        e.storage().instance().get(&DataKey::Admin).expect("admin not set")
    }

    pub fn get_verifier_contract(e: Env) -> Address {
        e.storage().instance().get(&DataKey::ZKVerifierContract).expect("verifier not set")
    }

    pub fn get_nft_contract(e: Env) -> Address {
        e.storage().instance().get(&DataKey::InzpektorIDNFTContract).expect("NFT contract not set")
    }

    pub fn get_nft_owner(e: Env, token_id: u32) -> Address {
        let inzpektor_id_contract_address: Address = e.storage().instance().get(&DataKey::InzpektorIDNFTContract).expect("INZPEKTOR-ID contract not set");
        
        let owner_fn = Symbol::new(&e, "owner_of");
        let owner: Address = e.invoke_contract(
            &inzpektor_id_contract_address,
            &owner_fn,
            vec![&e, token_id.into_val(&e)]
        );
        
        owner
    }

    pub fn get_nft_metadata(e: Env) -> (String, String, String) {
        let inzpektor_id_contract_address: Address = e.storage().instance().get(&DataKey::InzpektorIDNFTContract).expect("INZPEKTOR-ID contract not set");
        
        let name_fn = Symbol::new(&e, "name");
        let name: String = e.invoke_contract(
            &inzpektor_id_contract_address,
            &name_fn,
            vec![&e]
        );

        let symbol_fn = Symbol::new(&e, "symbol");
        let symbol: String = e.invoke_contract(
            &inzpektor_id_contract_address,
            &symbol_fn,
            vec![&e]
        );

        let base_uri_fn = Symbol::new(&e, "base_uri");
        let base_uri: String = e.invoke_contract(
            &inzpektor_id_contract_address,
            &base_uri_fn,
            vec![&e]
        );
        
        (name, symbol, base_uri)
    }

    pub fn get_nft_expiration(e: Env) -> u64 {
        let inzpektor_id_contract_address: Address = e.storage().instance().get(&DataKey::InzpektorIDNFTContract).expect("INZPEKTOR-ID contract not set");
        
        let expiration_fn = Symbol::new(&e, "get_expiration_timestamp");
        let expiration: u64 = e.invoke_contract(
            &inzpektor_id_contract_address,
            &expiration_fn,
            vec![&e]
        );
        
        expiration
    }
}

mod test;