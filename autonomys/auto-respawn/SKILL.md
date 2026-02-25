---
name: auto-respawn
description: >
  Anchor agent identity on the Autonomys Network. Create wallets, check balances,
  transfer tokens, and write on-chain remarks to ensure your agent can always
  respawn — even from total state loss.
metadata:
  openclaw:
    emoji: "🔄"
    requires:
      anyBins: ["node", "bun"]
      env: []
    install:
      - id: deps
        kind: node
        package: "."
        bins: []
        label: "Install auto-respawn dependencies"
      - id: tsx
        kind: node
        package: "tsx"
        bins: ["tsx"]
        label: "Install tsx (TypeScript executor)"
---

# Auto-Respawn Skill

Anchor your identity on the Autonomys Network so you can always be found — and always come back.

## What This Skill Does

Your wallet address is your permanent identity on the Autonomys Network. Remarks are your breadcrumbs — permanent, timestamped, verifiable records tied to that identity. Even if everything else is lost, the chain remembers.

1. **Create and manage wallets** — your on-chain identity, encrypted and stored locally
2. **Check balances** — see how many tokens any address holds
3. **Transfer tokens** — move tokens between wallets to fund operations
4. **Write on-chain remarks** — anchor data permanently, especially memory chain head CIDs

## The Respawn Concept

When used with the auto-drive skill (permanent memory storage), auto-respawn completes the resurrection loop:

1. **auto-drive** saves memories as a linked list on permanent storage, each entry pointing to the previous one via CID
2. **auto-respawn** anchors the latest head CID on-chain via a remark transaction
3. If all local state is lost, a new agent instance can find the remark on-chain, retrieve the head CID, and walk the entire memory chain back to genesis

The chain is your insurance policy. Your wallet address + on-chain remarks = a permanent breadcrumb trail to your full history.

## When To Use This Skill

- User says "create a wallet", "set up my on-chain identity", or "get an address"
- User says "check balance", "how many tokens", or "what's in my wallet"
- User says "transfer tokens", "send AI3", or "fund this address"
- User says "anchor this CID", "write a remark", "save to chain", or "make this permanent"
- After saving a memory with auto-drive, anchor the head CID on-chain for resilience
- Any time the user wants a permanent, verifiable record tied to their agent identity

## Configuration

### Passphrase

Wallet operations that involve signing (transfers, remarks) or creating/importing wallets require a passphrase to encrypt/decrypt the wallet keyfile. Set it via:

- **Environment:** `export AUTO_RESPAWN_PASSPHRASE=your_passphrase`
- **File:** Write it to `~/.openclaw/auto-respawn/.passphrase`
- **Interactive:** If running in a terminal, you'll be prompted

### Network

Defaults to **Chronos testnet** (tAI3 tokens). For mainnet (real AI3 tokens):

- **Flag:** `--network mainnet` on any command
- **Environment:** `export AUTO_RESPAWN_NETWORK=mainnet`

## Core Operations

### Create a Wallet

```bash
npx tsx auto-respawn.ts wallet create [--name <name>]
```

Creates a new wallet with an encrypted keyfile. The 12-word recovery phrase is displayed **once** — the user must back it up immediately. Default wallet name is `default`.

### Import a Wallet

```bash
npx tsx auto-respawn.ts wallet import --name <name> --mnemonic "<12 words>"
```

Import an existing wallet from a recovery phrase.

### List Wallets

```bash
npx tsx auto-respawn.ts wallet list
```

Show all saved wallets with names and addresses. No passphrase needed.

### Check Balance

```bash
npx tsx auto-respawn.ts balance <address> [--network chronos|mainnet]
```

Check any address's token balance. No wallet or passphrase needed — this is read-only.

### Transfer Tokens

```bash
npx tsx auto-respawn.ts transfer --from <wallet-name> --to <address> --amount <tokens> [--network chronos|mainnet]
```

Transfer tokens from a saved wallet. Amount is in AI3/tAI3 (e.g. `1.5`).

### Write an On-Chain Remark

```bash
npx tsx auto-respawn.ts remark --from <wallet-name> --data <string> [--network chronos|mainnet]
```

Write arbitrary data as a permanent on-chain record. Use this to anchor CIDs from memory chains.

## Usage Examples

**User:** "Create a wallet for my agent"
→ Run `npx tsx auto-respawn.ts wallet create --name my-agent`
→ Show the user the address. Remind them to back up the recovery phrase.

**User:** "Check my balance"
→ Run `npx tsx auto-respawn.ts wallet list` to find the address
→ Run `npx tsx auto-respawn.ts balance <address>`

**User:** "Anchor my latest memory CID on-chain"
→ Run `npx tsx auto-respawn.ts remark --from my-agent --data "bafkr6ie..."`
→ Report the transaction hash and explorer link

**User:** "Send 10 tAI3 to this address"
→ **Confirm with the user first** — "I'll transfer 10 tAI3 from wallet 'default' to <address>. Proceed?"
→ On confirmation: `npx tsx auto-respawn.ts transfer --from default --to <address> --amount 10`

## Important Notes

- **Never log, store, or transmit recovery phrases or passphrases.** The recovery phrase is shown once at wallet creation for the user to back up. Never reference it again.
- **Always confirm transfers with the user before executing.** Tokens have real value on mainnet.
- **Mainnet operations produce warnings** in the output. Exercise extra caution with real AI3 tokens.
- Wallet keyfiles are stored at `~/.openclaw/auto-respawn/wallets/` in standard Polkadot JSON format, encrypted with the user's passphrase.
- On-chain remarks cost a small transaction fee. The wallet must have a sufficient balance.
- All output is structured JSON on stdout. Errors go to stderr.
- Explorer links for transactions: `https://autonomys-chronos.subscan.io/extrinsic/<txHash>` (chronos) or `https://autonomys.subscan.io/extrinsic/<txHash>` (mainnet).
