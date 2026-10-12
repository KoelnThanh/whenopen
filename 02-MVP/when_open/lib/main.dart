import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'providers/locations_provider.dart';
import 'widget/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Datums-/Wochentagsnamen für den Header (DateFormat 'de').
  await initializeDateFormatting('de', null);

  // Nach jeder Datenaenderung das Widget neu zeichnen lassen (rechnet nativ).
  AppDataNotifier.onDatenGeaendert = (_) => WidgetService.aktualisiereWidget();
  // Beim Start einmal anstossen: deckt Widgets ab, die vor einem App-Update
  // platziert wurden, und plant deren Takt neu.
  unawaited(WidgetService.aktualisiereWidget());

  runApp(const ProviderScope(child: WhenOpenApp()));
}
