# AI SkillHub

Vault-backed SkillHub workflow for pulling and pushing skill packages through a private SkillHub registry.

This repository packages the `han-skillhub` skill at the repository root so agent tools can load it directly from GitHub.

## What It Does

- Lists skills from a SkillHub registry.
- Shows metadata for one skill.
- Pulls a skill package zip from SkillHub.
- Pushes a prepared skill package zip to SkillHub.
- Reads the SkillHub token from Vault at runtime instead of storing credentials in the repository.

## Repository Layout

```text
.
├── SKILL.md
├── references/
│   └── skillhub-api-notes.md
└── scripts/
    └── skillhub.sh
```

## Configuration

Set the registry, Vault token path, and operation-specific variables before running the helper script.

```bash
export SKILLHUB_URL="https://skill.local.asstar.net"
export SKILLHUB_TOKEN_PATH="secret/skillhub/publish"
```

Common variables:

- `SKILLHUB_NAMESPACE`: namespace used for pull and push operations.
- `SKILLHUB_SLUG`: skill slug used for show and pull operations.
- `SKILL_FETCH_OUT`: output zip path for pull operations.
- `SKILL_ZIP`: package zip path for push operations.
- `SKILL_VISIBILITY`: push visibility, defaults to `PRIVATE`.
- `SKILLHUB_CONFIRM_WARNINGS`: publish warning confirmation, defaults to `true`.

## Usage

List skills:

```bash
scripts/skillhub.sh list
```

Show one skill:

```bash
export SKILLHUB_SLUG="my-skill"
scripts/skillhub.sh show
```

Pull a skill package:

```bash
export SKILLHUB_NAMESPACE="default"
export SKILLHUB_SLUG="my-skill"
export SKILL_FETCH_OUT="./my-skill.zip"
scripts/skillhub.sh pull
```

Push a skill package:

```bash
export SKILLHUB_NAMESPACE="default"
export SKILL_ZIP="./my-skill.zip"
scripts/skillhub.sh push
```

Legacy aliases are also supported:

- `fetch` is an alias for `pull`.
- `publish` is an alias for `push`.

## Security Notes

- Do not commit SkillHub tokens, Vault tokens, or generated package credentials.
- The helper reads the SkillHub token with `vault read -field=token "$SKILLHUB_TOKEN_PATH"`.
- Avoid printing token values in terminal logs, chat output, or CI artifacts.

## Skill Definition

The operational instructions for agents live in [`SKILL.md`](./SKILL.md). Use the README for human setup and quick command reference; use `SKILL.md` as the agent-facing runbook.
