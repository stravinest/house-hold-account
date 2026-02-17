import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarDayCell hasData 로직 단위 테스트', () {
    // calendar_day_cell.dart의 hasData 판별 로직을 단위 테스트
    // hasData = income > 0 || expense > 0 || hasAsset || hasUserExpense

    /// hasData 판별 로직을 재현하는 헬퍼 함수
    bool calculateHasData(Map<String, dynamic>? totals) {
      final income = totals?['totalIncome'] ?? 0;
      final expense = totals?['totalExpense'] ?? 0;

      final rawUsers = totals?['users'];
      final usersForAsset = rawUsers is Map
          ? Map<String, dynamic>.from(rawUsers)
          : <String, dynamic>{};

      final hasAsset = usersForAsset.values.any((u) {
        final userData = u is Map
            ? Map<String, dynamic>.from(u)
            : <String, dynamic>{};
        return (userData['asset'] as int? ?? 0) > 0;
      });

      final hasUserExpense = usersForAsset.values.any((u) {
        final userData = u is Map
            ? Map<String, dynamic>.from(u)
            : <String, dynamic>{};
        return (userData['expense'] as int? ?? 0) > 0;
      });

      return income > 0 || expense > 0 || hasAsset || hasUserExpense;
    }

    test('totalExpense가 0이지만 사용자별 expense가 있으면 hasData가 true이다 (고정비만 있는 날)', () {
      // Given: 고정비 제외로 totalExpense=0이지만, 사용자별 expense에는 금액이 누적된 상태
      final totals = {
        'totalIncome': 0,
        'totalExpense': 0, // 고정비가 제외되어 0
        'users': {
          'user1': {
            'income': 0,
            'expense': 50000, // 사용자별에는 고정비 금액이 누적되어 있음
            'asset': 0,
            'color': '#A8D8EA',
          },
        },
      };

      // When & Then
      expect(calculateHasData(totals), true,
          reason: '사용자별 expense가 있으면 hasData는 true여야 한다');
    });

    test('모든 값이 0이면 hasData가 false이다', () {
      // Given: 모든 금액이 0인 데이터
      final totals = {
        'totalIncome': 0,
        'totalExpense': 0,
        'users': {
          'user1': {
            'income': 0,
            'expense': 0,
            'asset': 0,
            'color': '#A8D8EA',
          },
        },
      };

      // When & Then
      expect(calculateHasData(totals), false,
          reason: '모든 값이 0이면 hasData는 false여야 한다');
    });

    test('totals가 null이면 hasData가 false이다', () {
      // Given: totals가 null (해당 날짜에 거래가 없는 경우)
      // When & Then
      expect(calculateHasData(null), false,
          reason: 'totals가 null이면 hasData는 false여야 한다');
    });

    test('asset만 있으면 hasData가 true이다', () {
      // Given: 자산 거래만 있는 데이터
      final totals = {
        'totalIncome': 0,
        'totalExpense': 0,
        'users': {
          'user1': {
            'income': 0,
            'expense': 0,
            'asset': 100000,
            'color': '#A8D8EA',
          },
        },
      };

      // When & Then
      expect(calculateHasData(totals), true,
          reason: 'asset이 있으면 hasData는 true여야 한다');
    });

    test('income만 있으면 hasData가 true이다', () {
      // Given: 수입만 있는 데이터
      final totals = {
        'totalIncome': 200000,
        'totalExpense': 0,
        'users': {
          'user1': {
            'income': 200000,
            'expense': 0,
            'asset': 0,
            'color': '#FFB6A3',
          },
        },
      };

      // When & Then
      expect(calculateHasData(totals), true,
          reason: 'income이 있으면 hasData는 true여야 한다');
    });
  });
}
