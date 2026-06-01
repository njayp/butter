#!/usr/bin/env bash
#
# dev.sh — a Claude-owned Flutter run loop.
#
# Owns the `flutter run` process so its logs (stdout) and hot-reload commands
# (stdin) are drivable from a terminal, independent of VS Code's F5 session.
#
# Subcommands: start | reload | restart | shot | logs | stop | tap | type | key
set -euo pipefail

DEVICE="iPhone 16"
BUNDLE_ID="nickjaypowellgmail.com.butter" # app to terminate on stop
CMD_FIFO="/tmp/butter-cmd"
RUN_LOG="/tmp/butter-run.log"
SHOT_PNG="/tmp/butter-shot.png"

# fb-idb drives touch/text input that simctl can't. Resolve the CLI whether or
# not ~/.local/bin is on PATH; `idb` auto-spawns its companion on first use.
IDB="$(command -v idb || echo "$HOME/.local/bin/idb")"

# `flutter` is a wrapper that execs the dart snapshot, so the real run process
# shows up in `ps` as the snapshot invocation below — the literal "flutter run"
# never does. Matching the wrong string is why `stop` used to miss orphans.
RUN_PATTERN="flutter_tools.snapshot run -d $DEVICE"
FEEDER_PATTERN="tail -f $CMD_FIFO"

usage() {
  echo "usage: dev.sh {start|reload|restart|shot|logs|stop|tap|type|key}" >&2
  exit 2
}

# True while a `flutter run` (ours or an F5 session) drives the device.
run_alive() { pgrep -f "$RUN_PATTERN" >/dev/null 2>&1; }
# True while OUR loop is up — the FIFO feeder is its unique signature.
ours_alive() { pgrep -f "$FEEDER_PATTERN" >/dev/null 2>&1; }

