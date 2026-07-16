import 'package:flutter_test/flutter_test.dart';
import 'package:nia_flutter/data/repositories.dart';
import 'package:nia_flutter/domain/models.dart';

void main() {
  test('demo repository supports the full conversation lifecycle', () async {
    final repository = DemoRepository();
    const preferences = TutorPreferences.defaults();

    final grant = await repository.createSession(preferences);
    expect(grant.transport, 'demo');
    expect(grant.clientSecret, isNull);

    final turn = ConversationTurn(
      id: 'turn-1',
      role: TurnRole.user,
      text: 'Hola',
      occurredAt: DateTime.utc(2026, 7, 15),
    );
    await repository.saveTurn(grant.conversation.id, turn);
    await repository.saveTurn(grant.conversation.id, turn);

    final active = await repository.get(grant.conversation.id);
    expect(active.turns, hasLength(1), reason: 'turn PUTs are idempotent');

    final completed = await repository.complete(grant.conversation.id);
    expect(completed.conversation.status, ConversationStatus.completed);
    expect(completed.feedback?.corrections, isNotEmpty);

    await repository.delete(grant.conversation.id);
    expect(
      () => repository.get(grant.conversation.id),
      throwsA(isA<Exception>()),
    );
  });
}
