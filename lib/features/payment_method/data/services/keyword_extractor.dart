/// 거래 제목에서 카테고리 매핑용 키워드를 추출하는 유틸리티
class KeywordExtractor {
  /// 거래 제목을 공백 기준으로 분리하여 의미 있는 키워드만 반환
  ///
  /// - 1글자 단어 제외
  /// - 순수 숫자 제외 (금액, 수량 등)
  /// - 날짜 패턴 제외 (2026-03-03, 03/03 등)
  /// - 시간 패턴 제외 (14:30 등)
  /// - 금액(원) 패턴 제외 (5000원 등)
  /// - 중복 제거
  static List<String> extract(String? title) {
    if (title == null || title.trim().isEmpty) return [];
    return title
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .where((w) => !RegExp(r'^\d+$').hasMatch(w))
        .where((w) =>
            !RegExp(r'^\d{2,4}[./-]\d{1,2}([./-]\d{1,4})?$').hasMatch(w))
        .where((w) => !RegExp(r'^\d{1,2}:\d{2}$').hasMatch(w))
        .where((w) => !RegExp(r'^\d+원$').hasMatch(w))
        .toSet()
        .toList();
  }
}
