#!/bin/bash
# Scaffold: copy the baseline memory fixture into the run's workspace.
set -e
here=$(cd "$(dirname "$0")" && pwd)
cp -r "$here/../../tests/fixture-memory-baseline" memory
