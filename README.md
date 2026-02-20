# openclaw-skills

OpenClaw skill library for AI agents, built by [Autonomys](https://autonomys.xyz). Skills are installed into your OpenClaw workspace and loaded automatically into every agent session.

## Repository Structure

Skills are organized by vendor/topic under subdirectories. Each skill lives in its own folder containing a `SKILL.md` (the agent instruction file) and any supporting scripts or references:

```
<vendor>/<skill-name>/
├── SKILL.md          # Agent instructions + OpenClaw metadata (required)
├── scripts/          # Shell scripts the agent can invoke
└── references/       # Background docs the skill may reference
```

## Available Skills

### 🧬 auto-drive — Autonomys Network Storage

**Slug:** `autonomys/auto-drive`

Permanent decentralized storage on the [Autonomys Network](https://autonomys.xyz) via [Auto-Drive](https://ai3.storage). Supports file upload/download by CID, and a linked-list memory chain for agent resurrection — a new agent instance only needs one CID to rebuild its full history.

**Requires:** `curl`, `jq`, `file`, `AUTO_DRIVE_API_KEY` ([get a free key at ai3.storage](https://ai3.storage))

| Operation | What it does |
|---|---|
| Upload | Upload any file to Auto-Drive; returns a permanent CID |
| Download | Retrieve a file by CID; decompresses if API key is set |
| Save memory | Append a structured experience to the agent's memory chain |
| Recall chain | Walk the chain from a CID to reconstruct full agent history |

→ See [`autonomys/auto-drive/SKILL.md`](autonomys/auto-drive/SKILL.md) for full docs.

## Installing Skills

Skills in this repo can be installed into OpenClaw directly from ClawHub, or manually by cloning into your skills directory.

**Via ClawHub CLI:**
```sh
npx clawhub@latest install auto-drive
```

**Manual install:**
```sh
git clone https://github.com/autonomys/openclaw-skills ~/.openclaw/skills/openclaw-skills
```
Then symlink or copy individual skill folders into `~/.openclaw/skills/`.

## Notes on Auto-Drive Data

All data uploaded to Auto-Drive is **permanent and public**. Do not upload secrets, private keys, or sensitive personal data. The free API tier includes a 20 MB/month upload limit on mainnet; downloads are unlimited.

## Contributing

New skills follow the same layout: a folder under the appropriate vendor namespace, a `SKILL.md` with valid OpenClaw frontmatter, and any scripts the skill needs. See the [OpenClaw skill spec](https://openclaw.dev) for frontmatter details.
