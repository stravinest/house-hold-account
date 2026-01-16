import 'package:intl/intl.dart';

/// NumberFormat 인스턴스를 캐싱하여 반복적인 객체 생성을 방지하는 유틸리티 클래스
///
/// NumberFormat 객체 생성은 로케일 데이터 조회를 수반하므로 비교적 비용이 큽니다.
/// 특히 캘린더 뷰처럼 빌드가 자주 발생하는 위젯에서 매번 새 인스턴스를 생성하면
/// 불필요한 가비지 컬렉션 압력을 유발합니다.
///
/// 이 클래스는 자주 사용되는 NumberFormat 패턴을 정적 캐시 인스턴스로 제공하여
/// 성능을 최적화합니다.
class NumberFormatUtils {
  // 인스턴스 생성 방지를 위한 private 생성자
  NumberFormatUtils._();

  // 천 단위 구분 기호 패턴
  static const _currencyPattern = '#,###';

  /// 천 단위 구분 기호가 있는 숫자 포맷터
  ///
  /// 패턴: #,### (예: 1234567 → 1,234,567)
  /// 캘린더 셀, 통계 위젯, 검색 결과 등에서 금액 표시에 사용
  static final NumberFormat currency = NumberFormat(_currencyPattern);
}
