enum TargetLanguage {
  spanish('es', 'Spanish', 'Hola'),
  english('en', 'English', 'Hello'),
  catalan('ca', 'Catalan', 'Hola');

  const TargetLanguage(this.wireValue, this.label, this.greeting);
  final String wireValue;
  final String label;
  final String greeting;

  static TargetLanguage fromWire(Object? value) => values.firstWhere(
        (item) => item.wireValue == value,
        orElse: () => throw FormatException(
          'target_language must be one of es, en, or ca.',
        ),
      );
}

enum ProficiencyLevel {
  beginner('beginner', 'Beginner'),
  intermediate('intermediate', 'Intermediate'),
  advanced('advanced', 'Advanced');

  const ProficiencyLevel(this.wireValue, this.label);
  final String wireValue;
  final String label;

  static ProficiencyLevel fromWire(Object? value) => values.firstWhere(
        (item) => item.wireValue == value,
        orElse: () => throw FormatException(
          'level must be beginner, intermediate, or advanced.',
        ),
      );
}

enum CorrectionStyle {
  gentle('gentle', 'Gentle nudges', 'Keep the conversation flowing'),
  immediate('immediate', 'Correct me now', 'Fix mistakes as they happen'),
  summary('summary', 'End summary', 'Save corrections for the recap');

  const CorrectionStyle(this.wireValue, this.label, this.description);
  final String wireValue;
  final String label;
  final String description;

  static CorrectionStyle fromWire(Object? value) => values.firstWhere(
        (item) => item.wireValue == value,
        orElse: () => throw FormatException(
          'correction_style must be gentle, immediate, or summary.',
        ),
      );
}

class TutorPreferences {
  const TutorPreferences({
    required this.targetLanguage,
    required this.level,
    required this.topic,
    required this.correctionStyle,
  });

  const TutorPreferences.defaults()
      : targetLanguage = TargetLanguage.spanish,
        level = ProficiencyLevel.intermediate,
        topic = 'Everyday life',
        correctionStyle = CorrectionStyle.gentle;

  final TargetLanguage targetLanguage;
  final ProficiencyLevel level;
  final String topic;
  final CorrectionStyle correctionStyle;

  TutorPreferences copyWith({
    TargetLanguage? targetLanguage,
    ProficiencyLevel? level,
    String? topic,
    CorrectionStyle? correctionStyle,
  }) =>
      TutorPreferences(
        targetLanguage: targetLanguage ?? this.targetLanguage,
        level: level ?? this.level,
        topic: topic ?? this.topic,
        correctionStyle: correctionStyle ?? this.correctionStyle,
      );

  Map<String, Object> toJson() => <String, Object>{
        'target_language': targetLanguage.wireValue,
        'level': level.wireValue,
        'topic': topic,
        'correction_style': correctionStyle.wireValue,
      };

  factory TutorPreferences.fromJson(Map<String, Object?> json) =>
      TutorPreferences(
        targetLanguage: TargetLanguage.fromWire(json['target_language']),
        level: ProficiencyLevel.fromWire(json['level']),
        topic: _requiredString(json, 'topic'),
        correctionStyle: CorrectionStyle.fromWire(json['correction_style']),
      );
}

enum ConversationStatus {
  active,
  completed;

  static ConversationStatus fromWire(Object? value) => switch (value) {
        'active' => active,
        'completed' => completed,
        _ => throw const FormatException(
            'status must be active or completed.',
          ),
      };
}

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.status,
    required this.preferences,
    required this.createdAt,
    required this.turnCount,
    this.completedAt,
  });

  final String id;
  final ConversationStatus status;
  final TutorPreferences preferences;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int turnCount;

  factory ConversationSummary.fromJson(Map<String, Object?> json) {
    final preferencesJson = _requiredMap(json, 'preferences');
    final createdAt = _requiredDate(json, 'created_at');
    _requiredDate(json, 'updated_at');
    return ConversationSummary(
      id: _requiredString(json, 'id'),
      status: ConversationStatus.fromWire(json['status']),
      preferences: TutorPreferences.fromJson(preferencesJson),
      createdAt: createdAt,
      completedAt: _date(json['completed_at']),
      turnCount: _requiredNonNegativeInt(json, 'turn_count'),
    );
  }
}

enum TurnRole {
  user,
  assistant;

  static TurnRole fromWire(Object? value) => switch (value) {
        'user' => user,
        'assistant' => assistant,
        _ => throw const FormatException('role must be user or assistant.'),
      };
}

class ConversationTurn {
  const ConversationTurn({
    required this.id,
    required this.role,
    required this.text,
    required this.occurredAt,
  });

  final String id;
  final TurnRole role;
  final String text;
  final DateTime occurredAt;

  Map<String, Object> toJson() => <String, Object>{
        'role': role.name,
        'text': text,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
      };

  factory ConversationTurn.fromJson(Map<String, Object?> json) =>
      ConversationTurn(
        id: _requiredString(json, 'id'),
        role: TurnRole.fromWire(json['role']),
        text: _requiredString(json, 'text'),
        occurredAt: _requiredDate(json, 'occurred_at'),
      );
}

class SessionFeedback {
  const SessionFeedback({
    required this.summary,
    required this.strengths,
    required this.corrections,
    required this.nextSteps,
    required this.generatedAt,
  });

  final String summary;
  final List<String> strengths;
  final List<FeedbackCorrection> corrections;
  final List<String> nextSteps;
  final DateTime generatedAt;

