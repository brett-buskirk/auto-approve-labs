#!/usr/bin/env bash
# Builds the disposable fixture repo the reaper is allowed to touch: main, two merged
# feature branches (the prey), one unmerged branch (must survive), and the marker file
# the reaper's blast-radius guard requires. Idempotent: wipes and rebuilds.
set -euo pipefail

FIXTURE="${1:?usage: make-fixture.sh <path>}"

rm -rf "$FIXTURE"
git init -q -b main "$FIXTURE"
g(){ git -C "$FIXTURE" "$@"; }

# Local-only identity and no signing: deterministic on any machine, including CI.
g config user.name  "Lab Fixture"
g config user.email "lab@invalid.example"
g config commit.gpgsign false

touch "$FIXTURE/.reaper-lab-fixture"
g add .reaper-lab-fixture
g commit -qm "init fixture"

for name in feature/one feature/two; do
  g checkout -qb "$name"
  echo "$name" >> "$FIXTURE/work.txt"
  g add work.txt
  g commit -qm "work on $name"
  g checkout -q main
  g merge -q --no-edit "$name"
done

g checkout -qb wip/unmerged
echo "unfinished" > "$FIXTURE/wip.txt"
g add wip.txt
g commit -qm "unmerged work"
g checkout -q main

printf 'fixture ready: %s (branches: %s)\n' "$FIXTURE" \
  "$(g branch --format='%(refname:short)' | paste -sd' ' -)"
