import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/screens/ueber_screen.dart';

void main() {
  test('„Über WhenOpen" zeigt die Version aus pubspec.yaml', () {
    // kAppVersion ist eine Konstante — ohne diesen Test driftet sie beim
    // Versionssprung unbemerkt weg (war bis v1.3.0 noch "1.2.0").
    final zeile = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((z) => z.startsWith('version:'));
    final version = zeile.split(':').last.trim().split('+').first;
    expect(kAppVersion, version);
  });
}
