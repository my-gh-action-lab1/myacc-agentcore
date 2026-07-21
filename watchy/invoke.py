#!/usr/bin/env python3
"""Invoke the watchy AgentCore runtime with a prompt.

Usage:
    python invoke.py "What is the capital of Japan?"
    python invoke.py "..." --session-id my-existing-session-id-1234567890123
    python invoke.py "..." --arn arn:aws:bedrock-agentcore:eu-west-1:123456789012:runtime/myacc_watchy_agent-abc123
"""

import argparse
import json
import uuid

import boto3


def resolve_arn(control_client, runtime_name: str) -> str:
    paginator = control_client.get_paginator("list_agent_runtimes")
    for page in paginator.paginate():
        for runtime in page.get("agentRuntimes", []):
            if runtime.get("agentRuntimeName") == runtime_name:
                return runtime["agentRuntimeArn"]
    raise SystemExit(f"ERROR: no agent runtime found named '{runtime_name}'")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("prompt", help="Prompt to send to the agent")
    parser.add_argument("--arn", default=None, help="Agent runtime ARN (skips lookup)")
    parser.add_argument("--runtime-name", default="myacc_watchy_agent")
    parser.add_argument("--session-id", default=None, help="Reuse an existing session id (must be 33-256 chars)")
    parser.add_argument("--region", default="eu-west-1")
    args = parser.parse_args()

    session_id = args.session_id or str(uuid.uuid4())

    data_client = boto3.client("bedrock-agentcore", region_name=args.region)

    arn = args.arn
    if not arn:
        control_client = boto3.client("bedrock-agentcore-control", region_name=args.region)
        arn = resolve_arn(control_client, args.runtime_name)

    print(f"Invoking {arn} (session={session_id})...")

    response = data_client.invoke_agent_runtime(
        agentRuntimeArn=arn,
        runtimeSessionId=session_id,
        payload=json.dumps({"prompt": args.prompt}).encode("utf-8"),
        contentType="application/json",
        accept="application/json",
    )

    body = response["response"].read()
    try:
        print(json.dumps(json.loads(body), indent=2))
    except json.JSONDecodeError:
        print(body.decode(errors="replace"))


if __name__ == "__main__":
    main()
