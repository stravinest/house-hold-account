import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 캘린더 뷰 모드
enum CalendarViewMode {
  daily, // 일별
  weekly, // 주별
  monthly, // 월별
}

/// 주의 시작일
enum WeekStartDay {
  sunday, // 일요일
  monday, // 월요일
}

// 뷰 모드 Provider (SharedPreferences에서 로드, 기본값: monthly)
final calendarViewModeProvider =
    StateNotifierProvider<CalendarViewModeNotifier, CalendarViewMode>((ref) {
      return CalendarViewModeNotifier();
    });

class CalendarViewModeNotifier extends StateNotifier<CalendarViewMode> {
  static const _key = 'calendar_view_mode';

  CalendarViewModeNotifier() : super(CalendarViewMode.monthly) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      switch (value) {
        case 'daily':
          state = CalendarViewMode.daily;
          break;
        case 'weekly':
          state = CalendarViewMode.weekly;
          break;
        case 'monthly':
        default:
          state = CalendarViewMode.monthly;
          break;
      }
    }
  }

  Future<void> setViewMode(CalendarViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
    state = mode;
  }
}

// 주 시작일 Provider (SharedPreferences에서 로드)
final weekStartDayProvider =
    StateNotifierProvider<WeekStartDayNotifier, WeekStartDay>((ref) {
      return WeekStartDayNotifier();
    });

class WeekStartDayNotifier extends StateNotifier<WeekStartDay> {
  static const _key = 'week_start_day';

  WeekStartDayNotifier() : super(WeekStartDay.sunday) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'monday') {
      state = WeekStartDay.monday;
    } else {
      state = WeekStartDay.sunday;
    }
  }

  Future<void> setWeekStartDay(WeekStartDay day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      day == WeekStartDay.monday ? 'monday' : 'sunday',
    );
    state = day;
  }
}

/// 선택된 주의 시작일과 종료일을 계산하는 Provider
final selectedWeekRangeProvider = Provider<({DateTime start, DateTime end})>((
  ref,
) {
  final selectedDate = ref.watch(selectedDateForCalendarProvider);
  final weekStartDay = ref.watch(weekStartDayProvider);

  return _getWeekRange(selectedDate, weekStartDay);
});

/// 선택된 날짜 (캘린더 뷰용, 기존 selectedDateProvider와 연동)
final selectedDateForCalendarProvider = Provider<DateTime>((ref) {
  // 기존 transaction_provider의 selectedDateProvider를 사용
  // 여기서는 직접 참조하지 않고, home_page에서 연동
  return DateTime.now();
});

/// 주의 범위를 계산하는 유틸리티 함수
({DateTime start, DateTime end}) _getWeekRange(
  DateTime date,
  WeekStartDay weekStartDay,
) {
  final int targetWeekday = weekStartDay == WeekStartDay.sunday
      ? DateTime.sunday
      : DateTime.monday;

  // 현재 날짜의 요일
  int currentWeekday = date.weekday;

  // 일요일 시작인 경우, DateTime.weekday는 월=1, 일=7이므로 조정 필요
  int daysToSubtract;
  if (weekStartDay == WeekStartDay.sunday) {
    // 일요일(7)을 0으로 취급
    daysToSubtract = currentWeekday == DateTime.sunday ? 0 : currentWeekday;
  } else {
    // 월요일 시작
    daysToSubtract = currentWeekday - DateTime.monday;
  }

  final start = DateTime(date.year, date.month, date.day - daysToSubtract);
  final end = start.add(const Duration(days: 6));

  return (start: start, end: end);
}

/// 주어진 날짜와 주 시작일로 주 범위를 계산
({DateTime start, DateTime end}) getWeekRangeFor(
  DateTime date,
  WeekStartDay weekStartDay,
) {
  return _getWeekRange(date, weekStartDay);
}
