# auto-approve-labs

Runnable companion labs for **Auto-Approve**, a hands-on podcast about building real
software with AI coding agents — the workflows, the context, and the CI discipline that
make agent output safe to merge. Hosted by Brett Buskirk
([brett-buskirk.dev](https://brett-buskirk.dev)).

Every episode takes one real task end to end, drives it into a ditch on purpose, and shows
the guardrail that catches it. The labs are where you do the same thing yourself. One lab
per episode that needs one, each treated like production code.

> Listen: [auto-approve.podbean.com](https://auto-approve.podbean.com/)

## The labs

| Lab | Episode | What breaks, and what catches it |
|-----|---------|----------------------------------|
| [`001-the-prompt-that-never-asked`](001-the-prompt-that-never-asked/) | Ep. 001 | A deletion tool's confirm gate silently can't fire headless; dry-run defaults, fail-closed probes, and a regression test that asserts the refusal itself. |

## How labs work

Every lab holds to the same contract:

- **Runs from a clean clone.** Prerequisites are listed in the lab's README; no hidden
  state, no "you probably already have this."
- **`make setup` · `make run` · `make verify` · `make teardown`.** Teardown removes
  everything the lab created.
- **Costs are stated up front.** A lab that provisions billable resources says so in its
  README, first section, with a rough number. Lab 001 costs nothing and runs offline.
- **Versions are pinned** and recorded against what the episode was recorded with.
- **No secrets.** Where a lab needs credentials, `.env.example` and the README explain how
  to create your own.

If a lab doesn't pass its own `make verify` from a fresh clone, that's a bug — issues
welcome.

## License

MIT — run them, fork them, break them on purpose. See [`LICENSE`](LICENSE).
