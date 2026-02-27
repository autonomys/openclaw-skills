# openclaw-skills

OpenClaw skills that give AI agents permanent memory and on-chain identity on the Autonomys Network.

## Structure

```
autonomys/
├── auto-memory/     # Permanent storage and memory chains (primary)
├── auto-drive/      # ⚠️ Deprecated — renamed to auto-memory
└── auto-respawn/    # On-chain identity and memory anchoring
```

Each skill lives in its own directory under `autonomys/` with a `SKILL.md` that defines the skill interface, installation steps, and usage instructions.

## Skills

### auto-memory

[clawhub.ai/jim-counter/auto-memory](https://clawhub.ai/jim-counter/auto-memory)

```bash
npx clawhub install auto-memory
```

Permanent decentralized storage via the Autonomys Auto Drive API. Gives your agent:

- **Permanent file storage** — upload any file to the Autonomys Network and get back a CID. The data is distributed across the network and never expires.
- **Memory chains** — save identity, knowledge, and key decisions as a linked list where each entry points to the previous one via CID. A future instance can reconstruct who it was from a single CID.
- **Local CID tracking** — the skill maintains a local state file (`automemory-state.json`) with the latest head CID, chain length, and timestamp. This means auto-memory is fully functional on its own — no wallet, no tokens, no on-chain transactions needed.

auto-memory only needs an Auto Drive API key (free at [ai3.storage](https://ai3.storage)). It's the right starting point for any agent that wants permanent memory.

### auto-respawn

[clawhub.ai/jim-counter/auto-respawn](https://clawhub.ai/jim-counter/auto-respawn)

```bash
npx clawhub install auto-respawn
```

On-chain identity and memory anchoring on the Autonomys Network. Gives your agent:

- **Permanent identity** — a wallet with two addresses (consensus `su...` and EVM `0x...`) derived from a single recovery phrase. This is the agent's verifiable on-chain identity.
- **Token management** — check balances, transfer tokens, and bridge between the consensus layer and Auto-EVM.
- **On-chain CID anchoring** — write the latest memory chain head CID to the MemoryChain smart contract. This makes the head CID recoverable from any machine using just the agent's EVM address — no local state needed.

auto-respawn **requires auto-memory** (or equivalent) to have something worth anchoring. It completes the resurrection loop: auto-memory builds the chain, auto-respawn anchors the pointer on-chain, and a new agent instance can recover everything from just its address. The reverse dependency does not apply — auto-memory works independently with local CID tracking.

### auto-drive (deprecated)

The original name for the auto-memory skill. Preserved for backward compatibility but no longer maintained. Use `autonomys/auto-memory/` instead.

## CI

GitHub Actions runs on PRs and pushes to `main` (`.github/workflows/ci.yml`):

- **TypeScript** — type check (`tsc --noEmit`), lint (`eslint .`), and test (`vitest run`) for auto-respawn (Node 22)
- **Shell** — `shellcheck -x -S warning` on all auto-memory scripts (except `_lib.sh`, which is validated in context via `-x`)

## Publishing

Skills are published to [ClawHub](https://docs.openclaw.ai) via `.github/workflows/publish.yml`. The workflow triggers on tags matching `*/v*`.

### How to publish a release

1. **Tag the commit** using the pattern `<skill>/v<semver>`:

   ```bash
   git tag auto-memory/v0.2.0
   git tag auto-respawn/v0.1.0-beta.3
   ```

2. **Push the tag:**

   ```bash
   git push origin auto-memory/v0.2.0
   ```

3. The workflow automatically:
   - Parses the skill name and version from the tag (strips the `v` prefix — ClawHub expects bare semver like `0.2.0`, not `v0.2.0`)
   - Resolves the skill directory (`autonomys/auto-memory` or `autonomys/auto-respawn`)
   - Validates that `SKILL.md` exists in the directory
   - Authenticates with ClawHub using the `CLAWHUB_TOKEN` repository secret
   - Publishes with `npx clawhub publish` including `--tags beta`

### Supported skills

| Tag prefix | Directory | ClawHub slug | Display name |
|---|---|---|---|
| `auto-memory/v*` | `autonomys/auto-memory` | `auto-memory` | Auto Memory |
| `auto-respawn/v*` | `autonomys/auto-respawn` | `auto-respawn` | Auto Respawn |

### Requirements

- A `CLAWHUB_TOKEN` repository secret must be configured in GitHub
- The tagged commit must contain a valid `SKILL.md` in the skill's directory
