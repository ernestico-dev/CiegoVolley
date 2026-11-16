import 'package:ciego_volley/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpAvatar(
  WidgetTester tester, {
  String name = 'Ana Torres',
  String? avatarUrl,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: Center(
          child: UserAvatar(name: name, avatarUrl: avatarUrl, radius: 24),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('muestra las iniciales cuando no hay foto', (tester) async {
    await pumpAvatar(tester);

    expect(find.text('AT'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('mantener pulsado abre la foto ampliada', (tester) async {
    await pumpAvatar(tester);

    await tester.longPress(find.byType(UserAvatar));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Ana Torres'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
  });

  test('las iniciales toman las dos primeras palabras', () {
    expect(UserAvatar.initialsOf('Ernesto Carbonell Paz'), 'EC');
    expect(UserAvatar.initialsOf('ana'), 'A');
    expect(UserAvatar.initialsOf('   '), '?');
  });
}
