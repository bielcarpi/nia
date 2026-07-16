import 'dart:collection';

import 'package:nia_flutter/core/api/api_client.dart';
import 'package:nia_flutter/domain/models.dart';

abstract interface class PreferencesRepository {
  Future<TutorPreferences> load();
  Future<TutorPreferences> save(TutorPreferences preferences);
}

abstract interface class ConversationRepository {
  Future<RealtimeGrant> createSession(TutorPreferences preferences);
  Future<ConversationPage> list({String? cursor});
  Future<ConversationDetail> get(String id);
  Future<void> saveTurn(String conversationId, ConversationTurn turn);
  Future<ConversationDetail> complete(String conversationId);
  Future<void> delete(String conversationId);
}

class ApiPreferencesRepository implements PreferencesRepository {
  const ApiPreferencesRepository(this._api);
  final ApiClient _api;

  @override
  Future<TutorPreferences> load() async {
    final json = asJsonMap(await _api.get('/api/v1/me/preferences'));
    if (json == null) throw _invalidResponse();
    return TutorPreferences.fromJson(asJsonMap(json['preferences']) ?? json);
  }

  @override
  Future<TutorPreferences> save(TutorPreferences preferences) async {
    final json = asJsonMap(
      await _api.patch('/api/v1/me/preferences', body: preferences.toJson()),
    );
    if (json == null) throw _invalidResponse();
    return TutorPreferences.fromJson(asJsonMap(json['preferences']) ?? json);
  }
}

class ApiConversationRepository implements ConversationRepository {
  const ApiConversationRepository(this._api);
  final ApiClient _api;

  @override
  Future<RealtimeGrant> createSession(TutorPreferences preferences) async {
    final json = asJsonMap(
      await _api.post(
        '/api/v1/realtime/sessions',
        body: <String, Object>{'preferences': preferences.toJson()},
      ),
    );
    if (json == null) throw _invalidResponse();
    return RealtimeGrant.fromJson(json);
  }

  @override
  Future<ConversationPage> list({String? cursor}) async {
    final json = asJsonMap(
      await _api.get(
        '/api/v1/conversations',
        query: cursor == null ? null : <String, String>{'cursor': cursor},
      ),
    );
    if (json == null) throw _invalidResponse();
    final rawItems = json['items'];
    if (rawItems is! List<Object?>) throw _invalidResponse();
    return ConversationPage(
      items: rawItems
          .map(asJsonMap)
          .whereType<Map<String, Object?>>()
          .map(ConversationSummary.fromJson)
          .toList(growable: false),
      nextCursor: json['next_cursor'] as String?,
    );
  }

  @override
  Future<ConversationDetail> get(String id) async {
    final json = asJsonMap(
      await _api.get('/api/v1/conversations/${Uri.encodeComponent(id)}'),
    );
    if (json == null) throw _invalidResponse();
    return ConversationDetail.fromJson(json);
  }

  @override
  Future<void> saveTurn(String conversationId, ConversationTurn turn) async {
    await _api.put(
      '/api/v1/conversations/${Uri.encodeComponent(conversationId)}'
      '/turns/${Uri.encodeComponent(turn.id)}',
      body: turn.toJson(),
    );
  }

  @override
  Future<ConversationDetail> complete(String conversationId) async {
    final json = asJsonMap(
      await _api.post(
        '/api/v1/conversations/${Uri.encodeComponent(conversationId)}'
        '/complete',
      ),
    );
    if (json == null) throw _invalidResponse();
    return ConversationDetail.fromJson(json);
  }

  @override
  Future<void> delete(String conversationId) => _api.delete(
        '/api/v1/conversations/${Uri.encodeComponent(conversationId)}',
      );
}

ApiException _invalidResponse() => const ApiException(
      code: 'invalid_response',
      message: 'Nia received an unexpected server response.',
    );

