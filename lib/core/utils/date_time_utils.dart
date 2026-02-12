import 'package:intl/intl.dart';

/// Supabase 타임존 처리를 위한 유틸리티
///
/// Supabase TIMESTAMPTZ 컬럼은 UTC로 저장되므로:
/// - DB에 저장할 때: [nowUtcIso] 사용 (로컬 -> UTC 변환)
/// - DB에서 읽어 UI에 표시할 때: [toLocalDateTime] 사용 (UTC -> 로컬 변환)
class DateTimeUtils {
  DateTimeUtils._();

  // -- DB 저장용 --

  /// 현재 시각을 UTC ISO 8601 문자열로 반환 (Supabase TIMESTAMPTZ 저장용)
  ///
  /// 예: '2026-02-10T05:30:00.000Z'
  static String nowUtcIso() => DateTime.now().toUtc().toIso8601String();

  /// DateTime을 UTC ISO 8601 문자열로 변환 (Supabase TIMESTAMPTZ 저장용)
  static String toUtcIso(DateTime dt) => dt.toUtc().toIso8601String();

  // -- UI 표시용 --

  /// UTC DateTime을 로컬 시간으로 변환 (UI 표시용)
  ///
  /// Supabase에서 받은 TIMESTAMPTZ 값은 UTC로 파싱되므로
  /// UI에 표시할 때 반드시 이 메서드를 사용해야 한다.
  static DateTime toLocalDateTime(DateTime utcDateTime) =>
      utcDateTime.toLocal();

  /// UTC DateTime을 로컬 시간으로 변환 후 포맷팅 (UI 표시용)
  static String formatLocal(DateTime utcDateTime, DateFormat format) =>
      format.format(utcDateTime.toLocal());

  // -- 날짜 전용 (DATE 타입) --

  /// DateTime에서 날짜 부분만 ISO 문자열로 추출 (Supabase DATE 컬럼용)
  ///
  /// 예: '2026-02-10'
  @Deprecated('toLocalDateOnly()를 사용하세요. UTC DateTime 전달 시 날짜가 달라질 수 있습니다.')
  static String toDateOnly(DateTime dt) =>
      dt.toIso8601String().split('T').first;

  /// DATE 문자열을 로컬 자정 DateTime으로 파싱 (Supabase DATE 컬럼 읽기용)
  /// "2026-02-12" -> DateTime(2026, 2, 12) (로컬 자정, UTC 아님)
  static DateTime parseLocalDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// DateTime에서 로컬 날짜만 추출 (Supabase DATE 컬럼 저장용)
  /// 로컬 시간 기준으로 날짜를 추출하여 KST/UTC 혼동 방지
  static String toLocalDateOnly(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
