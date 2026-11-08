import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ciego_volley/app.dart';

void main() {
  testWidgets('sin Supabase configurado muestra la pantalla de ayuda', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: CiegoVolleyApp(supabaseReady: false)),
    );

    expect(find.text('Falta configurar Supabase'), findsOneWidget);
    expect(find.textContaining('dart_defines/dev.json'), findsWidgets);
  });
}