class DemoRepository implements PreferencesRepository, ConversationRepository {
  DemoRepository() {
    final completed = ConversationSummary(
      id: 'demo-coffee',
      status: ConversationStatus.completed,
      preferences: const TutorPreferences(
        targetLanguage: TargetLanguage.spanish,
        level: ProficiencyLevel.intermediate,
        topic: 'Ordering at a café',
        correctionStyle: CorrectionStyle.gentle,
      ),
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      completedAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      turnCount: 4,
    );
    _conversations[completed.id] = ConversationDetail(
      conversation: completed,
      turns: <ConversationTurn>[
        ConversationTurn(
          id: 'demo-turn-1',
          role: TurnRole.assistant,
          text: '¡Buenos días! ¿Qué te gustaría tomar?',
          occurredAt: completed.createdAt,
        ),
        ConversationTurn(
          id: 'demo-turn-2',
          role: TurnRole.user,
          text: 'Quiero un café con leche, por favor.',
          occurredAt: completed.createdAt.add(const Duration(seconds: 8)),
        ),
        ConversationTurn(
          id: 'demo-turn-3',
          role: TurnRole.assistant,
          text: 'Perfecto. ¿Lo quieres grande o pequeño?',
          occurredAt: completed.createdAt.add(const Duration(seconds: 13)),
        ),
        ConversationTurn(
          id: 'demo-turn-4',
          role: TurnRole.user,
          text: 'Pequeño, gracias.',
          occurredAt: completed.createdAt.add(const Duration(seconds: 18)),
        ),
      ],
      feedback: SessionFeedback(
        summary: 'A confident, natural café exchange with clear requests.',
        strengths: <String>[
          'Polite use of “por favor” and “gracias”',
          'Correct noun phrase: “un café con leche”',
        ],
        corrections: <FeedbackCorrection>[
          FeedbackCorrection(
            original: 'Pequeño, gracias.',
            corrected: 'Uno pequeño, gracias.',
            explanation: 'Use “uno” to refer back to the coffee naturally.',
          ),
        ],
        nextSteps: <String>[
          'Practise asking for the bill.',
          'Try the same exchange while paying by card.',
        ],
        generatedAt: DateTime.utc(2026, 7, 15, 12),
      ),
    );
  }

  TutorPreferences _preferences = const TutorPreferences.defaults();
  final Map<String, ConversationDetail> _conversations =
      <String, ConversationDetail>{};
  int _id = 1;

  @override
  Future<TutorPreferences> load() async => _preferences;

  @override
  Future<TutorPreferences> save(TutorPreferences preferences) async {
    _preferences = preferences;
    return preferences;
  }

  @override
  Future<RealtimeGrant> createSession(TutorPreferences preferences) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final now = DateTime.now().toUtc();
    final summary = ConversationSummary(
      id: 'demo-session-${_id++}',
      status: ConversationStatus.active,
      preferences: preferences,
      createdAt: now,
      turnCount: 0,
    );
    _conversations[summary.id] = ConversationDetail(
      conversation: summary,
      turns: const <ConversationTurn>[],
    );
    return RealtimeGrant(
      conversation: summary,
      transport: 'demo',
      endpoint: Uri.parse('demo://local'),
      model: 'deterministic-demo',
    );
  }

  @override
  Future<ConversationPage> list({String? cursor}) async {
    final items = _conversations.values
        .map((detail) => detail.conversation)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ConversationPage(items: UnmodifiableListView(items));
  }

  @override
  Future<ConversationDetail> get(String id) async {
    final detail = _conversations[id];
    if (detail == null) {
      throw const ApiException(
        code: 'not_found',
        message: 'That conversation no longer exists.',
        statusCode: 404,
      );
    }
    return detail;
  }

  @override
  Future<void> saveTurn(String conversationId, ConversationTurn turn) async {
    final detail = await get(conversationId);
    if (detail.turns.any((item) => item.id == turn.id)) return;
    final turns = <ConversationTurn>[...detail.turns, turn];
    _conversations[conversationId] = ConversationDetail(
      conversation: ConversationSummary(
        id: detail.conversation.id,
        status: detail.conversation.status,
        preferences: detail.conversation.preferences,
        createdAt: detail.conversation.createdAt,
        completedAt: detail.conversation.completedAt,
        turnCount: turns.length,
      ),
      turns: turns,
      feedback: detail.feedback,
    );
  }

  @override
  Future<ConversationDetail> complete(String conversationId) async {
    final detail = await get(conversationId);
    final completed = ConversationDetail(
      conversation: ConversationSummary(
        id: detail.conversation.id,
        status: ConversationStatus.completed,
        preferences: detail.conversation.preferences,
        createdAt: detail.conversation.createdAt,
        completedAt: DateTime.now().toUtc(),
        turnCount: detail.turns.length,
      ),
      turns: detail.turns,
      feedback: SessionFeedback(
        summary: 'You kept the exchange moving and communicated clearly.',
        strengths: <String>[
          'You responded with complete thoughts',
          'Your vocabulary matched the selected topic',
        ],
        corrections: <FeedbackCorrection>[
          FeedbackCorrection(
            original: 'Me gustaría practicar una situación real.',
            corrected: 'Quisiera practicar una situación real.',
            explanation: '“Quisiera” is a polished alternative for requests.',
          ),
        ],
        nextSteps: <String>[
          'Repeat the topic at advanced level.',
          'Aim for faster, complete responses.',
        ],
        generatedAt: DateTime.utc(2026, 7, 15, 12),
      ),
    );
    _conversations[conversationId] = completed;
    return completed;
  }

  @override
  Future<void> delete(String conversationId) async {
    _conversations.remove(conversationId);
  }
}
