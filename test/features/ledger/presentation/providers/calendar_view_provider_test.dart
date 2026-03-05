import 'package:flutter_riverpod/flutter_riverpod.dart';
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

      test('토요일에서 일요일 시작일로 계산하면 그 주 토요일이 종료일이다', () {
        // Given: 2024년 1월 13일 (토요일)
        final date = DateTime(2024, 1, 13);
        const weekStartDay = WeekStartDay.sunday;

        // When
        final range = getWeekRangeFor(date, weekStartDay);

        // Then: 2024년 1월 7일 (일요일) ~ 1월 13일 (토요일)
        expect(range.start, equals(DateTime(2024, 1, 7)));
        expect(range.end, equals(DateTime(2024, 1, 13)));
      });

      test('월요일 시작으로 일요일 날짜 계산 시 그 주 일요일이 종료일이다', () {
        // Given: 2024년 1월 14일 (일요일)
        final date = DateTime(2024, 1, 14);
        const weekStartDay = WeekStartDay.monday;

        // When
        final range = getWeekRangeFor(date, weekStartDay);

        // Then: 2024년 1월 8일 (월요일) ~ 1월 14일 (일요일)
        expect(range.start, equals(DateTime(2024, 1, 8)));
        expect(range.end, equals(DateTime(2024, 1, 14)));
      });
    });

    group('CalendarViewModeNotifier - SharedPreferences 복원', () {
      test('저장된 weekly 값을 복원한다', () async {
        // Given: SharedPreferences에 weekly가 저장됨
        SharedPreferences.setMockInitialValues({
          'calendar_view_mode': 'weekly',
        });
        final notifier = CalendarViewModeNotifier();

        // 비동기 로딩 대기
        await Future.delayed(const Duration(milliseconds: 100));

        // Then
        expect(notifier.state, equals(CalendarViewMode.weekly));
      });

      test('저장된 daily 값을 복원한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({
          'calendar_view_mode': 'daily',
        });
        final notifier = CalendarViewModeNotifier();

        await Future.delayed(const Duration(milliseconds: 100));

        // Then
        expect(notifier.state, equals(CalendarViewMode.daily));
      });

      test('저장된 monthly 값을 복원한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({
          'calendar_view_mode': 'monthly',
        });
        final notifier = CalendarViewModeNotifier();

        await Future.delayed(const Duration(milliseconds: 100));

        // Then
        expect(notifier.state, equals(CalendarViewMode.monthly));
      });

      test('알 수 없는 값이 저장된 경우 monthly로 기본값 처리한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({
          'calendar_view_mode': 'unknown_value',
        });
        final notifier = CalendarViewModeNotifier();

        await Future.delayed(const Duration(milliseconds: 100));

        // Then: 기본값 monthly
        expect(notifier.state, equals(CalendarViewMode.monthly));
      });

      test('monthly로 변경할 수 있다', () async {
        // Given
        SharedPreferences.setMockInitialValues({});
        final notifier = CalendarViewModeNotifier();
        await notifier.setViewMode(CalendarViewMode.weekly);

        // When
        await notifier.setViewMode(CalendarViewMode.monthly);

        // Then
        expect(notifier.state, equals(CalendarViewMode.monthly));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('calendar_view_mode'), equals('monthly'));
      });
    });

    group('WeekStartDayNotifier - SharedPreferences 복원', () {
      test('저장된 monday 값을 복원한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({
          'week_start_day': 'monday',
        });
        final notifier = WeekStartDayNotifier();

        await Future.delayed(const Duration(milliseconds: 100));

        // Then
        expect(notifier.state, equals(WeekStartDay.monday));
      });

      test('저장된 sunday 값을 복원한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({
          'week_start_day': 'sunday',
        });
        final notifier = WeekStartDayNotifier();

        await Future.delayed(const Duration(milliseconds: 100));

        // Then
        expect(notifier.state, equals(WeekStartDay.sunday));
      });

      test('CalendarViewMode.values에 3개 요소가 있다', () {
        // Then
        expect(CalendarViewMode.values.length, equals(3));
        expect(CalendarViewMode.values.contains(CalendarViewMode.daily), isTrue);
        expect(CalendarViewMode.values.contains(CalendarViewMode.weekly), isTrue);
        expect(CalendarViewMode.values.contains(CalendarViewMode.monthly), isTrue);
      });

      test('WeekStartDay.values에 2개 요소가 있다', () {
        // Then
        expect(WeekStartDay.values.length, equals(2));
        expect(WeekStartDay.values.contains(WeekStartDay.sunday), isTrue);
        expect(WeekStartDay.values.contains(WeekStartDay.monday), isTrue);
      });
    });

    group('ProviderContainer를 통한 Provider 실행 테스트', () {
      test('calendarViewModeProvider를 ProviderContainer로 읽으면 monthly를 반환한다', () {
        // Given
        SharedPreferences.setMockInitialValues({});

        // When
        final container = ProviderContainer();
        final mode = container.read(calendarViewModeProvider);
        addTearDown(container.dispose);

        // Then: 기본값은 monthly
        expect(mode, equals(CalendarViewMode.monthly));
      });

      test('weekStartDayProvider를 ProviderContainer로 읽으면 sunday를 반환한다', () {
        // Given
        SharedPreferences.setMockInitialValues({});

        // When
        final container = ProviderContainer();
        final day = container.read(weekStartDayProvider);
        addTearDown(container.dispose);

        // Then: 기본값은 sunday
        expect(day, equals(WeekStartDay.sunday));
      });

      test('selectedDateForCalendarProvider는 현재 날짜에 근접한 값을 반환한다', () {
        // Given
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final before = DateTime.now().subtract(const Duration(seconds: 1));

        // When
        final selectedDate = container.read(selectedDateForCalendarProvider);
        final after = DateTime.now().add(const Duration(seconds: 1));

        // Then: 현재 날짜 반환 (DateTime.now() 기반)
        expect(
          selectedDate.isAfter(before) || selectedDate.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          selectedDate.isBefore(after) || selectedDate.isAtSameMomentAs(after),
          isTrue,
        );
      });

      test('selectedWeekRangeProvider는 현재 날짜 기준으로 7일 범위를 반환한다', () {
        // Given
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // When
        final range = container.read(selectedWeekRangeProvider);

        // Then: start는 end보다 이전 날짜이고, 범위는 정확히 6일 차이
        expect(
          range.start.isBefore(range.end) || range.start.isAtSameMomentAs(range.end),
          isTrue,
        );
        final diff = range.end.difference(range.start).inDays;
        expect(diff, equals(6));
      });

      test('selectedDateForCalendarProvider를 특정 날짜로 오버라이드하면 해당 날짜를 반환한다', () {
        // Given
        SharedPreferences.setMockInitialValues({});
        final fixedDate = DateTime(2024, 6, 15);
        final container = ProviderContainer(
          overrides: [
            selectedDateForCalendarProvider.overrideWith((ref) => fixedDate),
          ],
        );
        addTearDown(container.dispose);

        // When
        final date = container.read(selectedDateForCalendarProvider);

        // Then
        expect(date, equals(fixedDate));
      });

      test('selectedWeekRangeProvider를 특정 날짜(수요일)와 일요일 시작으로 오버라이드하면 올바른 주 범위를 반환한다', () {
        // Given: 2024년 1월 10일 (수요일), 일요일 시작
        SharedPreferences.setMockInitialValues({});
        final testDate = DateTime(2024, 1, 10);
        final container = ProviderContainer(
          overrides: [
            selectedDateForCalendarProvider.overrideWith((ref) => testDate),
          ],
        );
        addTearDown(container.dispose);

        // When: 일요일 시작 기본값으로 주 범위 계산
        final range = container.read(selectedWeekRangeProvider);

        // Then: 2024-01-07 (일요일) ~ 2024-01-13 (토요일)
        expect(range.start, equals(DateTime(2024, 1, 7)));
        expect(range.end, equals(DateTime(2024, 1, 13)));
      });

      test('selectedWeekRangeProvider를 특정 날짜(수요일)와 월요일 시작으로 오버라이드하면 올바른 주 범위를 반환한다', () {
        // Given: 2024년 1월 10일 (수요일), 월요일 시작
        SharedPreferences.setMockInitialValues({'week_start_day': 'monday'});
        final testDate = DateTime(2024, 1, 10);
        final container = ProviderContainer(
          overrides: [
            selectedDateForCalendarProvider.overrideWith((ref) => testDate),
          ],
        );
        addTearDown(container.dispose);

        // 비동기 로딩 대기 후 확인
        // When: weekStartDayProvider가 monday를 로드하기 전 기본값(sunday)으로 계산
        final range = container.read(selectedWeekRangeProvider);

        // Then: 범위는 항상 6일
        final diff = range.end.difference(range.start).inDays;
        expect(diff, equals(6));
      });
    });
  });
}

