import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/services/downloads_backup_service.dart';

/// Prueft die Dart-Seite des nativen Sicherungs-Kanals (Kanalname + Argumente +
/// Rueckgabe). Die native MediaStore-Logik liegt in BackupStorage.kt.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const kanal = MethodChannel('com.whenopen/backup');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const service = DownloadsBackupService();

  tearDown(() => messenger.setMockMethodCallHandler(kanal, null));

  test('sichern sendet den Inhalt und gibt das Ordner-Label zurueck', () async {
    String? gesendet;
    messenger.setMockMethodCallHandler(kanal, (call) async {
      expect(call.method, 'sichern');
      gesendet = (call.arguments as Map)['inhalt'] as String;
      return 'Download/WhenOpen';
    });

    final label = await service.sichern('{"version":"2.1"}');

    expect(gesendet, '{"version":"2.1"}');
    expect(label, 'Download/WhenOpen');
  });

  test('sichern faellt auf ein Standard-Label zurueck, wenn nativ null kommt',
      () async {
    messenger.setMockMethodCallHandler(kanal, (call) async => null);
    expect(await service.sichern('x'), 'Download/WhenOpen');
  });

  test('letzteSicherung reicht den nativen Inhalt durch', () async {
    messenger.setMockMethodCallHandler(kanal, (call) async {
      expect(call.method, 'letzteSicherung');
      return '{"version":"2.1","eintraege":[]}';
    });

    expect(await service.letzteSicherung(), contains('2.1'));
  });

  test('letzteSicherung gibt null zurueck, wenn keine Sicherung existiert',
      () async {
    messenger.setMockMethodCallHandler(kanal, (call) async => null);
    expect(await service.letzteSicherung(), isNull);
  });
}
