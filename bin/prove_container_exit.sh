#!/usr/bin/env bash
set -e

NAME="evidence-exit-proof"

echo "PRECONDITION: starting container"

set +e
docker run --rm \
  --name "$NAME" \
  --platform linux/amd64 \
  -v "$PWD:/workspace" \
  -w /workspace \
  ghcr.io/catthehacker/ubuntu:js-latest \
  bash -lc '
    echo "CONTAINER: started"
    python3 --version
    ./bin/probes/env_probe
    echo "CONTAINER: setup complete"
  '
rc=$?
set -e

echo "OBSERVATION: docker_run_exit_code=$rc"

if [ "$rc" -ne 0 ]; then
  echo "POSTCONDITION: FAIL - container command failed"
  exit "$rc"
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  echo "POSTCONDITION: FAIL - container still exists"
  exit 1
else
  echo "POSTCONDITION: PASS - container exited and was removed"
fi