#!/usr/bin/env bash
#
# dev.sh — a Claude-owned Flutter run loop.
#
# Owns the `flutter run` process so its logs (stdout) and hot-reload commands
# (stdin) are drivable from a terminal, independent of VS Code's F5 session.
#
# Subcommands: start | reload | restart | shot | logs | stop
set -euo pipefail

DEVICE="iPhone 16"
CMD_FIFO="/tmp/butter-cmd"
RUN_LOG="/tmp/butter-run.log"
SHOT_PNG="/tmp/butter-shot.png"

usage() {
  echo "usage: dev.sh {start|reload|restart|shot|logs|stop}" >&2
  exit 2
}

start() {
  # Idempotent boot: bootstatus boots only if needed, else waits for the sim.
  # Reuses the "Boot iOS Simulator" task command from .vscode/tasks.json.
  xcrun simctl bootstatus "$DEVICE" -b && open -a Simulator

  : > "$RUN_LOG"
  rm -f "$CMD_FIFO"
  mkfifo "$CMD_FIFO"

  # `tail -f` on the FIFO holds flutter run's stdin open forever (no EOF),
  # so we can feed it r/R/q on demand. Detach the whole pipeline's stdio
  # (</dev/null, log for out+err) so the persistent `tail -f` feeder can't
  # inherit — and thus hold open — a caller's stdout/stderr pipe. Without
  # this, `dev.sh start 2>&1 | tail` blocks forever waiting on an EOF the
  # never-exiting feeder withholds.
  { tail -f "$CMD_FIFO" | flutter run -d "$DEVICE"; } </dev/null >> "$RUN_LOG" 2>&1 &
  echo "started flutter run on '$DEVICE' (logs: $RUN_LOG)"
}

reload()  { echo r > "$CMD_FIFO"; echo "hot reload sent"; }
restart() { echo R > "$CMD_FIFO"; echo "hot restart sent"; }

shot() {
  xcrun simctl io booted screenshot "$SHOT_PNG"
  echo "$SHOT_PNG"
}

# Non-blocking: a finite read, never `tail -f` (which would hang the caller).
logs() { tail -n "${1:-50}" "$RUN_LOG"; }

stop() {
  echo q > "$CMD_FIFO" 2>/dev/null || true   # ask flutter run to quit cleanly
  pkill -f "flutter run -d $DEVICE" 2>/dev/null || true
  pkill -f "tail -f $CMD_FIFO" 2>/dev/null || true   # reap the FIFO feeder
  rm -f "$CMD_FIFO"
  echo "stopped (simulator left booted; FIFO removed)"
}

case "${1:-}" in
  start)   start ;;
  reload)  reload ;;
  restart) restart ;;
  shot)    shot ;;
  logs)    shift; logs "$@" ;;
  stop)    stop ;;
  *)       usage ;;
esac
