# auto-respawn CLI Reference

All commands run from the auto-respawn skill directory.

## Wallet Management

### Create a new wallet

```bash
npx tsx auto-respawn.ts wallet create [--name <name>]
```

Generates a new SR25519 wallet, displays the 12-word recovery phrase once, encrypts the keypair, and saves it locally.

- `--name` — wallet name (default: `default`)
- Returns JSON: `{ name, address, keyfilePath }`
- Recovery phrase is printed to stderr — back it up immediately

### Import an existing wallet

```bash
npx tsx auto-respawn.ts wallet import --name <name> --mnemonic "<12 words>"
```

Creates a wallet from an existing recovery phrase. Same encryption and storage as create.

### List saved wallets

```bash
npx tsx auto-respawn.ts wallet list
```

Shows all saved wallets with name and address. No passphrase needed.

## Address Formats

All commands accept addresses in two formats:

- **`su...`** — Autonomys native format (SS58 prefix 6094). This is canonical.
- **`5...`** — Substrate generic format (SS58 prefix 42). Auto-converted to `su...`.

Any other format (e.g. `0x...` EVM addresses) is rejected with a clear error. Output always uses the canonical `su...` format.

## Balance

```bash
npx tsx auto-respawn.ts balance <address> [--network chronos|mainnet]
```

Queries on-chain balance for any address. No wallet or passphrase needed — this is a read-only operation.

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

Writes arbitrary data as a permanent on-chain record via `system.remark`. This is the CID anchoring primitive — use it to write a memory chain head CID to the blockchain.

- `--from` — name of the saved wallet
- `--data` — the data to anchor (typically a CID like `bafkr6ie...`)
- Returns JSON: `{ success, txHash, blockHash, from, data, network, symbol }`

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `AUTO_RESPAWN_PASSPHRASE` | Wallet encryption passphrase | — |
| `AUTO_RESPAWN_PASSPHRASE_FILE` | Path to file containing passphrase | `~/.openclaw/auto-respawn/.passphrase` |
| `AUTO_RESPAWN_NETWORK` | Default network | `chronos` |

Passphrase resolution order: env var → file → interactive prompt.

## Error Codes

Errors are returned as JSON to stderr with a non-zero exit code.

| Error | Meaning |
|-------|---------|
| Wallet already exists | A wallet with that name is already saved |
| Wallet not found | No saved wallet with that name |
| No passphrase found | No passphrase available from any source |
| Invalid address prefix | Address must start with `su` or `5` |
| Invalid address | Address has correct prefix but is malformed |
| Wrong passphrase | Passphrase doesn't match the wallet encryption |
| Failed to generate wallet keypair | Internal SDK error during key generation |
| Network/connection errors | RPC endpoint unreachable |
| Transaction errors | Insufficient balance, tx rejected, etc. |

## File Locations

- Wallets: `~/.openclaw/auto-respawn/wallets/<name>.json`
- Passphrase file: `~/.openclaw/auto-respawn/.passphrase` (optional)
