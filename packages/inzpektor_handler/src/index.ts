import { Buffer } from "buffer";
import { Address } from '@stellar/stellar-sdk';
import {
  AssembledTransaction,
  Client as ContractClient,
  ClientOptions as ContractClientOptions,
  MethodOptions,
  Result,
  Spec as ContractSpec,
} from '@stellar/stellar-sdk/contract';
import type {
  u32,
  i32,
  u64,
  i64,
  u128,
  i128,
  u256,
  i256,
  AssembledTransactionOptions,
  Option,
  Typepoint,
  Duration,
} from '@stellar/stellar-sdk/contract';
export * from '@stellar/stellar-sdk'
export * as contract from '@stellar/stellar-sdk/contract'
export * as rpc from '@stellar/stellar-sdk/rpc'

if (typeof window !== 'undefined') {
  //@ts-ignore Buffer exists
  window.Buffer = window.Buffer || Buffer;
}


export const networks = {
  standalone: {
    networkPassphrase: "Standalone Network ; February 2017",
    contractId: "CCTF5O6EDDWDZKBGXWNNBMJF5UVCF4PHMRZ6LSBUTE746TLTPLM5J5VJ",
  }
} as const


export interface Client {
  /**
   * Construct and simulate a get_admin transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   */
  get_admin: (options?: AssembledTransactionOptions<string>) => Promise<AssembledTransaction<string>>

  /**
   * Construct and simulate a initialize transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   */
  initialize: ({admin, verifier_contract, inzpektor_id_contract}: {admin: string, verifier_contract: string, inzpektor_id_contract: string}, options?: AssembledTransactionOptions<null>) => Promise<AssembledTransaction<null>>

  /**
   * Construct and simulate a get_nft_owner transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   */
  get_nft_owner: ({token_id}: {token_id: u32}, options?: AssembledTransactionOptions<string>) => Promise<AssembledTransaction<string>>

  /**
   * Construct and simulate a is_nft_expired transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   */
  is_nft_expired: ({token_id}: {token_id: u32}, options?: AssembledTransactionOptions<boolean>) => Promise<AssembledTransaction<boolean>>

  /**
   * Construct and simulate a get_nft_balance transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   */
  get_nft_balance: ({user}: {user: string}, options?: AssembledTransactionOptions<u32>) => Promise<AssembledTransaction<u32>>

  /**
   * Construct and simulate a get_nft_contract transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   */
  get_nft_contract: (options?: AssembledTransactionOptions<string>) => Promise<AssembledTransaction<string>>

  /**
   * Construct and simulate a get_nft_metadata transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   */
  get_nft_metadata: (options?: AssembledTransactionOptions<readonly [string, string, string]>) => Promise<AssembledTransaction<readonly [string, string, string]>>

  /**
   * Construct and simulate a mint_inzpektor_id transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   */
  mint_inzpektor_id: ({user, expires_at, vk_json, proof_blob}: {user: string, expires_at: u64, vk_json: Buffer, proof_blob: Buffer}, options?: AssembledTransactionOptions<u32>) => Promise<AssembledTransaction<u32>>

  /**
   * Construct and simulate a get_nft_expiration transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   */
  get_nft_expiration: ({token_id}: {token_id: u32}, options?: AssembledTransactionOptions<u64>) => Promise<AssembledTransaction<u64>>

  /**
   * Construct and simulate a get_verifier_contract transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   */
  get_verifier_contract: (options?: AssembledTransactionOptions<string>) => Promise<AssembledTransaction<string>>

}
export class Client extends ContractClient {
  static async deploy<T = Client>(
    /** Options for initializing a Client as well as for calling a method, with extras specific to deploying. */
    options: MethodOptions &
      Omit<ContractClientOptions, "contractId"> & {
        /** The hash of the Wasm blob, which must already be installed on-chain. */
        wasmHash: Buffer | string;
        /** Salt used to generate the contract's ID. Passed through to {@link Operation.createCustomContract}. Default: random. */
        salt?: Buffer | Uint8Array;
        /** The format used to decode `wasmHash`, if it's provided as a string. */
        format?: "hex" | "base64";
      }
  ): Promise<AssembledTransaction<T>> {
    return ContractClient.deploy(null, options)
  }
  constructor(public readonly options: ContractClientOptions) {
    super(
      new ContractSpec([ "AAAAAAAAAAAAAAAJZ2V0X2FkbWluAAAAAAAAAAAAAAEAAAAT",
        "AAAAAAAAAAAAAAAKaW5pdGlhbGl6ZQAAAAAAAwAAAAAAAAAFYWRtaW4AAAAAAAATAAAAAAAAABF2ZXJpZmllcl9jb250cmFjdAAAAAAAABMAAAAAAAAAFWluenBla3Rvcl9pZF9jb250cmFjdAAAAAAAABMAAAAA",
        "AAAAAAAAAAAAAAANZ2V0X25mdF9vd25lcgAAAAAAAAEAAAAAAAAACHRva2VuX2lkAAAABAAAAAEAAAAT",
        "AAAAAAAAAAAAAAAOaXNfbmZ0X2V4cGlyZWQAAAAAAAEAAAAAAAAACHRva2VuX2lkAAAABAAAAAEAAAAB",
        "AAAAAAAAAAAAAAAPZ2V0X25mdF9iYWxhbmNlAAAAAAEAAAAAAAAABHVzZXIAAAATAAAAAQAAAAQ=",
        "AAAAAAAAAAAAAAAQZ2V0X25mdF9jb250cmFjdAAAAAAAAAABAAAAEw==",
        "AAAAAAAAAAAAAAAQZ2V0X25mdF9tZXRhZGF0YQAAAAAAAAABAAAD7QAAAAMAAAAQAAAAEAAAABA=",
        "AAAAAAAAAAAAAAARbWludF9pbnpwZWt0b3JfaWQAAAAAAAAEAAAAAAAAAAR1c2VyAAAAEwAAAAAAAAAKZXhwaXJlc19hdAAAAAAABgAAAAAAAAAHdmtfanNvbgAAAAAOAAAAAAAAAApwcm9vZl9ibG9iAAAAAAAOAAAAAQAAAAQ=",
        "AAAAAAAAAAAAAAASZ2V0X25mdF9leHBpcmF0aW9uAAAAAAABAAAAAAAAAAh0b2tlbl9pZAAAAAQAAAABAAAABg==",
        "AAAAAAAAAAAAAAAVZ2V0X3ZlcmlmaWVyX2NvbnRyYWN0AAAAAAAAAAAAAAEAAAAT" ]),
      options
    )
  }
  public readonly fromJSON = {
    get_admin: this.txFromJSON<string>,
        initialize: this.txFromJSON<null>,
        get_nft_owner: this.txFromJSON<string>,
        is_nft_expired: this.txFromJSON<boolean>,
        get_nft_balance: this.txFromJSON<u32>,
        get_nft_contract: this.txFromJSON<string>,
        get_nft_metadata: this.txFromJSON<readonly [string, string, string]>,
        mint_inzpektor_id: this.txFromJSON<u32>,
        get_nft_expiration: this.txFromJSON<u64>,
        get_verifier_contract: this.txFromJSON<string>
  }
}