  factory SessionFeedback.fromJson(Map<String, Object?> json) =>
      SessionFeedback(
        summary: _requiredString(json, 'summary'),
        strengths: _requiredStringList(json, 'strengths'),
        corrections: _requiredList(json, 'corrections')
            .map((item) => FeedbackCorrection.fromJson(_expectMap(item)))
            .toList(growable: false),
        nextSteps: _requiredStringList(json, 'next_steps'),
        generatedAt: _requiredDate(json, 'generated_at'),
      );
}

class FeedbackCorrection {
  const FeedbackCorrection({
    required this.original,
    required this.corrected,
    required this.explanation,
  });

  final String original;
  final String corrected;
  final String explanation;

  factory FeedbackCorrection.fromJson(Map<String, Object?> json) =>
      FeedbackCorrection(
        original: _requiredString(json, 'original'),
        corrected: _requiredString(json, 'corrected'),
        explanation: _requiredString(json, 'explanation'),
      );
}

class ConversationDetail {
  const ConversationDetail({
    required this.conversation,
    required this.turns,
    this.feedback,
  });

  final ConversationSummary conversation;
  final List<ConversationTurn> turns;
  final SessionFeedback? feedback;

  factory ConversationDetail.fromJson(Map<String, Object?> json) {
    final conversationJson = _requiredMap(json, 'conversation');
    final turnsJson = _requiredList(json, 'turns');
    if (!json.containsKey('feedback')) {
      throw const FormatException('feedback is required.');
    }
    final rawFeedback = json['feedback'];
    final feedbackJson = _map(rawFeedback);
    if (rawFeedback != null && feedbackJson == null) {
      throw const FormatException('feedback must be an object or null.');
    }
    return ConversationDetail(
      conversation: ConversationSummary.fromJson(conversationJson),
      turns: turnsJson
          .map((item) => ConversationTurn.fromJson(_expectMap(item)))
          .toList(growable: false),
      feedback:
          feedbackJson == null ? null : SessionFeedback.fromJson(feedbackJson),
    );
  }
}

class ConversationPage {
  const ConversationPage({required this.items, this.nextCursor});
  final List<ConversationSummary> items;
  final String? nextCursor;
}

class RealtimeGrant {
  const RealtimeGrant({
    required this.conversation,
    required this.transport,
    required this.endpoint,
    required this.model,
    this.clientSecret,
    this.expiresAt,
  });

  final ConversationSummary conversation;
  final String transport;
  final Uri endpoint;
  final String model;
  final String? clientSecret;
  final DateTime? expiresAt;

  bool get canUseWebRtc => transport == 'webrtc' && clientSecret != null;

  factory RealtimeGrant.fromJson(Map<String, Object?> json) {
    final conversationJson = _requiredMap(json, 'conversation');
    if (!json.containsKey('client_secret')) {
      throw const FormatException('client_secret is required.');
    }
    final rawSecret = json['client_secret'];
    final secretJson = _map(rawSecret);
    if (rawSecret != null && secretJson == null) {
      throw const FormatException('client_secret must be an object or null.');
    }
    final realtimeJson = _requiredMap(json, 'realtime');
    final transport = _requiredString(realtimeJson, 'transport');
    if (transport != 'demo' && transport != 'webrtc') {
      throw const FormatException('realtime.transport is unsupported.');
    }
    final endpoint = Uri.tryParse(_requiredString(realtimeJson, 'endpoint'));
    if (endpoint == null || !endpoint.hasScheme || endpoint.host.isEmpty) {
      throw const FormatException('realtime.endpoint must be an absolute URI.');
    }
    if (transport == 'webrtc' && endpoint.scheme != 'https') {
      throw const FormatException('WebRTC endpoint must use HTTPS.');
    }
    if (transport == 'webrtc' && secretJson == null) {
      throw const FormatException('WebRTC sessions require client_secret.');
    }
    if (transport == 'demo' && secretJson != null) {
      throw const FormatException(
          'Demo sessions cannot contain client_secret.');
    }
    final expiresAt = secretJson?['expires_at'];
    if (secretJson != null &&
        (expiresAt is! num ||
            expiresAt.toInt() != expiresAt ||
            expiresAt <= 0)) {
      throw const FormatException(
        'client_secret.expires_at must be a Unix timestamp.',
      );
    }
    return RealtimeGrant(
      conversation: ConversationSummary.fromJson(conversationJson),
      transport: transport,
      endpoint: endpoint,
      model: _requiredString(realtimeJson, 'model'),
      clientSecret:
          secretJson == null ? null : _requiredString(secretJson, 'value'),
      expiresAt: expiresAt is num
          ? DateTime.fromMillisecondsSinceEpoch(
              expiresAt.toInt() * 1000,
              isUtc: true,
            )
          : null,
    );
  }
}

Map<String, Object?>? _map(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = _map(json[key]);
  if (value == null) throw FormatException('$key must be an object.');
  return value;
}

Map<String, Object?> _expectMap(Object? value) {
  final map = _map(value);
  if (map == null) throw const FormatException('Expected an object.');
  return map;
}

List<Object?> _requiredList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List<Object?>) throw FormatException('$key must be an array.');
  return value;
}

List<String> _requiredStringList(Map<String, Object?> json, String key) =>
    _requiredList(json, key).map((item) {
      if (item is! String || item.trim().isEmpty) {
        throw FormatException('$key must contain non-empty strings.');
      }
      return item;
    }).toList(growable: false);

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _requiredNonNegativeInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! num || value.toInt() != value || value < 0) {
    throw FormatException('$key must be a non-negative integer.');
  }
  return value.toInt();
}

DateTime _requiredDate(Map<String, Object?> json, String key) {
  final value = _date(json[key]);
  if (value == null) throw FormatException('$key must be an ISO-8601 date.');
  return value;
}
