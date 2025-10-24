#!/usr/bin/env python3
"""Minimal contract-enforcing runner.

Usage:
  python3 bin/contract_runner.py --contract contract.json --script ./myscript.sh -- [script-args]

Features implemented:
- load contract JSON and apply settings
- verify optional script_sha256
- enforce timeout_seconds
- enforce max_output_bytes for combined stdout+stderr
- inject contract.env into child's environment
- return structured JSON with exit code, timings and truncated outputs (base64)

Notes:
- This runner implements pragmatic, user-space enforcement. It does not create a full OS sandbox.
- For strict network isolation, run inside a container or use tools like firejail/unshare externally.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import shlex
import signal
import subprocess
import sys
import tempfile
import threading
import time
from typing import Dict, Optional


def load_contract(path: str) -> Dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def sha256_of_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


class OutputCollector:
    def __init__(self, max_bytes: int):
        self.max_bytes = max_bytes
        self.lock = threading.Lock()
        self.data = bytearray()
        self.truncated = False

    def feed(self, chunk: bytes):
        with self.lock:
            remaining = self.max_bytes - len(self.data)
            if remaining <= 0:
                self.truncated = True
                return
            if len(chunk) <= remaining:
                self.data.extend(chunk)
            else:
                self.data.extend(chunk[:remaining])
                self.truncated = True

    def get_bytes(self) -> bytes:
        with self.lock:
            return bytes(self.data)


def stream_reader(pipe, collector: OutputCollector):
    try:
        while True:
            chunk = pipe.read(1024)
            if not chunk:
                break
            collector.feed(chunk)
            # If collector is full, continue reading but don't store beyond limit
    except Exception:
        pass


def run_with_contract(contract: Dict, script: str, script_args: list) -> Dict:
    timeout = int(contract.get("resources", {}).get("timeout_seconds", 300))
    max_output = int(contract.get("resources", {}).get("max_output_bytes", 10 * 1024 * 1024))

    # integrity check
    expected_sha = contract.get("integrity", {}).get("script_sha256")
    if expected_sha:
        actual = sha256_of_file(script)
        if actual.lower() != expected_sha.lower():
            return {
                "ok": False,
                "error": "script_sha256_mismatch",
                "expected": expected_sha,
                "actual": actual,
            }

    # Prepare environment for child
    child_env = os.environ.copy()
    for k, v in contract.get("env", {}).items():
        child_env[k] = str(v)

    # If network is disallowed, set an env hint
    if isinstance(contract.get("network"), dict) and not contract["network"].get("allowed", True):
        child_env.setdefault("ALLOW_NETWORK", "0")

    cmd = [script] + script_args

    collector = OutputCollector(max_output)
    collector_err = OutputCollector(max_output)

    start = time.time()
    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=child_env,
        )
    except FileNotFoundError as e:
        return {"ok": False, "error": "script_not_found", "detail": str(e)}

    threads = []
    if proc.stdout:
        t = threading.Thread(target=stream_reader, args=(proc.stdout, collector), daemon=True)
        t.start()
        threads.append(t)
    if proc.stderr:
        t2 = threading.Thread(target=stream_reader, args=(proc.stderr, collector_err), daemon=True)
        t2.start()
        threads.append(t2)

    timed_out = False
    try:
        proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        try:
            proc.kill()
        except Exception:
            pass

    # Allow reader threads to drain
    for t in threads:
        t.join(timeout=1)

    end = time.time()

    out_bytes = collector.get_bytes()
    err_bytes = collector_err.get_bytes()

    combined_len = len(out_bytes) + len(err_bytes)
    output_truncated = collector.truncated or collector_err.truncated or (combined_len >= max_output)

    result = {
        "ok": not timed_out and proc.returncode == 0,
        "exit_code": proc.returncode,
        "timed_out": timed_out,
        "duration_seconds": end - start,
        "stdout_b64": base64.b64encode(out_bytes).decode("ascii"),
        "stderr_b64": base64.b64encode(err_bytes).decode("ascii"),
        "stdout_truncated": collector.truncated,
        "stderr_truncated": collector_err.truncated,
        "combined_output_bytes": combined_len,
    }

    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description="Contract-enforcing runner")
    parser.add_argument("--contract", required=True, help="Path to contract JSON")
    parser.add_argument("--script", required=True, help="Script to run")
    parser.add_argument("--args", nargs=argparse.REMAINDER, help="Arguments to script (prefix with --)")
    args = parser.parse_args(argv)

    contract = load_contract(args.contract)

    script_path = args.script
    script_args = args.args or []
    # If args begins with --, argparse keeps it; remove leading '--' if present
    if script_args and script_args[0] == "--":
        script_args = script_args[1:]

    result = run_with_contract(contract, script_path, script_args)
    json.dump(result, sys.stdout, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
