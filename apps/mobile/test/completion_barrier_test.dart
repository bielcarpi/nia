import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/data/repositories.dart';
import 'package:nia_flutter/domain/models.dart';
import 'package:nia_flutter/realtime/realtime_client.dart';
import 'package:nia_flutter/ui/conversation_screen.dart';

void main() {
  testWidgets('completion waits for writes and an actual learner turn', (
    tester,
  ) async {
    final repository = _BarrierRepository();
    final grant = await tester.runAsync(
      () => repository.createSession(const TutorPreferences.defaults()),
    );
    expect(grant, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildNiaTheme(),
        home: ConversationScreen(
          grant: grant!,
          repository: repository,
          realtimeClient: DemoRealtimeClient(),
        ),
      ),
    );

    FilledButton finishButton() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Finish'),
        );

    expect(finishButton().onPressed, isNull,
        reason: 'no empty completion race');

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.textContaining('¡Hola!'), findsOneWidget);
    expect(
      finishButton().onPressed,
      isNull,
      reason: 'an assistant greeting is not enough to generate feedback',
    );

    await tester.enterText(
      find.byType(TextField).last,
      'Me gusta descubrir cafés nuevos.',
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Muy bien'), findsOneWidget);
    expect(finishButton().onPressed, isNotNull);

    await tester.tap(find.text('Finish'));
    await tester.pump();
    expect(repository.completeCalled, isFalse);
    expect(find.text('Finishing…'), findsOneWidget);

    repository.allowWrites();
    await tester.pumpAndSettle();
    expect(repository.completeCalled, isTrue);
    expect(find.text('Your feedback'), findsOneWidget);
  });
}

class _BarrierRepository implements ConversationRepository {
  final DemoRepository _delegate = DemoRepository();
  final Completer<void> _writeGate = Completer<void>();
  bool completeCalled = false;

  void allowWrites() => _writeGate.complete();

  @override
  Future<RealtimeGrant> createSession(TutorPreferences preferences) =>
      _delegate.createSession(preferences);

  @override
  Future<void> delete(String conversationId) =>
      _delegate.delete(conversationId);

  @override
  Future<ConversationDetail> get(String id) => _delegate.get(id);

  @override
  Future<ConversationPage> list({String? cursor}) =>
      _delegate.list(cursor: cursor);

  @override
  Future<void> saveTurn(
    String conversationId,
    ConversationTurn turn,
  ) async {
    await _writeGate.future;
    await _delegate.saveTurn(conversationId, turn);
  }

  @override
  Future<ConversationDetail> complete(String conversationId) async {
    completeCalled = true;
    return _delegate.complete(conversationId);
  }
}
