# Makefile — human-facing app tasks.
# (Claude's simulator run loop lives in scripts/dev.sh.)

# Physical iPhone UDID, from `flutter devices`. Override per device:
#   make iphone IPHONE=<other-udid>
IPHONE ?= 00008120-001C25142EF8C01E

# Build a release copy and run it on the iPhone. Once it launches you can
# press Ctrl-C — the app stays installed and runs standalone (no Mac needed
# until the provisioning profile expires, ~1 year on a paid account).
.PHONY: iphone
iphone:
	flutter run --release -d $(IPHONE)

# Attached debug session on the iPhone with hot reload (the real-device
# analogue of the simulator loop). Ctrl-C to quit.
.PHONY: iphone-debug
iphone-debug:
	flutter run -d $(IPHONE)
