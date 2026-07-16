enum TargetLanguage {
  spanish('es', 'Spanish', 'Hola'),
  english('en', 'English', 'Hello'),
  catalan('ca', 'Catalan', 'Hola');

  const TargetLanguage(this.wireValue, this.label, this.greeting);
  final String wireValue;
  final String label;
  final String greeting;

  static TargetLanguage fromWire(String? value) => values.firstWhere(
        (item) => item.wireValue == value,
        orElse: () => TargetLanguage.spanish,
      );
}

enum ProficiencyLevel {
  beginner('beginner', 'Beginner'),
  intermediate('intermediate', 'Intermediate'),
  advanced('advanced', 'Advanced');

  const ProficiencyLevel(this.wireValue, this.label);
  final String wireValue;
  final String label;

  static ProficiencyLevel fromWire(String? value) => values.firstWhere(
        (item) => item.wireValue == value,
        orElse: () => ProficiencyLevel.intermediate,
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

  static CorrectionStyle fromWire(String? value) => values.firstWhere(
        (item) => item.wireValue == value,
        orElse: () => CorrectionStyle.gentle,
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
        targetLanguage: TargetLanguage.fromWire(
          json['target_language'] as String?,
        ),
        level: ProficiencyLevel.fromWire(json['level'] as String?),
        topic: (json['topic'] as String?)?.trim().isNotEmpty == true
            ? (json['topic']! as String)
            : 'Everyday life',
        correctionStyle: CorrectionStyle.fromWire(
          json['correction_style'] as String?,
        ),
      );
}

enum ConversationStatus {
  active,
  completed;

  static ConversationStatus fromWire(String? value) =>
      value == 'completed' ? completed : active;
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
    final preferencesJson = _map(json['preferences']);
    return ConversationSummary(
      id: json['id'] as String? ?? json['conversation_id'] as String? ?? '',
      status: ConversationStatus.fromWire(json['status'] as String?),
      preferences: preferencesJson == null
          ? const TutorPreferences.defaults()
          : TutorPreferences.fromJson(preferencesJson),
      createdAt: _date(json['created_at']) ?? DateTime.now().toUtc(),
      completedAt: _date(json['completed_at']),
      turnCount: (json['turn_count'] as num?)?.toInt() ?? 0,
    );
  }
}

enum TurnRole {
  user,
  assistant;

  static TurnRole fromWire(String? value) =>
      value == 'assistant' ? assistant : user;
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
        id: json['id'] as String? ?? json['turn_id'] as String? ?? '',
        role: TurnRole.fromWire(json['role'] as String?),
        text: json['text'] as String? ?? '',
        occurredAt: _date(json['occurred_at']) ?? DateTime.now().toUtc(),
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
        summary: json['summary'] as String? ?? '',
        strengths: _strings(json['strengths']),
        corrections:
            (json['corrections'] as List<Object?>? ?? const <Object?>[])
                .map(_map)
                .whereType<Map<String, Object?>>()
                .map(FeedbackCorrection.fromJson)
                .toList(growable: false),
        nextSteps: _strings(json['next_steps']),
        generatedAt: _date(json['generated_at']) ?? DateTime.now().toUtc(),
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
        original: json['original'] as String? ?? '',
        corrected: json['corrected'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
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
    final conversationJson = _map(json['conversation']) ?? json;
    final turnsJson = json['turns'] as List<Object?>? ?? const <Object?>[];
    final feedbackJson = _map(json['feedback']);
    return ConversationDetail(
      conversation: ConversationSummary.fromJson(conversationJson),
      turns: turnsJson
          .map(_map)
          .whereType<Map<String, Object?>>()
          .map(ConversationTurn.fromJson)
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
    final conversationJson = _map(json['conversation']);
    final secretJson = _map(json['client_secret']);
    final realtimeJson = _map(json['realtime']) ?? const <String, Object?>{};
    final expiresAt = secretJson?['expires_at'];
    return RealtimeGrant(
      conversation: ConversationSummary.fromJson(
        conversationJson ?? const <String, Object?>{},
      ),
      transport: realtimeJson['transport'] as String? ?? 'demo',
      endpoint: Uri.parse(
        realtimeJson['endpoint'] as String? ??
            'https://api.openai.com/v1/realtime/calls',
      ),
      model: realtimeJson['model'] as String? ?? 'gpt-realtime-2.1',
      clientSecret: secretJson?['value'] as String?,
      expiresAt: expiresAt is num
          ? DateTime.fromMillisecondsSinceEpoch(
              expiresAt.toInt() * 1000,
              isUtc: true,
            )
          : _date(expiresAt),
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

List<String> _strings(Object? value) => value is List<Object?>
    ? value.whereType<String>().toList(growable: false)
    : const <String>[];
