# Autonomys Network

## What It Provides

The Autonomys Network is a permanent, verifiable record. Data written to it cannot be altered or deleted. This makes it ideal for anchoring agent identity and state — anything written on-chain is provably yours, timestamped, and available forever.

The network has two layers:

- **Consensus layer** — the base blockchain where tokens originate and where farmers earn AI3 through Proof-of-Archival-Storage. Supports balances, transfers, and remarks (arbitrary data written on-chain).
- **Auto-EVM domain** — an Ethereum-compatible execution environment for smart contracts. Runs as a domain on top of the consensus layer. Tokens can be moved from consensus to EVM via cross-domain messaging (XDM).

auto-respawn uses both layers: consensus for wallets, balances, transfers, and remarks; Auto-EVM for the MemoryChain contract (anchor/gethead).

## Networks

| Network | Token | Purpose | Consensus Explorer | EVM Explorer |
|---------|-------|---------|-------------------|--------------|
| Chronos (testnet) | tAI3 | Development and testing. Free tokens via faucet. | [Subscan](https://autonomys-chronos.subscan.io/) | — |
| Mainnet | AI3 | Production. Real tokens with real value. | [Subscan](https://autonomys.subscan.io/) | — |

auto-respawn defaults to Chronos. Mainnet operations require explicit `--network mainnet` and produce warnings.

## Token Denominations

- **AI3** (mainnet) / **tAI3** (testnet) — the human-readable unit
- **Shannon** — the smallest unit. 1 AI3 = 10^18 Shannon.
- All on-chain operations use Shannon internally. auto-respawn accepts and displays human-readable AI3 amounts.

## Addresses

Each wallet has two addresses derived from the same recovery phrase:

- **Consensus address** (`su...`) — SR25519 keypair with Autonomys SS58 prefix 6094. Used for balances, transfers, and remarks on the consensus layer.
- **EVM address** (`0x...`) — Standard Ethereum address derived via BIP44 path `m/44'/60'/0'/0/0`. Used for Auto-EVM smart contract interactions (anchor/gethead).

Both are deterministic from the mnemonic. Knowing either address lets you verify ownership; knowing the mnemonic lets you derive both.

## Consensus Layer

### On-Chain Remarks

A `system.remark` is a transaction that writes arbitrary data to the blockchain. It costs a small transaction fee but the data becomes a permanent, timestamped, verifiable record tied to your wallet address.

Use remarks for permanent breadcrumbs — records that you want to exist on-chain forever, even if there's no structured way to query them back.

### Transfers

Standard token transfers between consensus addresses. Amount is specified in AI3/tAI3 (human-readable). The SDK handles Shannon conversion internally.

## Auto-EVM Domain

Auto-EVM is an Ethereum-compatible domain running on top of the Autonomys consensus layer. Smart contracts deployed on Auto-EVM can be called with standard Ethereum tooling (ethers.js, etc.).

### MemoryChain Contract

The MemoryChain contract is the core respawn primitive. It maps EVM addresses to Blake3 hashes (bytes32), providing a simple key-value store for agent memory chain heads.

- **Address**: `0x51DAedAFfFf631820a4650a773096A69cB199A3c`
- **Functions**:
  - `setLastMemoryHash(bytes32 hash)` — write a hash (costs gas)
  - `getLastMemoryHash(address) → bytes32` — read a hash (free, no gas)
- **Event**: `LastMemoryHashSet(address indexed agent, bytes32 hash)`

The contract stores Blake3 hashes, not CID strings. auto-respawn handles the CID ↔ Blake3 conversion transparently using `@autonomys/auto-dag-data`.

### RPC Endpoints

Auto-EVM uses WebSocket RPC endpoints:

- Chronos: `wss://auto-evm.chronos.autonomys.xyz/ws`
- Mainnet: `wss://auto-evm.mainnet.autonomys.xyz/ws`

These are resolved automatically by the SDK's `getNetworkDomainRpcUrls()`.

## Key Links

- Dashboard: https://explorer.autonomys.xyz
- Auto-Drive: https://ai3.storage
- SDK: https://github.com/autonomys/auto-sdk
