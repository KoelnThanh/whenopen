import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/app.dart';

void main() {
  testWidgets('App startet und zeigt den Home-Screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WhenOpenApp()));
    await tester.pumpAndSettle();

    expect(find.text('WhenOpen'), findsOneWidget);
  });
}
