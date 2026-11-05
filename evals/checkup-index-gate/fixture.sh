#!/bin/bash
# Scaffold: generate the 210-line index fixture into the run's workspace.
set -e
here=$(cd "$(dirname "$0")" && pwd)
sh "$here/../../tests/make-index-fixture.sh" "$PWD/memory" >/dev/null
