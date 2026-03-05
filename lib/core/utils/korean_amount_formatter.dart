import 'package:intl/intl.dart';

/// 숫자를 한글 단위 문자열로 변환
/// 예: 150000000 -> '1억 5,000만원'
///     35000000  -> '3,500만원'
///     10000     -> '1만원'
///     5000      -> '5,000원'
String formatKoreanAmount(int amount) {
  if (amount <= 0) return '';

  final formatter = NumberFormat('#,###');
  final eok = amount ~/ 100000000; // 억
  final man = (amount % 100000000) ~/ 10000; // 만
  final rest = amount % 10000; // 나머지

  if (eok > 0 && man > 0) {
    return '${formatter.format(eok)}억 ${formatter.format(man)}만원';
  } else if (eok > 0) {
    if (rest > 0) {
      return '${formatter.format(eok)}억 ${formatter.format(rest)}원';
    }
    return '${formatter.format(eok)}억원';
  } else if (man > 0) {
    if (rest > 0) {
      return '${formatter.format(man)}만 ${formatter.format(rest)}원';
    }
    return '${formatter.format(man)}만원';
  } else {
    return '${formatter.format(rest)}원';
  }
}
