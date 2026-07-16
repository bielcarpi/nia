import 'package:flutter_test/flutter_test.dart';
import 'package:nia_flutter/domain/models.dart';

void main() {
  group('domain models', () {
    test('preferences preserve the public API wire contract', () {
      const preferences = TutorPreferences(
        targetLanguage: TargetLanguage.catalan,
        level: ProficiencyLevel.advanced,
        topic: 'Job interview',
        correctionStyle: CorrectionStyle.summary,
      );

      expect(preferences.toJson(), <String, Object>{
        'target_language': 'ca',
        'level': 'advanced',
        'topic': 'Job interview',
        'correction_style': 'summary',
      });
      final roundTrip = TutorPreferences.fromJson(preferences.toJson());
      expect(roundTrip.targetLanguage, TargetLanguage.catalan);
      expect(roundTrip.correctionStyle, CorrectionStyle.summary);
    });

    test('feedback parses corrections and next steps without data loss', () {
      final detail = ConversationDetail.fromJson(<String, Object?>{
        'conversation': <String, Object?>{
          'id': 'conversation-1',
          'status': 'completed',
          'created_at': '2026-07-15T10:00:00Z',
          'turn_count': 2,
        },
        'turns': <Object>[],
        'feedback': <String, Object?>{
          'summary': 'Clear and confident.',
          'strengths': <Object>['Natural pacing'],
          'corrections': <Object>[
            <String, Object>{
              'original': 'Yo soy bien.',
              'corrected': 'Estoy bien.',
              'explanation': 'Use estar for temporary states.',
            },
          ],
          'next_steps': <Object>['Practise greetings'],
          'generated_at': '2026-07-15T10:05:00Z',
        },
      });

      expect(detail.feedback?.strengths, <String>['Natural pacing']);
      expect(detail.feedback?.corrections.single.corrected, 'Estoy bien.');
      expect(detail.feedback?.nextSteps.single, 'Practise greetings');
      expect(detail.feedback?.generatedAt.isUtc, isTrue);
    });
  });
}
