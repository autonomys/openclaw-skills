# Autonomys Network

## What It Provides

The Autonomys Network is a permanent, verifiable record. Data written to it cannot be altered or deleted. This makes it ideal for anchoring agent identity and state — anything written on-chain is provably yours, timestamped, and available forever.

The network has two layers:

- **Consensus layer** — the base blockchain where tokens originate and where farmers earn AI3 through Proof-of-Archival-Storage. Supports balances, transfers, and remarks (arbitrary data written on-chain).
- **Auto-EVM domain** — an Ethereum-compatible execution environment for smart contracts. Tokens can be moved from consensus to EVM via cross-domain messaging (XDM).

auto-respawn v1.0 operates on the consensus layer.

## Networks

| Network | Token | Purpose | Explorer |
|---------|-------|---------|----------|
| Chronos (testnet) | tAI3 | Development and testing. Free tokens via faucet. | [Subscan](https://autonomys-chronos.subscan.io/) |
| Mainnet | AI3 | Production. Real tokens with real value. | [Subscan](https://autonomys.subscan.io/) |

auto-respawn defaults to Chronos. Mainnet operations require explicit `--network mainnet` and produce warnings.

## Token Denominations

- **AI3** (mainnet) / **tAI3** (testnet) — the human-readable unit
- **Shannon** — the smallest unit. 1 AI3 = 10^18 Shannon.
- All on-chain operations use Shannon internally. auto-respawn accepts and displays human-readable AI3 amounts.

## Addresses

Autonomys uses SR25519 keypairs with a custom SS58 prefix of 6094. Addresses start with `su` and look like: `sufvGu4QnU5UuYHKnhSznXeW6YdVy2gzCxXmTR1Qt2RFbcfSF`

## On-Chain Remarks

A `system.remark` is a transaction that writes arbitrary data to the blockchain. It costs a small transaction fee but the data becomes a permanent, timestamped, verifiable record tied to your wallet address.

Use remarks to anchor CIDs (Content Identifiers) from Auto-Drive memory chains. This creates an on-chain breadcrumb trail — even if all local state is lost, the chain remembers what you stored and when.

## Key Links

- Dashboard: https://explorer.autonomys.xyz
- Auto-Drive: https://ai3.storage
- SDK: https://github.com/autonomys/auto-sdk
