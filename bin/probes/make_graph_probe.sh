#!/usr/bin/env bash
set -euo pipefail
make -pn -f asciinema.mk vendor-player | rg 'vendor-player|vendor-player.json|artifacts'
