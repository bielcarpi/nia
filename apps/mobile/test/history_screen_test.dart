import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/data/repositories.dart';
import 'package:nia_flutter/ui/history_screen.dart';

void main() {
  testWidgets(
      'deleting a conversation refreshes history without setState errors',
      (tester) async {
    final repository = DemoRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildNiaTheme(),
        home: Scaffold(body: HistoryScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ordering at a café'), findsOneWidget);
    await tester.tap(find.byTooltip('Conversation actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this conversation?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('No sessions yet'), findsOneWidget);
  });
}
