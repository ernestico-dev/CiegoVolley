import 'package:ciego_volley/app.dart';
import 'package:ciego_volley/core/supabase/supabase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sesión nula sin tocar el SDK ni la red.
class _SignedOutSession extends SessionNotifier {
  @override
  Session? build() => null;
}

void main() {
  testWidgets('sin sesión el router redirige al login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(_SignedOutSession.new)],
        child: const CiegoVolleyApp(supabaseReady: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CiegoVolley'), findsOneWidget);
    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('Olvidé mi contraseña'), findsOneWidget);
  });
}
