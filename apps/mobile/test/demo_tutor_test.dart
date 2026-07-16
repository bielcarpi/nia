import 'package:flutter_test/flutter_test.dart';
import 'package:nia_flutter/domain/demo_tutor.dart';
import 'package:nia_flutter/domain/models.dart';

void main() {
  test('scripted replies quote the learner instead of returning canned praise',
      () {
    const preferences = TutorPreferences.defaults();
    final first = DemoTutor.reply(preferences, 'Viajo en tren mañana.');
    final second = DemoTutor.reply(preferences, 'Trabajo desde casa hoy.');

    expect(first, contains('Viajo en tren mañana.'));
    expect(second, contains('Trabajo desde casa hoy.'));
    expect(first, isNot(second));
  });

  test('feedback follows the selected language and saved learner transcript',
      () {
    final generatedAt = DateTime.utc(2026, 7, 16, 10);
    const preferences = TutorPreferences(
      targetLanguage: TargetLanguage.english,
      level: ProficiencyLevel.intermediate,
      topic: 'Meeting a colleague',
      correctionStyle: CorrectionStyle.gentle,
    );
    final feedback = DemoTutor.feedback(
      preferences: preferences,
      turns: <ConversationTurn>[
        ConversationTurn(
          id: 'turn_english_1234',
          role: TurnRole.user,
          text: 'I am agree with the plan.',
          occurredAt: generatedAt,
        ),
      ],
      generatedAt: generatedAt,
    );

    expect(feedback.summary, contains('English'));
    expect(feedback.strengths.join(' '), contains('I am agree with the plan.'));
    expect(feedback.corrections.single.corrected, 'I agree.');
    expect(feedback.nextSteps.first, startsWith('Answer again'));
    expect(feedback.generatedAt, generatedAt);
  });

  test('correction style changes when a known mistake is surfaced', () {
    const base = TutorPreferences(
      targetLanguage: TargetLanguage.english,
      level: ProficiencyLevel.intermediate,
      topic: 'Making plans',
      correctionStyle: CorrectionStyle.gentle,
    );

    final gentle = DemoTutor.reply(base, 'I am agree with that.');
    final immediate = DemoTutor.reply(
      base.copyWith(correctionStyle: CorrectionStyle.immediate),
      'I am agree with that.',
    );
    final summary = DemoTutor.reply(
      base.copyWith(correctionStyle: CorrectionStyle.summary),
      'I am agree with that.',
    );

    expect(gentle, contains('A more natural form is “I agree.”'));
    expect(immediate, contains('One correction'));
    expect(immediate, contains('Try it once more'));
    expect(summary, isNot(contains('I agree.')));
    expect(summary, contains('I am agree with that.'));
  });
}
