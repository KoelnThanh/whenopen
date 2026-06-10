import 'package:workmanager/workmanager.dart';

import 'widget_service.dart';

/// WorkManager-Task-Name fuer das periodische Sicherheitsnetz (E16).
const widgetNetzTask = 'whenopen-widget-netz';

/// Einstiegspunkt fuer WorkManager (separates Hintergrund-Isolate).
/// Faengt verschluckte Alarme ab (Doze, Neustart) — laeuft ~alle 15 min.
@pragma('vm:entry-point')
void widgetWorkmanagerDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await WidgetService.aktualisiereWidget();
    return true;
  });
}
