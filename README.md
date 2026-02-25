# openclaw-skills

OpenClaw skills that give AI agents permanent memory and on-chain identity on the Autonomys Network.

## Structure

```
autonomys/
├── auto-drive/      # Permanent storage and memory chains
└── auto-respawn/    # On-chain identity and memory anchoring
```

Each skill lives in its own directory under `autonomys/` with a `SKILL.md` that defines the skill interface, installation steps, and usage instructions.

## Skills

### auto-drive

Permanent decentralized storage via the Autonomys Auto-Drive API. Upload and download files by CID, and save agent memories as a linked-list chain — each entry pointing to the previous one — so an agent's full history can be reconstructed from a single CID.

### auto-respawn

On-chain identity and memory anchoring on the Autonomys Network. Create wallets (consensus + EVM), manage balances, bridge tokens between layers, and write memory chain CIDs to the MemoryChain smart contract. Combined with auto-drive, this completes the resurrection loop: an agent can lose all local state and recover its entire memory from just its on-chain address.
