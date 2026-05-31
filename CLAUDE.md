## Claude-Code Plan Guidelines

**Context:** Explain why this change is needed — the problem, what prompted it, and the intended outcome.
**Reuse:** Search for existing functions, utilities, and patterns before proposing new code. List any reused code with file paths.
**Simplicity:** Follow existing patterns, conventions, and tech stack. Avoid unnecessary abstractions — don't add new helpers, layers, or files when existing ones suffice.
**Completeness:** Include absolute file paths with line numbers, a "Critical Files" section, and a testing strategy where applicable.
**Verification:** Include concrete steps to verify changes end-to-end using available tools (e.g. project test/build commands, `grep`, browser automation) — not manual inspection alone.

## Coding Guidelines

- **File size** — under 400 lines, single responsibility. When approaching the cap, split rather than pack more in.
- **DRY** — don't repeat yourself
- **YAGNI** — you ain't gonna need it
- **KISS** — keep it simple. Prefer simplicity and elegance; remove unnecessary code.
- **test behavior** — prefer testing behavior over implementation details
- **log levels** — errors: something failed that shouldn't have; warnings: system works but is degraded or misconfigured; info: normal operations worth noting

## Flutter / Dart

- This repo is for learning Flutter. Lean toward explanations that build understanding, not just shipped code. Link to official Flutter/Dart docs when introducing a new concept.
- Run `dart format .` and `flutter analyze` before considering a change done.
- Run `flutter test` for unit/widget tests; prefer widget tests that exercise observable behavior over rebuild-count assertions.
- Prefer `const` constructors where possible.
- Prefer composition (small `StatelessWidget`s) over deep widget trees in a single file.
- Keep null-safety strict — no `!`.

## Running the app (for Claude)

F5 (VS Code's Dart extension) is for the human's hands-on sessions and stays
untouched. When asked to verify a change, Claude drives its own `flutter run`
loop via [scripts/dev.sh](scripts/dev.sh), which owns the process so its logs
and hot-reload commands are readable from the terminal:

| Command                        | Effect                                                            |
| ------------------------------ | ----------------------------------------------------------------- |
| `bash scripts/dev.sh start`    | Boot the `iPhone 16` sim (if needed) + launch the app             |
| `bash scripts/dev.sh reload`   | Hot reload changed `.dart` files (`r`)                            |
| `bash scripts/dev.sh restart`  | Hot restart the app (`R`)                                         |
| `bash scripts/dev.sh shot`     | Screenshot the sim → `/tmp/butter-shot.png`                       |
| `bash scripts/dev.sh logs [N]` | Print last N (default 50) lines of `/tmp/butter-run.log`          |
| `bash scripts/dev.sh stop`     | Quit the app, reap the feeder, remove the FIFO (sim stays booted) |

**Verify loop:** edit `.dart` → `reload` → `logs` (check for exceptions /
expected `print` output) → `shot` (inspect rendered UI) → `dart format .` /
`flutter analyze` / `flutter test`.

**Caveat:** F5 and this loop both target the same booted `iPhone 16`. Don't run
both at once (two app instances is confusing) — stop the F5 session first, or
run this loop while F5 is idle.

---

_Update this file when conventions change; update README.md when scope changes._
