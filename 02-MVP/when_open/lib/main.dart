import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'providers/locations_provider.dart';
import 'widget/widget_background_callback.dart';
import 'widget/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Datums-/Wochentagsnamen für den Header (DateFormat 'de').
  await initializeDateFormatting('de', null);

  if (Platform.isAndroid) {
    // E16: ereignisgetriebene Widget-Updates nach jeder Datenaenderung.
    AppDataNotifier.onDatenGeaendert = (daten) async {
      await WidgetService.pushWidgetDaten(daten);
      await WidgetService.planeNaechstenAlarm(daten.eintraege);
    };

    // Aktualisieren-Knopf im Widget: ruft widgetInteraktionCallback im
    // Hintergrund-Isolate auf (Handle wird persistent gespeichert, wirkt
    // also auch bei beendeter App).
    await HomeWidget.registerInteractivityCallback(widgetInteraktionCallback);

    await AndroidAlarmManager.initialize();

    // Sicherheitsnetz: periodischer WorkManager-Task (~15 min, Doze-bewusst).
    await Workmanager().initialize(widgetWorkmanagerDispatcher);
    await Workmanager().registerPeriodicTask(
      widgetNetzTask,
      widgetNetzTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );

    // Beim App-Start einmal frisch rechnen (deckt auch TIME_CHANGED ab,
    // da der Nutzer nach Zeitumstellung die App ohnehin neu sieht).
    // Fehler hier duerfen den App-Start nie verhindern.
    // ignore: unawaited_futures
    WidgetService.aktualisiereWidget().catchError((Object _) {});
  }

  runApp(const ProviderScope(child: _LifecycleWrapper()));
}

/// E16: Wenn die App in den Hintergrund geht, frische Widget-Daten
/// schreiben — so ist das Widget beim naechsten Entsperren aktuell
/// (USER_PRESENT-Receiver sind ab Android 8 gesperrt).
class _LifecycleWrapper extends StatefulWidget {
  const _LifecycleWrapper();

  @override
  State<_LifecycleWrapper> createState() => _LifecycleWrapperState();
}

class _LifecycleWrapperState extends State<_LifecycleWrapper> {
  AppLifecycleListener? _listener;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _listener = AppLifecycleListener(
        onPause: () =>
            WidgetService.aktualisiereWidget().catchError((Object _) {}),
      );
    }
  }

  @override
  void dispose() {
    _listener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const WhenOpenApp();
}
