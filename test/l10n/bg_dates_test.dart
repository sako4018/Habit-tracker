import 'package:flutter_test/flutter_test.dart';
import 'package:streakly/l10n/bg_dates.dart';

void main() {
  group('BgDates.days', () {
    test('единствено число', () => expect(BgDates.days(1), '1 ден'));
    test('множествено число', () => expect(BgDates.days(5), '5 дни'));
    test('нула е множествено', () => expect(BgDates.days(0), '0 дни'));
  });

  group('BgDates.remaining', () {
    test('глаголът се съгласува по число', () {
      expect(BgDates.remaining(1), 'остава 1');
      expect(BgDates.remaining(2), 'остават 2');
    });
  });

  group('форматиране на дати', () {
    test('monthYear е с главна буква', () {
      expect(BgDates.monthYear(DateTime(2026, 9, 8)), 'Септември 2026');
    });

    test('weekdayDayMonth е с малка буква в изречение', () {
      expect(
        BgDates.weekdayDayMonth(DateTime(2026, 9, 8)),
        'вторник, 8 септември',
      );
    });

    test('понеделник е първи в седмицата', () {
      expect(BgDates.weekdays.first, 'понеделник');
      expect(BgDates.weekdayLetters.first, 'П');
      expect(BgDates.weekdayLetters.length, 7);
    });
  });
}
