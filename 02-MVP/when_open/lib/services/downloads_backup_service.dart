import 'package:flutter/services.dart';

/// Bruecke zum nativen Sicherungs-Kanal (siehe `BackupStorage.kt`): schreibt und
/// liest die WhenOpen-Sicherung im im Dateimanager sichtbaren Ordner
/// `Download/WhenOpen`. Ab Android 10 ohne Berechtigung (MediaStore).
class DownloadsBackupService {
  const DownloadsBackupService();

  static const _kanal = MethodChannel('com.whenopen/backup');

  /// Schreibt [inhalt] in den festen Sicherungsordner (ueberschreibt eine
  /// vorhandene Datei) und gibt das anzeigbare Ordner-Label zurueck
  /// (z. B. „Download/WhenOpen"). Wirft [PlatformException] bei Fehlern —
  /// Code `KEINE_BERECHTIGUNG`, wenn auf Android 8/9 die Freigabe fehlt.
  Future<String> sichern(String inhalt) async {
    final label =
        await _kanal.invokeMethod<String>('sichern', {'inhalt': inhalt});
    return label ?? 'Download/WhenOpen';
  }

  /// Inhalt der neuesten Sicherung im Ordner, oder null wenn keine existiert.
  Future<String?> letzteSicherung() =>
      _kanal.invokeMethod<String>('letzteSicherung');

  /// Öffnet den System-Dateibrowser (`ACTION_OPEN_DOCUMENT`) und gibt die
  /// gewählte Datei als `{name, inhalt}` zurück — oder null, wenn die Auswahl
  /// abgebrochen wurde. So lässt sich eine beliebige (auch empfangene)
  /// Sicherung importieren, ohne JSON-Text zu kopieren.
  Future<Map<String, String>?> dateiWaehlen() =>
      _kanal.invokeMapMethod<String, String>('dateiWaehlen');
}
