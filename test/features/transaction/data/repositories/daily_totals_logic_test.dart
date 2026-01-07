import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyTotals 데이터 그룹화 로직', () {
    test('사용자별 거래 데이터가 일별로 올바르게 그룹화되어야 한다', () {
      // Given: Supabase에서 가져온 거래 데이터 (모의 데이터)
      final transactions = [
        {
          'date': '2026-01-15',
          'user_id': 'user1',
          'amount': 50000,
          'type': 'income',
          'profiles': {'color': '#A8D8EA'},
        },
        {
          'date': '2026-01-15',
          'user_id': 'user2',
          'amount': 20000,
          'type': 'expense',
          'profiles': {'color': '#FFB6A3'},
        },
        {
          'date': '2026-01-15',
          'user_id': 'user1',
          'amount': 10000,
          'type': 'expense',
          'profiles': {'color': '#A8D8EA'},
        },
      ];

      // When: 데이터 그룹화 로직 실행
      final dailyTotals = <DateTime, Map<String, dynamic>>{};

      for (final transaction in transactions) {
        final dateStr = transaction['date'] as String;
        final date = DateTime.parse(dateStr);
        final dateKey = DateTime(date.year, date.month, date.day);

        final userId = transaction['user_id'] as String;
        final amount = transaction['amount'] as int;
        final type = transaction['type'] as String;

        final profileData = transaction['profiles'] as Map<String, dynamic>?;
        final userColor = (profileData != null && profileData['color'] != null)
            ? profileData['color'] as String
            : '#A8D8EA';

        // 날짜별 데이터 초기화
        dailyTotals.putIfAbsent(dateKey, () => {
          'users': <String, Map<String, dynamic>>{},
          'totalIncome': 0,
          'totalExpense': 0,
        });

        final dayData = dailyTotals[dateKey]!;
        final users = dayData['users'] as Map<String, Map<String, dynamic>>;

        // 사용자별 데이터 초기화
        users.putIfAbsent(userId, () => {
          'income': 0,
          'expense': 0,
          'color': userColor,
        });

        // 금액 누적
        if (type == 'income') {
          users[userId]!['income'] = (users[userId]!['income'] as int) + amount;
          dayData['totalIncome'] = (dayData['totalIncome'] as int) + amount;
        } else {
          users[userId]!['expense'] = (users[userId]!['expense'] as int) + amount;
          dayData['totalExpense'] = (dayData['totalExpense'] as int) + amount;
        }
      }

      // Then: 결과 검증
      final expectedDate = DateTime(2026, 1, 15);
      expect(dailyTotals.containsKey(expectedDate), true);

      final dayData = dailyTotals[expectedDate]!;
      expect(dayData['totalIncome'], 50000);
      expect(dayData['totalExpense'], 30000);

      final users = dayData['users'] as Map<String, Map<String, dynamic>>;
      expect(users.length, 2);

      // user1 검증
      expect(users['user1']!['income'], 50000);
      expect(users['user1']!['expense'], 10000);
      expect(users['user1']!['color'], '#A8D8EA');

      // user2 검증
      expect(users['user2']!['income'], 0);
      expect(users['user2']!['expense'], 20000);
      expect(users['user2']!['color'], '#FFB6A3');
    });

    test('profile에 color가 없는 경우 기본 색상을 사용해야 한다', () {
      // Given: color가 null인 프로필 데이터
      final transactions = [
        {
          'date': '2026-01-15',
          'user_id': 'user1',
          'amount': 10000,
          'type': 'expense',
          'profiles': null,
        },
        {
          'date': '2026-01-15',
          'user_id': 'user2',
          'amount': 20000,
          'type': 'expense',
          'profiles': {'color': null},
        },
      ];

      // When: 데이터 그룹화 로직 실행
      final dailyTotals = <DateTime, Map<String, dynamic>>{};

      for (final transaction in transactions) {
        final dateStr = transaction['date'] as String;
        final date = DateTime.parse(dateStr);
        final dateKey = DateTime(date.year, date.month, date.day);

        final userId = transaction['user_id'] as String;
        final amount = transaction['amount'] as int;
        final type = transaction['type'] as String;

        final profileData = transaction['profiles'] as Map<String, dynamic>?;
        final userColor = (profileData != null && profileData['color'] != null)
            ? profileData['color'] as String
            : '#A8D8EA';

        dailyTotals.putIfAbsent(dateKey, () => {
          'users': <String, Map<String, dynamic>>{},
          'totalIncome': 0,
          'totalExpense': 0,
        });

        final dayData = dailyTotals[dateKey]!;
        final users = dayData['users'] as Map<String, Map<String, dynamic>>;

        users.putIfAbsent(userId, () => {
          'income': 0,
          'expense': 0,
          'color': userColor,
        });

        if (type == 'income') {
          users[userId]!['income'] = (users[userId]!['income'] as int) + amount;
          dayData['totalIncome'] = (dayData['totalIncome'] as int) + amount;
        } else {
          users[userId]!['expense'] = (users[userId]!['expense'] as int) + amount;
          dayData['totalExpense'] = (dayData['totalExpense'] as int) + amount;
        }
      }

      // Then: 기본 색상이 적용되어야 함
      final expectedDate = DateTime(2026, 1, 15);
      final dayData = dailyTotals[expectedDate]!;
      final users = dayData['users'] as Map<String, Map<String, dynamic>>;

      expect(users['user1']!['color'], '#A8D8EA');
      expect(users['user2']!['color'], '#A8D8EA');
    });

    test('여러 날짜의 거래가 올바르게 그룹화되어야 한다', () {
      // Given: 여러 날짜에 걸친 거래 데이터
      final transactions = [
        {
          'date': '2026-01-15',
          'user_id': 'user1',
          'amount': 50000,
          'type': 'income',
          'profiles': {'color': '#A8D8EA'},
        },
        {
          'date': '2026-01-16',
          'user_id': 'user1',
          'amount': 30000,
          'type': 'expense',
          'profiles': {'color': '#A8D8EA'},
        },
        {
          'date': '2026-01-16',
          'user_id': 'user2',
          'amount': 10000,
          'type': 'income',
          'profiles': {'color': '#FFB6A3'},
        },
      ];

      // When: 데이터 그룹화 로직 실행
      final dailyTotals = <DateTime, Map<String, dynamic>>{};

      for (final transaction in transactions) {
        final dateStr = transaction['date'] as String;
        final date = DateTime.parse(dateStr);
        final dateKey = DateTime(date.year, date.month, date.day);

        final userId = transaction['user_id'] as String;
        final amount = transaction['amount'] as int;
        final type = transaction['type'] as String;

        final profileData = transaction['profiles'] as Map<String, dynamic>?;
        final userColor = (profileData != null && profileData['color'] != null)
            ? profileData['color'] as String
            : '#A8D8EA';

        dailyTotals.putIfAbsent(dateKey, () => {
          'users': <String, Map<String, dynamic>>{},
          'totalIncome': 0,
          'totalExpense': 0,
        });

        final dayData = dailyTotals[dateKey]!;
        final users = dayData['users'] as Map<String, Map<String, dynamic>>;

        users.putIfAbsent(userId, () => {
          'income': 0,
          'expense': 0,
          'color': userColor,
        });

        if (type == 'income') {
          users[userId]!['income'] = (users[userId]!['income'] as int) + amount;
          dayData['totalIncome'] = (dayData['totalIncome'] as int) + amount;
        } else {
          users[userId]!['expense'] = (users[userId]!['expense'] as int) + amount;
          dayData['totalExpense'] = (dayData['totalExpense'] as int) + amount;
        }
      }

      // Then: 각 날짜별로 올바르게 그룹화되어야 함
      expect(dailyTotals.length, 2);

      final date1 = DateTime(2026, 1, 15);
      final date2 = DateTime(2026, 1, 16);

      expect(dailyTotals[date1]!['totalIncome'], 50000);
      expect(dailyTotals[date1]!['totalExpense'], 0);

      expect(dailyTotals[date2]!['totalIncome'], 10000);
      expect(dailyTotals[date2]!['totalExpense'], 30000);
    });

    test('totalIncome과 totalExpense가 사용자별 합계와 일치해야 한다', () {
      // Given: 여러 사용자의 거래 데이터
      final transactions = [
        {
          'date': '2026-01-15',
          'user_id': 'user1',
          'amount': 100000,
          'type': 'income',
          'profiles': {'color': '#A8D8EA'},
        },
        {
          'date': '2026-01-15',
          'user_id': 'user2',
          'amount': 50000,
          'type': 'income',
          'profiles': {'color': '#FFB6A3'},
        },
        {
          'date': '2026-01-15',
          'user_id': 'user1',
          'amount': 20000,
          'type': 'expense',
          'profiles': {'color': '#A8D8EA'},
        },
        {
          'date': '2026-01-15',
          'user_id': 'user2',
          'amount': 30000,
          'type': 'expense',
          'profiles': {'color': '#FFB6A3'},
        },
      ];

      // When: 데이터 그룹화 로직 실행
      final dailyTotals = <DateTime, Map<String, dynamic>>{};

      for (final transaction in transactions) {
        final dateStr = transaction['date'] as String;
        final date = DateTime.parse(dateStr);
        final dateKey = DateTime(date.year, date.month, date.day);

        final userId = transaction['user_id'] as String;
        final amount = transaction['amount'] as int;
        final type = transaction['type'] as String;

        final profileData = transaction['profiles'] as Map<String, dynamic>?;
        final userColor = (profileData != null && profileData['color'] != null)
            ? profileData['color'] as String
            : '#A8D8EA';

        dailyTotals.putIfAbsent(dateKey, () => {
          'users': <String, Map<String, dynamic>>{},
          'totalIncome': 0,
          'totalExpense': 0,
        });

        final dayData = dailyTotals[dateKey]!;
        final users = dayData['users'] as Map<String, Map<String, dynamic>>;

        users.putIfAbsent(userId, () => {
          'income': 0,
          'expense': 0,
          'color': userColor,
        });

        if (type == 'income') {
          users[userId]!['income'] = (users[userId]!['income'] as int) + amount;
          dayData['totalIncome'] = (dayData['totalIncome'] as int) + amount;
        } else {
          users[userId]!['expense'] = (users[userId]!['expense'] as int) + amount;
          dayData['totalExpense'] = (dayData['totalExpense'] as int) + amount;
        }
      }

      // Then: 총합이 사용자별 합계와 일치해야 함
      final expectedDate = DateTime(2026, 1, 15);
      final dayData = dailyTotals[expectedDate]!;
      final users = dayData['users'] as Map<String, Map<String, dynamic>>;

      // 사용자별 income 합계 계산
      var calculatedIncome = 0;
      var calculatedExpense = 0;
      for (final userData in users.values) {
        calculatedIncome += userData['income'] as int;
        calculatedExpense += userData['expense'] as int;
      }

      expect(dayData['totalIncome'], calculatedIncome);
      expect(dayData['totalIncome'], 150000);

      expect(dayData['totalExpense'], calculatedExpense);
      expect(dayData['totalExpense'], 50000);
    });
  });
}
