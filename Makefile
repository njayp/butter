# Makefile — human-facing app tasks.
# (Claude's simulator run loop lives in scripts/dev.sh.)

# Physical iPhone UDID, from `flutter devices`. Override per device:
#   make iphone IPHONE=<other-udid>
IPHONE ?= 00008120-001C25142EF8C01E

# Build a release copy and run it on the iPhone. Once it launches you can
# press Ctrl-C — the app stays installed and runs standalone until the
# provisioning profile expires (~1 year on a paid account); re-run to renew.
#
# Deploying to a NEW device the first time must register it and mint a profile.
# Flutter passes -allowProvisioningUpdates so this is automatic, but if the run
# errors on signing, open ios/Runner.xcworkspace in Xcode and Run once to seed
# the profile, then `make iphone` works thereafter.
.PHONY: iphone
iphone:
	flutter run --release -d $(IPHONE)

# Attached debug session on the iPhone with hot reload (the real-device
# analogue of the simulator loop). Ctrl-C to quit.
.PHONY: iphone-debug
iphone-debug:
	flutter run -d $(IPHONE)
