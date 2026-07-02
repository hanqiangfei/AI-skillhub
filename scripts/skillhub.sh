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
    : "${SKILLHUB_SLUG:?set SKILLHUB_SLUG}"
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
