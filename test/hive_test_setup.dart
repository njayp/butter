import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Registers Hive [setUp]/[tearDown] for a test file: a fresh temp dir per
/// test, closing open boxes before wiping. The close must come first — Hive
/// keeps open boxes in static global state, so deleting one still open throws
/// `HiveError: box already open` in the next box-touching test.
void useTempHive() {
  setUp(() => Hive.init(Directory.systemTemp.createTempSync().path));
  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });
}
