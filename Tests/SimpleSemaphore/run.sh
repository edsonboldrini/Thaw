#!/usr/bin/env bash
# Behavioral checks for SimpleSemaphore. The 1.x line has no test target, so
# this compiles the actor straight out of MenuBarItemManager.swift together
# with main.swift and runs the result.
#
# Usage: Tests/SimpleSemaphore/run.sh [git-rev]
#   With no argument it checks the working tree; with a revision it checks
#   the actor as it was at that revision.
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
fi | awk '/^actor SimpleSemaphore \{/{on=1} on{print} on && /^\}/{on=0}' > "$work/body.swift"

# A private member is visible to an extension in the same file, so the test-only
# accessor is appended here instead of being added to the app code.
{
  echo "import Foundation"
  cat "$work/body.swift"
  echo "extension SimpleSemaphore { var waiterCount: Int { waiters.count } }"
} > "$work/SimpleSemaphore.swift"
swiftc -O -swift-version 5 -o "$work/check" "$work/SimpleSemaphore.swift" "$here/main.swift"
"$work/check"
