// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Stellar Soroban Contracts ^0.4.1


use soroban_sdk::{Address, Env, String, contract, contractimpl, symbol_short};
use stellar_macros::default_impl;
use stellar_tokens::non_fungible::{Base, NonFungibleToken};

#[contract]
pub struct INZPEKTORID;

#[contractimpl]
impl INZPEKTORID {
    pub fn __constructor(e: &Env, admin: Address, token_uri: String, expires_at: u64) {
        admin.require_auth();
        let name = String::from_str(e, "INZPEKTOR-ID");
        let symbol = String::from_str(e, "IZK");

        e.storage().instance().set(&symbol_short!("admin"), &admin);
        Base::set_metadata(e, token_uri, name, symbol);
        e.storage().instance().set(&symbol_short!("expires"), &expires_at);
    }

    pub fn get_expiration_timestamp(e: Env) -> u64 {
        e.storage().instance().get(&symbol_short!("expires")).unwrap_or(0)
    }

    pub fn mint(e: &Env, to: Address, token_id: u32) {
        let admin: Address = e.storage().instance().get(&symbol_short!("admin")).unwrap();
        admin.require_auth();
        Base::mint(e, &to, token_id);
    }
}

#[default_impl]
#[contractimpl]
impl NonFungibleToken for INZPEKTORID {
    type ContractType = Base;

}
