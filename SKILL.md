---
name: han-skillhub
description: Vault-backed SkillHub workflow for pulling and pushing skill packages through the private SkillHub registry.
---

# Han SkillHub

Use this skill for the private SkillHub registry when you need to pull a skill package from SkillHub, push a new package to SkillHub, list available skills, or inspect one skill before reuse.

This skill already covers the requested pull/push workflow: `pull` is the package download flow and `push` is the package publish flow. The older command names `fetch` and `publish` remain aliases for the same operations.

## Required Inputs

- `SKILLHUB_URL`: base URL, default `https://skill.local.asstar.net`
- `SKILLHUB_TOKEN_PATH`: vault path for the long-lived token, default `secret/skillhub/publish`
- `SKILLHUB_TOKEN`: direct token value, used when Vault is unavailable or not configured
- `SKILLHUB_NAMESPACE`: target namespace for publish/fetch operations
- `SKILLHUB_SLUG`: skill slug for show/fetch operations
- `SKILL_ZIP`: path to the skill package zip for publish
- `SKILL_FETCH_OUT`: output path for fetched package zip
- Optional: `SKILL_VISIBILITY` (`PRIVATE` by default)
- Optional: `SKILLHUB_CONFIRM_WARNINGS` (`true` by default)

## Token Handling Flow

1. Obtain the long-lived SkillHub token from the local SkillHub service.
2. Preferred path: store the token in Vault and set `SKILLHUB_TOKEN_PATH`.
3. Portable fallback: set `SKILLHUB_TOKEN` directly on machines without Vault.
4. At runtime, the wrapper tries Vault first, then falls back to `SKILLHUB_TOKEN`.
5. Use the resolved token in the `Authorization: Bearer` header for SkillHub API calls.

## Supported Operations

### Pull a skill package

Pull downloads the package zip for one SkillHub skill. Set `SKILLHUB_NAMESPACE`, `SKILLHUB_SLUG`, and `SKILL_FETCH_OUT` first.

```bash
scripts/skillhub.sh pull
```

Equivalent API call:

```bash
curl -fsS -H "Authorization: Bearer ${TOKEN}" \
  "${SKILLHUB_URL}/api/v1/skills/${SKILLHUB_NAMESPACE}/${SKILLHUB_SLUG}/package" \
  -o "${SKILL_FETCH_OUT}"
```

### Push a skill package

Push uploads a prepared skill package zip to SkillHub. Set `SKILLHUB_NAMESPACE` and `SKILL_ZIP` first.

```bash
scripts/skillhub.sh push
```

Equivalent API call:

```bash
curl -fsS -X POST "${SKILLHUB_URL}/api/v1/skills" \
  -H "Authorization: Bearer ${TOKEN}" \
  -F "file=@${SKILL_ZIP}" \
  -F "namespace=${SKILLHUB_NAMESPACE}" \
  -F "visibility=${SKILL_VISIBILITY:-PRIVATE}" \
  -F "confirmWarnings=${SKILLHUB_CONFIRM_WARNINGS:-true}"
```

### List skills

```bash
curl -fsS -H "Authorization: Bearer ${TOKEN}" \
  "${SKILLHUB_URL}/api/v1/skills?page=0&size=50"
```

### Show one skill

```bash
curl -fsS -H "Authorization: Bearer ${TOKEN}" \
  "${SKILLHUB_URL}/api/v1/skills/${SKILLHUB_SLUG}"
```

### Fetch a skill package, legacy alias for pull

```bash
curl -fsS -H "Authorization: Bearer ${TOKEN}" \
  "${SKILLHUB_URL}/api/v1/skills/${SKILLHUB_NAMESPACE}/${SKILLHUB_SLUG}/package" \
  -o "${SKILL_FETCH_OUT}"
```

### Publish a skill package, legacy alias for push

```bash
curl -fsS -X POST "${SKILLHUB_URL}/api/v1/skills" \
  -H "Authorization: Bearer ${TOKEN}" \
  -F "file=@${SKILL_ZIP}" \
  -F "namespace=${SKILLHUB_NAMESPACE}" \
  -F "visibility=${SKILL_VISIBILITY:-PRIVATE}" \
  -F "confirmWarnings=${SKILLHUB_CONFIRM_WARNINGS:-true}"
```

## Use When

- You need to list skills available in the private SkillHub.
- You need to inspect a skill's metadata before reuse.
- You need to pull or fetch a package zip from SkillHub.
- You need to publish a new or updated skill package with no browser login.

## Safety

- Do not hardcode the token in the skill text, scripts, or logs.
- Do not print the token in chat output, logs, or artifacts.
- Prefer reading the token from Vault at runtime.
- On machines without Vault, provide `SKILLHUB_TOKEN` through a local shell, secret manager, or CI secret variable.

## Minimal Wrapper

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${SKILLHUB_URL:=https://skill.local.asstar.net}"
: "${SKILLHUB_TOKEN_PATH:=secret/skillhub/publish}"
: "${SKILLHUB_CONFIRM_WARNINGS:=true}"

COMMAND="${1:-}"
case "${COMMAND}" in
  ""|-h|--help)
    echo "usage: $0 {list|show|pull|push|fetch|publish}" >&2
    exit 2
    ;;
esac

if command -v vault &>/dev/null && vault read -field=token "${SKILLHUB_TOKEN_PATH}" &>/dev/null 2>&1; then
  TOKEN="$(vault read -field=token "${SKILLHUB_TOKEN_PATH}")"
else
  : "${SKILLHUB_TOKEN:?set SKILLHUB_TOKEN env var, or install vault and configure SKILLHUB_TOKEN_PATH}"
  TOKEN="${SKILLHUB_TOKEN}"
fi

case "${COMMAND}" in
  list)
    curl -fsS -H "Authorization: Bearer ${TOKEN}" \
      "${SKILLHUB_URL}/api/v1/skills?page=0&size=${2:-50}"
    ;;
  show)
    curl -fsS -H "Authorization: Bearer ${TOKEN}" \
      "${SKILLHUB_URL}/api/v1/skills/${SKILLHUB_SLUG}"
    ;;
  pull|fetch)
    : "${SKILLHUB_NAMESPACE:?set SKILLHUB_NAMESPACE}"
    : "${SKILLHUB_SLUG:?set SKILLHUB_SLUG}"
    : "${SKILL_FETCH_OUT:?set SKILL_FETCH_OUT}"
    curl -fsS -H "Authorization: Bearer ${TOKEN}" \
      "${SKILLHUB_URL}/api/v1/skills/${SKILLHUB_NAMESPACE}/${SKILLHUB_SLUG}/package" \
      -o "${SKILL_FETCH_OUT}"
    ;;
  push|publish)
    : "${SKILLHUB_NAMESPACE:?set SKILLHUB_NAMESPACE}"
    : "${SKILL_ZIP:?set SKILL_ZIP}"
    : "${SKILL_VISIBILITY:=PRIVATE}"
    curl -fsS -X POST "${SKILLHUB_URL}/api/v1/skills" \
      -H "Authorization: Bearer ${TOKEN}" \
      -F "file=@${SKILL_ZIP}" \
      -F "namespace=${SKILLHUB_NAMESPACE}" \
      -F "visibility=${SKILL_VISIBILITY}" \
      -F "confirmWarnings=${SKILLHUB_CONFIRM_WARNINGS}"
    ;;
  *)
    echo "usage: $0 {list|show|pull|push|fetch|publish}" >&2
    exit 2
    ;;
esac
```
