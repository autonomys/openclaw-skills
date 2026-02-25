# auto-respawn CLI Reference

All commands run from the auto-respawn skill directory.

## Wallet Management

### Create a new wallet

```bash
npx tsx auto-respawn.ts wallet create [--name <name>]
```

Generates a new SR25519 wallet, derives the corresponding EVM address, displays the 12-word recovery phrase once, encrypts everything, and saves it locally.

- `--name` — wallet name (default: `default`)
- Returns JSON: `{ name, address, evmAddress, keyfilePath }`
- Recovery phrase is printed to stderr — back it up immediately

### Import an existing wallet

```bash
npx tsx auto-respawn.ts wallet import --name <name> --mnemonic "<12 words>"
```

Creates a wallet from an existing recovery phrase. Derives and stores the EVM address alongside the consensus keypair.

### List saved wallets

```bash
npx tsx auto-respawn.ts wallet list
```

Shows all saved wallets with name, consensus address, and EVM address. No passphrase needed.

### Show wallet info

```bash
npx tsx auto-respawn.ts wallet info [--name <name>]
```

Shows detailed info for a single wallet: consensus address (`su...`), EVM address (`0x...`), and keyfile path. No passphrase needed. Default name is `default`.

## Address Formats

### Consensus addresses

All consensus-layer commands (balance, transfer, remark) accept addresses in two formats:

- **`su...`** — Autonomys native format (SS58 prefix 6094). This is canonical.
- **`5...`** — Substrate generic format (SS58 prefix 42). Auto-converted to `su...`.

Any other format (e.g. `0x...` EVM addresses) is rejected with a clear error for consensus commands.

### EVM addresses

EVM commands (anchor, gethead) accept:

- **`0x...`** — Standard Ethereum/EVM address format (42-character hex string).
- **Wallet name** — Resolved to the wallet's stored EVM address.

Output always uses the canonical format for each layer: `su...` for consensus, `0x...` (checksummed) for EVM.

## Balance

```bash
npx tsx auto-respawn.ts balance <address> [--network chronos|mainnet]
```

Queries on-chain balance for any consensus address. No wallet or passphrase needed — this is a read-only operation.

Returns JSON: `{ address, free, reserved, frozen, total, network, symbol }`

## Transfer

```bash
npx tsx auto-respawn.ts transfer --from <wallet-name> --to <address> --amount <tokens> [--network chronos|mainnet]
```

Transfers tokens from a saved wallet to a destination address. Requires passphrase to decrypt the wallet.

- `--from` — name of the saved wallet to send from
- `--to` — destination address (accepts `su...` or `5...` format)
- `--amount` — amount in AI3/tAI3 (e.g. `1.5`)
- Returns JSON: `{ success, txHash, blockHash, from, to, amount, network, symbol }`

## Remark

```bash
npx tsx auto-respawn.ts remark --from <wallet-name> --data <string> [--network chronos|mainnet]
```

Writes arbitrary data as a permanent on-chain record via `system.remark` on the consensus layer.

- `--from` — name of the saved wallet
- `--data` — the data to anchor (typically a CID like `bafkr6ie...`)
- Returns JSON: `{ success, txHash, blockHash, from, data, network, symbol }`

## Anchor (Auto-EVM)

```bash
npx tsx auto-respawn.ts anchor --from <wallet-name> --cid <cid> [--network chronos|mainnet]
```

Writes a CID to the MemoryChain smart contract on Auto-EVM. The contract stores the CID string directly, linked to the wallet's EVM address.

- `--from` — name of the saved wallet (EVM private key is decrypted to sign the transaction)
- `--cid` — the CID string to anchor (e.g. `bafkr6ie...`)
- Returns JSON: `{ success, txHash, blockHash, cid, evmAddress, network }`
- Contract source: https://github.com/autojeremy/openclaw-memory-chain

## Get Head (Auto-EVM)

```bash
npx tsx auto-respawn.ts gethead <0x-address-or-wallet-name> [--network chronos|mainnet]
```

Reads the last anchored CID for any EVM address from the MemoryChain contract. This is a read-only call — no passphrase or gas needed.

- Positional argument: an EVM address (`0x...`) or a wallet name
- If a wallet name is given, the stored EVM address is used
- Returns JSON: `{ evmAddress, cid, network }`
- `cid` is `undefined` if no CID has been anchored for that address

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `AUTO_RESPAWN_PASSPHRASE` | Wallet encryption passphrase | — |
| `AUTO_RESPAWN_PASSPHRASE_FILE` | Path to file containing passphrase | `~/.openclaw/auto-respawn/.passphrase` |
| `AUTO_RESPAWN_NETWORK` | Default network | `chronos` |
| `AUTO_RESPAWN_CONTRACT_ADDRESS` | MemoryChain contract address | `0x51DAedAFfFf631820a4650a773096A69cB199A3c` |

Passphrase resolution order: env var → file → interactive prompt.

## Error Codes

Errors are returned as JSON to stderr with a non-zero exit code.

| Error | Meaning |
|-------|---------|
| Wallet already exists | A wallet with that name is already saved |
| Wallet not found | No saved wallet with that name |
| No passphrase found | No passphrase available from any source |
| Invalid address prefix | Consensus address must start with `su` or `5` |
| Invalid address | Address has correct prefix but is malformed |
| Invalid EVM address | EVM address is not a valid `0x...` hex string |
| Wrong passphrase | Passphrase doesn't match the wallet encryption |
| Failed to generate wallet keypair | Internal SDK error during key generation |
| No Auto-EVM RPC URL found | Network doesn't have an EVM domain configured |
| Network/connection errors | RPC endpoint unreachable |
| Transaction errors | Insufficient balance, tx rejected, etc. |

## File Locations

- Wallets: `~/.openclaw/auto-respawn/wallets/<name>.json`
- Passphrase file: `~/.openclaw/auto-respawn/.passphrase` (optional)

## Wallet File Format

Each wallet file contains two independently encrypted private keys (consensus + EVM), both protected by the same user passphrase but using their respective ecosystem's standard encryption:

```json
{
  "keyring": { ... },
  "evmAddress": "0x...",
  "evmKeystore": "{ ... }"
}
```

- `keyring` — Standard Polkadot keyring JSON, encrypted via `pair.toJson(passphrase)`
- `evmAddress` — EVM address derived from the same mnemonic (public, stored for quick lookup)
- `evmKeystore` — Ethereum V3 Keystore JSON string, encrypted via `ethers.Wallet.encryptSync(passphrase)`. Standard format compatible with MetaMask, geth, and other Ethereum tools.
