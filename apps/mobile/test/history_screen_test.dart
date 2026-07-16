import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/data/repositories.dart';
import 'package:nia_flutter/domain/models.dart';
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

  testWidgets('loads subsequent history pages from next_cursor',
      (tester) async {
    final repository = _PagedRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNiaTheme(),
        home: Scaffold(body: HistoryScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First session'), findsOneWidget);
    expect(find.text('Second session'), findsNothing);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(find.text('First session'), findsOneWidget);
    expect(find.text('Second session'), findsOneWidget);
    expect(repository.requestedCursors, <String?>[null, 'page-2']);
  });

  testWidgets('slow deletion cannot call setState after disposal',
      (tester) async {
    final repository = _PagedRepository(delayDelete: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNiaTheme(),
        home: Scaffold(body: HistoryScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Conversation actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    repository.finishDelete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a stale refresh cannot overwrite a newer history response',
      (tester) async {
    final repository = _RacingRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNiaTheme(),
        home: Scaffold(body: HistoryScreen(repository: repository)),
      ),
    );
    await tester.pump();
    expect(repository.calls, 1);

    await tester.tap(find.byTooltip('Refresh history'));
    await tester.pump();
    expect(repository.calls, 2);

    repository.newer.complete(
      ConversationPage(items: <ConversationSummary>[_summary('fresh')]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fresh session'), findsOneWidget);

    repository.older.complete(
      ConversationPage(items: <ConversationSummary>[_summary('stale')]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fresh session'), findsOneWidget);
    expect(find.text('Stale session'), findsNothing);
  });
}

class _RacingRepository implements ConversationRepository {
  final Completer<ConversationPage> older = Completer<ConversationPage>();
  final Completer<ConversationPage> newer = Completer<ConversationPage>();
  int calls = 0;

  @override
  Future<ConversationPage> list({String? cursor}) {
    calls++;
    return calls == 1 ? older.future : newer.future;
  }

  @override
  Future<void> delete(String conversationId) async {}

  @override
  Future<ConversationDetail> complete(String conversationId) =>
      Future<ConversationDetail>.error(UnimplementedError());

  @override
  Future<RealtimeGrant> createSession(TutorPreferences preferences) =>
      Future<RealtimeGrant>.error(UnimplementedError());

  @override
  Future<ConversationDetail> get(String id) =>
      Future<ConversationDetail>.error(UnimplementedError());

  @override
  Future<void> saveTurn(
    String conversationId,
    ConversationTurn turn,
  ) =>
      Future<void>.error(UnimplementedError());
}

class _PagedRepository implements ConversationRepository {
  _PagedRepository({this.delayDelete = false});

  final bool delayDelete;
  final Completer<void> _deleteGate = Completer<void>();
  final List<String?> requestedCursors = <String?>[];

  void finishDelete() {
    if (!_deleteGate.isCompleted) _deleteGate.complete();
  }

  @override
  Future<ConversationPage> list({String? cursor}) async {
    requestedCursors.add(cursor);
    if (cursor == 'page-2') {
      return ConversationPage(items: <ConversationSummary>[_summary('second')]);
    }
    return ConversationPage(
      items: <ConversationSummary>[_summary('first')],
      nextCursor: 'page-2',
    );
  }

  @override
  Future<void> delete(String conversationId) async {
    if (delayDelete) await _deleteGate.future;
  }

  @override
  Future<ConversationDetail> complete(String conversationId) =>
      Future<ConversationDetail>.error(UnimplementedError());

  @override
  Future<RealtimeGrant> createSession(TutorPreferences preferences) =>
      Future<RealtimeGrant>.error(UnimplementedError());

  @override
  Future<ConversationDetail> get(String id) =>
      Future<ConversationDetail>.error(UnimplementedError());

  @override
  Future<void> saveTurn(
    String conversationId,
    ConversationTurn turn,
  ) =>
      Future<void>.error(UnimplementedError());
}

ConversationSummary _summary(String id) => ConversationSummary(
      id: 'conversation_$id',
      status: ConversationStatus.completed,
      preferences: TutorPreferences(
        targetLanguage: TargetLanguage.spanish,
        level: ProficiencyLevel.intermediate,
        topic: '${id[0].toUpperCase()}${id.substring(1)} session',
        correctionStyle: CorrectionStyle.gentle,
      ),
      createdAt: DateTime.utc(2026, 7, 16),
      turnCount: 2,
    );
