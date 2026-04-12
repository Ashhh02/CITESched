import 'package:citesched_server/src/services/nlp_service.dart';
import 'package:test/test.dart';

void main() {
  group('NLPService pure helpers', () {
    test('normalizes queries', () {
      expect(
        NLPService.normalizeQueryForTest('  Schedule, Today!!  '),
        'schedule today',
      );
    });

    test('detects forbidden keywords', () {
      expect(
        NLPService.containsForbiddenKeywordsForTest('delete database now'),
        isTrue,
      );
      expect(
        NLPService.containsForbiddenKeywordsForTest('show my timetable'),
        isFalse,
      );
    });

    test('parses time tokens', () {
      expect(NLPService.parseTimeTokenForTest('8:30 am'), 510);
      expect(NLPService.parseTimeTokenForTest('12 pm'), 12 * 60);
      expect(NLPService.parseTimeTokenForTest('12 am'), 0);
    });

    test('extracts simple time ranges', () {
      final between = NLPService.extractTimeRangeForTest(
        'between 8 am and 10 am',
      );
      expect(between, isNotNull);
      expect(between!.start, 8 * 60);
      expect(between.end, 10 * 60);

      final morning = NLPService.extractTimeRangeForTest('morning classes');
      expect(morning, isNotNull);
      expect(morning!.start, 7 * 60);
      expect(morning.end, 12 * 60);
    });
  });
}
