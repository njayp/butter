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

---

_Update this file when conventions change; update README.md when scope changes._
