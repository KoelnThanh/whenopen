import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';
import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/kategorien_screen.dart';
import 'screens/quick_entry/quick_entry_screen.dart';
import 'theme/app_theme.dart';

/// Router als Top-Level, damit Deep Links (whenopen://open/:id) auch bei
/// laufender App in die bestehende Navigation einsteigen.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'detail/:id',
          builder: (context, state) =>
              DetailScreen(locationId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'quick-entry',
          builder: (context, state) => QuickEntryScreen(
            editId: state.uri.queryParameters['editId'],
            kategorieId: state.uri.queryParameters['kategorie'],
          ),
        ),
        GoRoute(
          path: 'kategorien',
          builder: (context, state) => const KategorienScreen(),
        ),
        // Deep-Link-Ziel fuer Widget-Taps: whenopen://open/:id
        GoRoute(
          path: 'open/:id',
          redirect: (context, state) =>
              '/detail/${state.pathParameters['id']}',
        ),
      ],
    ),
  ],
);

class WhenOpenApp extends StatelessWidget {
  const WhenOpenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: buildAppTheme(),
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de')],
      locale: const Locale('de'),
    );
  }
}
