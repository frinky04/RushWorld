#!/usr/bin/env bash
set -euo pipefail

exec "$(dirname "$0")/.rocks/bin/busted" spec "$@"

