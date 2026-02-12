import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/calendar_view_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CalendarViewProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('CalendarViewModeNotifier', () {
      test('기본값은 monthly이다', () {
        // Given
        SharedPreferences.setMockInitialValues({});

        // When
        final notifier = CalendarViewModeNotifier();

        // Then
        expect(notifier.state, equals(CalendarViewMode.monthly));
      });

      test('setViewMode는 뷰 모드를 변경하고 저장한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({});
        final notifier = CalendarViewModeNotifier();

        // When
        await notifier.setViewMode(CalendarViewMode.weekly);

        // Then
        expect(notifier.state, equals(CalendarViewMode.weekly));

        // SharedPreferences에 저장되었는지 확인
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('calendar_view_mode'), equals('weekly'));
      });

      test('daily로 변경할 수 있다', () async {
        // Given
        SharedPreferences.setMockInitialValues({});
        final notifier = CalendarViewModeNotifier();

        // When
        await notifier.setViewMode(CalendarViewMode.daily);

        // Then
        expect(notifier.state, equals(CalendarViewMode.daily));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('calendar_view_mode'), equals('daily'));
      });
    });

    group('WeekStartDayNotifier', () {
      test('기본값은 sunday이다', () {
        // Given
        SharedPreferences.setMockInitialValues({});

        // When
        final notifier = WeekStartDayNotifier();

        // Then
        expect(notifier.state, equals(WeekStartDay.sunday));
      });

      test('setWeekStartDay는 주 시작일을 변경하고 저장한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({});
        final notifier = WeekStartDayNotifier();

        // When
        await notifier.setWeekStartDay(WeekStartDay.monday);

        // Then
        expect(notifier.state, equals(WeekStartDay.monday));

        // SharedPreferences에 저장되었는지 확인
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('week_start_day'), equals('monday'));
      });

      test('setWeekStartDay를 sunday로 설정하면 저장된다', () async {
        // Given
        SharedPreferences.setMockInitialValues({});
        final notifier = WeekStartDayNotifier();

        // When
        await notifier.setWeekStartDay(WeekStartDay.sunday);

        // Then
        expect(notifier.state, equals(WeekStartDay.sunday));

        // SharedPreferences에 저장되었는지 확인
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('week_start_day'), equals('sunday'));
      });
    });

    group('getWeekRangeFor', () {
      test('일요일 시작인 경우 주 범위를 올바르게 계산한다', () {
        // Given: 2024년 1월 10일 (수요일)
        final date = DateTime(2024, 1, 10);
        const weekStartDay = WeekStartDay.sunday;

        // When
        final range = getWeekRangeFor(date, weekStartDay);

        // Then: 2024년 1월 7일 (일요일) ~ 1월 13일 (토요일)
        expect(range.start, equals(DateTime(2024, 1, 7)));
        expect(range.end, equals(DateTime(2024, 1, 13)));
      });

      test('월요일 시작인 경우 주 범위를 올바르게 계산한다', () {
        // Given: 2024년 1월 10일 (수요일)
        final date = DateTime(2024, 1, 10);
        const weekStartDay = WeekStartDay.monday;

        // When
        final range = getWeekRangeFor(date, weekStartDay);

        // Then: 2024년 1월 8일 (월요일) ~ 1월 14일 (일요일)
        expect(range.start, equals(DateTime(2024, 1, 8)));
        expect(range.end, equals(DateTime(2024, 1, 14)));
      });

      test('일요일 자체가 주 시작일인 경우', () {
        // Given: 2024년 1월 7일 (일요일)
        final date = DateTime(2024, 1, 7);
        const weekStartDay = WeekStartDay.sunday;

        // When
        final range = getWeekRangeFor(date, weekStartDay);

        // Then: 2024년 1월 7일 (일요일) ~ 1월 13일 (토요일)
        expect(range.start, equals(DateTime(2024, 1, 7)));
        expect(range.end, equals(DateTime(2024, 1, 13)));
      });

      test('월요일 자체가 주 시작일인 경우', () {
        // Given: 2024년 1월 8일 (월요일)
        final date = DateTime(2024, 1, 8);
        const weekStartDay = WeekStartDay.monday;

        // When
        final range = getWeekRangeFor(date, weekStartDay);

        // Then: 2024년 1월 8일 (월요일) ~ 1월 14일 (일요일)
        expect(range.start, equals(DateTime(2024, 1, 8)));
        expect(range.end, equals(DateTime(2024, 1, 14)));
      });
    });
  });
}