# UDID of our booted DEVICE — idb addresses targets by UDID, not by name.
device_udid() {
  local u
  u="$(xcrun simctl list devices booted | grep "$DEVICE (" | grep -oE '[0-9A-F-]{36}' | head -1)"
  if [[ -z "$u" ]]; then
    echo "no booted '$DEVICE'; run 'dev.sh start' first" >&2
    exit 1
  fi
  printf '%s' "$u"
}

# fb-idb must be installed for the touch/text subcommands below.
require_idb() {
  if [[ ! -x "$IDB" ]]; then
    echo "idb not found. Install: brew install facebook/fb/idb-companion && pipx install fb-idb" >&2
    exit 1
  fi
}

start() {
  # Idempotent boot: bootstatus boots only if needed, else waits for the sim.
  # Reuses the "Boot iOS Simulator" task command from .vscode/tasks.json.
  xcrun simctl bootstatus "$DEVICE" -b && open -a Simulator

  # Never stack two of our own loops — reap a previous one (or a stale FIFO).
  if ours_alive || [[ -e "$CMD_FIFO" ]]; then
    echo "reaping a previous dev.sh loop" >&2
    stop >/dev/null
  fi
  # A `flutter run` we don't own (almost always VS Code's F5) still holds the
  # device. Two app instances on one sim is the confusing state CLAUDE.md warns
  # about, so refuse rather than stack — `stop` clears a stale one.
  if run_alive; then
    echo "another 'flutter run' already targets '$DEVICE' (VS Code F5?)." >&2
    echo "stop that session first, or run 'dev.sh stop' to clear a stale one." >&2
    exit 1
  fi

  # Flutter's install step hangs (stuck right after "Xcode build done") when an
  # instance of the app is already running in the sim foreground — e.g. left
  # over from an F5 session or a crashed run that our reap path above didn't
  # catch. Terminating it first lets the fresh install land cleanly.
  xcrun simctl terminate "$DEVICE" "$BUNDLE_ID" 2>/dev/null || true

  : >"$RUN_LOG"
  rm -f "$CMD_FIFO"
  mkfifo "$CMD_FIFO"

  # `tail -f` on the FIFO holds flutter run's stdin open forever (no EOF), so we
  # can feed it r/R/q on demand. Detach the whole pipeline's stdio (</dev/null,
  # log for out+err) so the persistent feeder can't inherit — and thus hold open
  # — a caller's stdout/stderr pipe. Without this, `dev.sh start | tail` blocks
  # forever waiting on an EOF the never-exiting feeder withholds.
  { tail -f "$CMD_FIFO" | flutter run -d "$DEVICE"; } </dev/null >>"$RUN_LOG" 2>&1 &
  echo "started flutter run on '$DEVICE' (logs: $RUN_LOG)"

  # Block until the app is actually up, so the caller's next reload/shot lands
  # on the running app and not a half-built one (the bug we kept hitting). The
  # detached pipeline above means this wait never holds open a caller's pipe.
  printf 'waiting for launch'
  local i seen=0
  for ((i = 0; i < 90; i++)); do # 90 × 2s ≈ 3 min, enough for a cold build
    if grep -q "Flutter run key commands\." "$RUN_LOG"; then
      echo " — ready"
      return 0
    fi
    # The wrapper needs a moment to exec the dart snapshot, so only treat a
    # vanished process as a real early exit once we've actually seen it alive.
    if run_alive; then
      seen=1
    elif ((seen)); then
      echo " — flutter run exited early; see 'dev.sh logs'" >&2
      return 1
    fi
    sleep 2
    printf '.'
  done
  echo " — still not ready after 3 min; check 'dev.sh logs'" >&2
  return 1
}

reload() {
  echo r >"$CMD_FIFO"
  echo "hot reload sent"
}
restart() {
  echo R >"$CMD_FIFO"
  echo "hot restart sent"
}

shot() {
  xcrun simctl io booted screenshot "$SHOT_PNG"
  echo "$SHOT_PNG"
}

# Tap at device-point coordinates (top-left origin). List widgets and their
# point frames with `idb ui describe-all` (companion auto-targets the sim).
tap() {
  require_idb
  "$IDB" ui tap --udid "$(device_udid)" "$1" "$2"
  echo "tapped ($1, $2)"
}

# Replace the focused field's contents with TEXT, like Flutter's
# tester.enterText. Tap the field first; a centre/right tap parks the cursor at
# the end so the leading backspaces clear it.
type_text() {
  require_idb
  local udid
  udid="$(device_udid)"
  # Clear: 20 backspaces (HID 42) — covers any Pokédex number; surplus
  # backspaces on a shorter value are no-ops.
  "$IDB" ui key-sequence --udid "$udid" $(printf '42 %.0s' {1..20})
  "$IDB" ui text --udid "$udid" "$1"
  echo "typed '$1'"
}

# Press a key: return|enter|backspace, or a raw HID usage code.
key() {
  require_idb
  local code
  case "$1" in
    return | enter) code=40 ;;
    backspace) code=42 ;;
    *) code="$1" ;;
  esac
  "$IDB" ui key --udid "$(device_udid)" "$code"
  echo "key $1"
}

# Non-blocking: a finite read, never `tail -f` (which would hang the caller).
logs() { tail -n "${1:-50}" "$RUN_LOG"; }

stop() {
  # Ask flutter run to quit cleanly, but only if our feeder is alive to read it
  # (writing to a FIFO with no reader blocks forever).
  if ours_alive; then
    echo q >"$CMD_FIFO" 2>/dev/null || true
    sleep 1 # let flutter detach cleanly before we force-kill
  fi
  pkill -f "$FEEDER_PATTERN" 2>/dev/null || true                 # reap the feeder
  pkill -f "$RUN_PATTERN" 2>/dev/null || true                    # reap flutter run
  xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true # quit the app
  rm -f "$CMD_FIFO"
  echo "stopped (simulator left booted; app terminated; FIFO removed)"
}

case "${1:-}" in
  start) start ;;
  reload) reload ;;
  restart) restart ;;
  shot) shot ;;
  tap)
    shift
    tap "$@"
    ;;
  type)
    shift
    type_text "$@"
    ;;
  key)
    shift
    key "$@"
    ;;
  logs)
    shift
    logs "$@"
    ;;
  stop) stop ;;
  *) usage ;;
esac
