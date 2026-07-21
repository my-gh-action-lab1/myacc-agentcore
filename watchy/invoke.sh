#!/usr/bin/env bash
# Invoke the watchy AgentCore runtime with a prompt.
#
# Usage:
#   ./invoke.sh "What is the capital of Japan?"
#   ./invoke.sh "..." --session-id my-existing-session-id-1234567890123
#   AGENT_RUNTIME_ARN=arn:... ./invoke.sh "..."

set -euo pipefail

REGION="${AWS_REGION:-eu-west-1}"
RUNTIME_NAME="${AGENT_RUNTIME_NAME:-myacc_watchy_agent}"
ARN="${AGENT_RUNTIME_ARN:-}"
SESSION_ID=""
PROMPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arn) ARN="$2"; shift 2 ;;
    --session-id) SESSION_ID="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    *)
      if [[ -z "$PROMPT" ]]; then PROMPT="$1"; else PROMPT="$PROMPT $1"; fi
      shift
      ;;
  esac
done

if [[ -z "$PROMPT" ]]; then
  echo "Usage: $0 \"<prompt>\" [--session-id <id>] [--arn <agent-runtime-arn>] [--region <region>]" >&2
  exit 1
fi

if [[ -z "$ARN" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if command -v terraform >/dev/null 2>&1 && [[ -d "$SCRIPT_DIR/.terraform" ]]; then
    ARN=$(terraform -chdir="$SCRIPT_DIR" output -raw agent_runtime_arn 2>/dev/null || true)
  fi
fi

if [[ -z "$ARN" ]]; then
  echo "No ARN supplied/found via terraform state; looking up by name '$RUNTIME_NAME' in $REGION..." >&2
  ARN=$(aws bedrock-agentcore-control list-agent-runtimes --region "$REGION" \
    --query "agentRuntimes[?agentRuntimeName=='${RUNTIME_NAME}'].agentRuntimeArn | [0]" \
    --output text)
fi

if [[ -z "$ARN" || "$ARN" == "None" ]]; then
  echo "ERROR: could not resolve the agent runtime ARN. Pass --arn explicitly." >&2
  exit 1
fi

if [[ -z "$SESSION_ID" ]]; then
  if command -v uuidgen >/dev/null 2>&1; then
    SESSION_ID=$(uuidgen)
  else
    SESSION_ID=$(python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null \
      || python -c "import uuid; print(uuid.uuid4())")
  fi
fi

PAYLOAD=$(printf '{"prompt": %s}' "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$PROMPT" 2>/dev/null \
  || python -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$PROMPT")")

OUT_FILE="$(mktemp)"

echo "Invoking $ARN (region=$REGION, session=$SESSION_ID)..." >&2

aws bedrock-agentcore invoke-agent-runtime \
  --region "$REGION" \
  --cli-binary-format raw-in-base64-out \
  --agent-runtime-arn "$ARN" \
  --runtime-session-id "$SESSION_ID" \
  --content-type application/json \
  --accept application/json \
  --payload "$PAYLOAD" \
  "$OUT_FILE" >/dev/null

if command -v jq >/dev/null 2>&1; then
  jq . "$OUT_FILE"
else
  cat "$OUT_FILE"
fi
rm -f "$OUT_FILE"
