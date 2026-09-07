# Lab 001 — The Prompt That Never Asked

Companion lab for episode 001. You build (well, you're handed) a small destructive CLI — a
stale-branch reaper — with the same safety spine as the real tool it re-derives: dry-run by
default, `--apply` to mutate, a confirm gate that reads from the terminal, an audit log.
Then you run it the way automation runs it, headless, and watch the confirm gate's tty
probe fail in exactly the way the episode describes. Then you prove the fix with a
regression test that asserts the refusal itself.

**Cost: $0.** Fully offline. Nothing here touches the network, the cloud, or any git repo
except the disposable fixture it creates inside this directory.

## Prerequisites

- bash ≥ 5
- git ≥ 2.30
- util-linux (`setsid` and `script` — present by default on Ubuntu/Debian)
- GNU make

Recorded against: bash 5.1.16, git 2.34.1, util-linux 2.37.2, Ubuntu 22.04.5 (WSL2); also
verified on a GitHub Actions `ubuntu-latest` runner by CI (`.github/workflows/lab-001.yml`
in this repo).

## Run it

```bash
make setup      # build the fixture repo: main, two merged branches, one unmerged
make run        # dry-run sweep — the default, safe path
make verify     # full test suite, keyboard and headless paths both
make crash      # reproduce the bug: buggy probe, headless, strict mode on
make teardown   # remove everything the lab created
```

The interesting walk, after `make setup`:

1. `./reaper fixture` — dry-run. Nothing needs confirming because nothing is deleted.
2. `./reaper fixture --apply` — from your terminal: the `[y/N]` prompt appears. Answer `n`.
3. `make crash` — the same command, headless, with the buggy probe the episode studies
   (`REAPER_BUGGY_TTY_PROBE=1`). The permission-bits check passes, the tty fails to open,
   and `set -u` kills the script with a raw `unbound variable`. Nothing is deleted.
4. `REAPER_BUGGY_TTY_PROBE=1 REAPER_NO_STRICT=1 setsid --wait ./reaper fixture --apply </dev/null`
   — the same bug without strict mode: the empty reply hits the `[y/N]` default-No branch
   and refuses by accident. Two layers of luck, neither of them the documented behavior.
5. `setsid --wait ./reaper fixture --apply </dev/null` — the fixed probe: a graceful,
   documented refusal ("no tty for confirmation — pass --yes"), on stderr, failing closed.
6. `make verify` — the suite asserts all of the above, message text and repository state,
   never just exit codes. Exit-code-only assertions are how the bug survived.

## Lab flags

| Env var | Effect |
|---|---|
| `REAPER_BUGGY_TTY_PROBE=1` | Use the buggy permission-bits tty probe from the episode |
| `REAPER_NO_STRICT=1` | Turn off `set -u`, to see what the bug does without strict mode |

## Safety

The reaper refuses to run on any repo that lacks the `.reaper-lab-fixture` marker file
`make setup` plants — so it cannot touch your real repositories, even by accident, even
with `--apply --yes`. Every file the lab creates (fixture, audit log, test artifacts)
lives inside this directory; `make teardown` removes all of it.

## Provenance

The safety spine and the bug are re-derived from freki, a real deletion tool in the host's
estate: https://github.com/brett-buskirk/freki — see its `CHANGELOG.md`, `[1.0.1]`.
