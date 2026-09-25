#!/usr/bin/env bash
# Checks for the move-recovery helpers. The 1.x line has no test target, so
# this compiles the block between the "Move recovery" markers in
# MenuBarItemManager.swift together with main.swift and runs the result.
#
# Usage: Tests/MoveRecovery/run.sh [git-rev]
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
source_file=Thaw/MenuBar/MenuBarItems/MenuBarItemManager.swift
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

if [[ $# -gt 0 ]]; then
  git -C "$root" show "$1:$source_file"
else
  cat "$root/$source_file"
fi | awk '/^\/\/ MARK: - Move recovery/{on=1} on{print} /^\/\/ MARK: - End move recovery/{on=0}' > "$work/body.swift"

{ echo "import CoreGraphics"; echo "import Foundation"; cat "$work/body.swift"; } > "$work/MoveRecovery.swift"
swiftc -O -swift-version 5 -o "$work/check" "$work/MoveRecovery.swift" "$here/main.swift"
"$work/check"
