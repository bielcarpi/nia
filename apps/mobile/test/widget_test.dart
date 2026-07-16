import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nia_flutter/app/dependencies.dart';
import 'package:nia_flutter/app/nia_app.dart';
import 'package:nia_flutter/config/app_config.dart';
import 'package:nia_flutter/core/auth/auth_service.dart';
import 'package:nia_flutter/data/repositories.dart';
import 'package:nia_flutter/realtime/realtime_client.dart';

void main() {
  testWidgets('offline demo completes the core practice journey',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = DemoRepository();
    final dependencies = AppDependencies(
      config: AppConfig(
        demoMode: true,
        localStack: false,
        apiBaseUrl: Uri.parse('http://localhost:8080'),
      ),
      auth: DemoAuthService(),
      preferences: repository,
      conversations: repository,
      realtimeClientFactory: (_) => DemoRealtimeClient(),
    );

    await tester.pumpWidget(NiaApp(dependencies: dependencies));
    expect(tester.takeException(), isNull);
    expect(find.text('Open the demo'), findsOneWidget);

    await tester.ensureVisible(find.text('Open the demo'));
    await tester.tap(find.text('Open the demo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ready when you are'), findsOneWidget);

    await tester.ensureVisible(find.text('Start conversation'));
    await tester.tap(find.text('Start conversation'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('¡Hola!'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      'Yo soy bien.',
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Estoy bien.'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Your feedback'), findsOneWidget);
    expect(find.text('Corrections'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
