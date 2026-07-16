import 'package:nia_flutter/domain/models.dart';

abstract final class DemoTutor {
  static String greeting(TutorPreferences preferences) =>
      switch (preferences.targetLanguage) {
        TargetLanguage.spanish =>
          '¡Hola! Hablemos de ${preferences.topic.toLowerCase()}. ¿Cómo empezarías?',
        TargetLanguage.english =>
          'Hello! Let’s talk about ${preferences.topic.toLowerCase()}. How would you begin?',
        TargetLanguage.catalan =>
          'Hola! Parlem de ${preferences.topic.toLowerCase()}. Com començaries?',
      };

  static String reply(TutorPreferences preferences, String learnerText) {
    final excerpt = _excerpt(learnerText);
    final wordCount = learnerText.trim().split(RegExp(r'\s+')).length;
    final invite = wordCount < 5;
    final correction = _knownCorrectionForText(
      preferences.targetLanguage,
      learnerText,
    );
    if (correction != null &&
        preferences.correctionStyle != CorrectionStyle.summary) {
      return _correctionReply(preferences, correction);
    }
    return _defaultReply(preferences.targetLanguage, excerpt, invite);
  }

  static String _defaultReply(
    TargetLanguage language,
    String excerpt,
    bool invite,
  ) =>
      switch (language) {
        TargetLanguage.spanish => invite
            ? 'He entendido “$excerpt”. Añade dónde o cuándo ocurre para completar la idea.'
            : 'Has explicado “$excerpt” con claridad. ¿Qué detalle añadirías después?',
        TargetLanguage.english => invite
            ? 'I understood “$excerpt”. Add where or when it happens to complete the thought.'
            : 'You explained “$excerpt” clearly. What detail would you add next?',
        TargetLanguage.catalan => invite
            ? 'He entès “$excerpt”. Afegeix on o quan passa per completar la idea.'
            : 'Has explicat “$excerpt” amb claredat. Quin detall hi afegiries després?',
      };

  static String _correctionReply(
    TutorPreferences preferences,
    FeedbackCorrection correction,
  ) {
    final immediate = preferences.correctionStyle == CorrectionStyle.immediate;
    return switch (preferences.targetLanguage) {
      TargetLanguage.spanish => immediate
          ? 'Una corrección: en este caso, di “${correction.corrected}”. Inténtalo otra vez.'
          : 'Te he entendido. Una forma más natural es “${correction.corrected}”. ¿Quieres ampliar la idea?',
      TargetLanguage.english => immediate
          ? 'One correction: say “${correction.corrected}” here. Try it once more.'
          : 'I understood you. A more natural form is “${correction.corrected}”. Would you add another detail?',
      TargetLanguage.catalan => immediate
          ? 'Una correcció: en aquest cas, digues “${correction.corrected}”. Torna-ho a provar.'
          : 'T’he entès. Una forma més natural és “${correction.corrected}”. Hi afegiries un altre detall?',
    };
  }

  static SessionFeedback feedback({
    required TutorPreferences preferences,
    required List<ConversationTurn> turns,
    required DateTime generatedAt,
  }) {
    final learnerTurns = turns
        .where((turn) => turn.role == TurnRole.user)
        .toList(growable: false);
    if (learnerTurns.isEmpty) {
      throw ArgumentError('A learner turn is required for demo feedback.');
    }
    final latest = learnerTurns.last.text.trim();
    final correction =
        _knownCorrection(preferences.targetLanguage, learnerTurns);
    final language = preferences.targetLanguage.label;
    final count = learnerTurns.length;
    return SessionFeedback(
      summary: 'You completed $count $language learner '
          '${count == 1 ? 'turn' : 'turns'} about ${preferences.topic}.',
      strengths: <String>[
        'You kept the exchange moving for $count learner '
            '${count == 1 ? 'turn' : 'turns'}.',
        'Your latest idea was specific: “${_excerpt(latest)}”.',
      ],
      corrections: correction == null
          ? const <FeedbackCorrection>[]
          : <FeedbackCorrection>[correction],
      nextSteps: _nextSteps(preferences),
      generatedAt: generatedAt.toUtc(),
    );
  }

  static FeedbackCorrection? _knownCorrection(
    TargetLanguage language,
    List<ConversationTurn> turns,
  ) {
    for (final turn in turns) {
      final correction = _knownCorrectionForText(language, turn.text);
      if (correction != null) return correction;
    }
    return null;
  }

  static FeedbackCorrection? _knownCorrectionForText(
    TargetLanguage language,
    String learnerText,
  ) {
    final text = learnerText.trim().toLowerCase();
    return switch (language) {
      TargetLanguage.spanish when text.contains('yo soy bien') =>
        const FeedbackCorrection(
          original: 'Yo soy bien.',
          corrected: 'Estoy bien.',
          explanation: 'Use “estar” for a temporary state or feeling.',
        ),
      TargetLanguage.english when text.contains('i am agree') =>
        const FeedbackCorrection(
          original: 'I am agree.',
          corrected: 'I agree.',
          explanation: '“Agree” is a verb, so it does not take “am”.',
        ),
      TargetLanguage.catalan
          when text.contains('jo soc bé') || text.contains('jo sóc bé') =>
        const FeedbackCorrection(
          original: 'Jo soc bé.',
          corrected: 'Estic bé.',
          explanation: 'Fes servir “estar” per expressar com et trobes.',
        ),
      _ => null,
    };
  }

  static List<String> _nextSteps(TutorPreferences preferences) =>
      switch (preferences.targetLanguage) {
        TargetLanguage.spanish => <String>[
            'Responde otra vez añadiendo cuándo, dónde y por qué.',
            'Practica una pregunta de seguimiento sobre ${preferences.topic.toLowerCase()}.',
          ],
        TargetLanguage.english => <String>[
            'Answer again with when, where, and why.',
            'Practise a follow-up question about ${preferences.topic.toLowerCase()}.',
          ],
        TargetLanguage.catalan => <String>[
            'Torna a respondre afegint quan, on i per què.',
            'Practica una pregunta de seguiment sobre ${preferences.topic.toLowerCase()}.',
          ],
      };

  static String _excerpt(String text) {
    final singleLine = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (singleLine.length <= 84) return singleLine;
    return '${singleLine.substring(0, 81)}…';
  }
}
