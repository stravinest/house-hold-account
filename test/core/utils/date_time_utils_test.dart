import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/utils/date_time_utils.dart';

void main() {
  group('DateTimeUtils', () {
    group('parseLocalDate - DATE 컬럼 읽기', () {
      test('날짜 문자열을 로컬 자정 DateTime으로 파싱한다', () {
        final result = DateTimeUtils.parseLocalDate('2026-02-12');

        expect(result.year, 2026);
        expect(result.month, 2);
        expect(result.day, 12);
        expect(result.hour, 0);
        expect(result.minute, 0);
        expect(result.second, 0);
        expect(result.isUtc, false, reason: 'UTC가 아닌 로컬 시간이어야 한다');
      });

      test('DateTime.parse와 동일하게 로컬로 파싱하지만 명시적이고 안전하다', () {
        // DateTime.parse("2026-02-12")도 로컬로 해석하지만,
        // "2026-02-12T00:00:00.000Z" 형태는 UTC로 해석됨
        // parseLocalDate는 항상 로컬로 파싱하므로 혼동이 없다
        final parseResult = DateTime.parse('2026-02-12');
        final localResult = DateTimeUtils.parseLocalDate('2026-02-12');

        expect(parseResult.isUtc, false);
        expect(localResult.isUtc, false);
        expect(localResult.day, parseResult.day);

        // UTC ISO 문자열은 DateTime.parse가 UTC로 해석하는 반면
        // parseLocalDate는 항상 로컬 날짜만 추출
        final utcIso = DateTime.utc(2026, 2, 11, 23, 0).toIso8601String();
        // "2026-02-11T23:00:00.000Z" -> DateTime.parse는 UTC로 해석
        final fromIso = DateTime.parse(utcIso);
        expect(fromIso.isUtc, true, reason: 'Z 접미사가 있으면 UTC로 해석한다');
      });

      test('월말/월초 경계 날짜를 정확히 파싱한다', () {
        final jan31 = DateTimeUtils.parseLocalDate('2026-01-31');
        expect(jan31.month, 1);
        expect(jan31.day, 31);

        final feb01 = DateTimeUtils.parseLocalDate('2026-02-01');
        expect(feb01.month, 2);
        expect(feb01.day, 1);
      });

      test('연말/연초 경계 날짜를 정확히 파싱한다', () {
        final dec31 = DateTimeUtils.parseLocalDate('2025-12-31');
        expect(dec31.year, 2025);
        expect(dec31.month, 12);
        expect(dec31.day, 31);

        final jan01 = DateTimeUtils.parseLocalDate('2026-01-01');
        expect(jan01.year, 2026);
        expect(jan01.month, 1);
        expect(jan01.day, 1);
      });

      test('한 자리 월/일도 정상 파싱한다 (zero-padded)', () {
        final result = DateTimeUtils.parseLocalDate('2026-01-05');
        expect(result.month, 1);
        expect(result.day, 5);
      });
    });

    group('toLocalDateOnly - DATE 컬럼 저장', () {
      test('로컬 DateTime을 날짜 문자열로 변환한다', () {
        final dt = DateTime(2026, 2, 12, 15, 30);
        final result = DateTimeUtils.toLocalDateOnly(dt);
        expect(result, '2026-02-12');
      });

      test('로컬 자정 DateTime도 정확히 변환한다', () {
        final dt = DateTime(2026, 2, 12);
        final result = DateTimeUtils.toLocalDateOnly(dt);
        expect(result, '2026-02-12');
      });

      test('UTC 자정 직전 시간의 DateTime은 로컬 날짜 기준으로 변환한다 (핵심 버그 시나리오)', () {
        // 시나리오: KST 2026-02-12 08:29 -> UTC 2026-02-11 23:29
        // 기존 toDateOnly()는 UTC 기준이라 "2026-02-11"을 반환할 수 있음
        final kstMorning = DateTime(2026, 2, 12, 8, 29); // 로컬 시간
        final result = DateTimeUtils.toLocalDateOnly(kstMorning);
        expect(result, '2026-02-12',
            reason: '로컬 날짜 기준으로 2월 12일이어야 한다');
      });

      test('UTC DateTime을 전달해도 로컬 날짜로 올바르게 변환한다', () {
        // UTC 2026-02-11 23:29 -> KST 2026-02-12 08:29
        final utcDateTime = DateTime.utc(2026, 2, 11, 23, 29);
        final result = DateTimeUtils.toLocalDateOnly(utcDateTime);

        // 로컬 타임존이 UTC+9(KST)라면 "2026-02-12"여야 함
        // 테스트 환경의 타임존에 따라 달라질 수 있으므로
        // toLocal()의 날짜와 일치하는지 검증
        final localDt = utcDateTime.toLocal();
        final expected =
            '${localDt.year}-${localDt.month.toString().padLeft(2, '0')}-${localDt.day.toString().padLeft(2, '0')}';
        expect(result, expected);
      });

      test('월/일이 한 자리일 때 zero-padding을 적용한다', () {
        final dt = DateTime(2026, 1, 5, 10, 0);
        final result = DateTimeUtils.toLocalDateOnly(dt);
        expect(result, '2026-01-05');
      });

      test('12월 31일 자정 직전도 올바르게 처리한다', () {
        final dt = DateTime(2026, 12, 31, 23, 59, 59);
        final result = DateTimeUtils.toLocalDateOnly(dt);
        expect(result, '2026-12-31');
      });
    });

    group('toDateOnly vs toLocalDateOnly 비교 (기존 버그 재현)', () {
      test('toDateOnly는 UTC DateTime에서 날짜가 달라질 수 있다', () {
        // UTC 2026-02-11 23:29 (KST로는 2026-02-12 08:29)
        final utcDateTime = DateTime.utc(2026, 2, 11, 23, 29);

        // ignore: deprecated_member_use_from_same_package
        final oldResult = DateTimeUtils.toDateOnly(utcDateTime);
        final newResult = DateTimeUtils.toLocalDateOnly(utcDateTime);

        // toDateOnly는 UTC 기준이라 "2026-02-11" 반환
        expect(oldResult, '2026-02-11',
            reason: 'toDateOnly는 ISO 문자열 기반이라 UTC 날짜를 반환한다');

        // toLocalDateOnly는 로컬 기준
        final localDt = utcDateTime.toLocal();
        final expectedLocal =
            '${localDt.year}-${localDt.month.toString().padLeft(2, '0')}-${localDt.day.toString().padLeft(2, '0')}';
        expect(newResult, expectedLocal,
            reason: 'toLocalDateOnly는 로컬 날짜를 반환한다');
      });

      test('로컬 DateTime에서는 두 메서드가 동일한 결과를 반환한다', () {
        final localDt = DateTime(2026, 2, 12, 15, 30);

        // ignore: deprecated_member_use_from_same_package
        final oldResult = DateTimeUtils.toDateOnly(localDt);
        final newResult = DateTimeUtils.toLocalDateOnly(localDt);

        expect(oldResult, newResult,
            reason: '로컬 DateTime에서는 두 메서드가 동일해야 한다');
      });
    });

    group('parseLocalDate + toLocalDateOnly 왕복 변환 (round-trip)', () {
      test('저장 후 읽기 시 날짜가 보존된다', () {
        final original = DateTime(2026, 2, 12, 8, 29);

        // 저장: DateTime -> 문자열
        final dateStr = DateTimeUtils.toLocalDateOnly(original);
        expect(dateStr, '2026-02-12');

        // 읽기: 문자열 -> DateTime
        final parsed = DateTimeUtils.parseLocalDate(dateStr);
        expect(parsed.year, original.year);
        expect(parsed.month, original.month);
        expect(parsed.day, original.day);
        expect(parsed.isUtc, false);
      });

      test('자정 직전 시간도 왕복 변환 시 날짜가 보존된다', () {
        final original = DateTime(2026, 2, 12, 23, 59, 59);

        final dateStr = DateTimeUtils.toLocalDateOnly(original);
        final parsed = DateTimeUtils.parseLocalDate(dateStr);

        expect(parsed.year, 2026);
        expect(parsed.month, 2);
        expect(parsed.day, 12);
      });

      test('자정 직후 시간도 왕복 변환 시 날짜가 보존된다', () {
        final original = DateTime(2026, 2, 12, 0, 0, 1);

        final dateStr = DateTimeUtils.toLocalDateOnly(original);
        final parsed = DateTimeUtils.parseLocalDate(dateStr);

        expect(parsed.year, 2026);
        expect(parsed.month, 2);
        expect(parsed.day, 12);
      });

      test('연속 7일간 왕복 변환이 모두 정확하다', () {
        for (int i = 0; i < 7; i++) {
          final original = DateTime(2026, 2, 10 + i, 3, 0);
          final dateStr = DateTimeUtils.toLocalDateOnly(original);
          final parsed = DateTimeUtils.parseLocalDate(dateStr);

          expect(parsed.day, 10 + i,
              reason: '2월 ${10 + i}일이 보존되어야 한다');
        }
      });
    });

    group('날짜 비교/그룹화 시나리오', () {
      test('parseLocalDate로 파싱한 같은 날짜는 동일 비교가 가능하다', () {
        final date1 = DateTimeUtils.parseLocalDate('2026-02-12');
        final date2 = DateTimeUtils.parseLocalDate('2026-02-12');

        expect(date1, equals(date2));
        expect(date1.compareTo(date2), 0);
      });

      test('parseLocalDate로 파싱한 날짜 간 정렬이 올바르다', () {
        final dates = [
          DateTimeUtils.parseLocalDate('2026-02-15'),
          DateTimeUtils.parseLocalDate('2026-02-12'),
          DateTimeUtils.parseLocalDate('2026-02-13'),
        ];
        dates.sort();

        expect(dates[0].day, 12);
        expect(dates[1].day, 13);
        expect(dates[2].day, 15);
      });

      test('같은 날짜의 거래를 그룹화할 때 올바르게 동작한다', () {
        // 시뮬레이션: DB에서 읽은 거래 3건 (같은 날짜)
        final transactions = [
          {'date': '2026-02-12', 'amount': 10000},
          {'date': '2026-02-12', 'amount': 20000},
          {'date': '2026-02-13', 'amount': 30000},
        ];

        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final tx in transactions) {
          final date = DateTimeUtils.parseLocalDate(tx['date'] as String);
          final key = DateTimeUtils.toLocalDateOnly(date);
          grouped.putIfAbsent(key, () => []).add(tx);
        }

        expect(grouped.keys.length, 2, reason: '2개 그룹이어야 한다');
        expect(grouped['2026-02-12']!.length, 2);
        expect(grouped['2026-02-13']!.length, 1);
      });
    });

    group('SMS 자동수집 시나리오', () {
      test('SMS 파싱된 로컬 시간을 저장 후 읽어도 날짜가 변하지 않는다', () {
        // SMS 수신: 한국시간 새벽 0시 30분 (UTC 전날 15:30)
        final smsTimestamp = DateTime(2026, 2, 12, 0, 30);

        // 저장
        final savedDate = DateTimeUtils.toLocalDateOnly(smsTimestamp);
        expect(savedDate, '2026-02-12');

        // 읽기
        final loadedDate = DateTimeUtils.parseLocalDate(savedDate);
        expect(loadedDate.day, 12, reason: 'SMS 수신 날짜가 보존되어야 한다');
      });

      test('fromMillisecondsSinceEpoch로 생성된 DateTime도 올바르게 처리한다', () {
        // Android SMS 수신 시 timestamp는 fromMillisecondsSinceEpoch로 생성
        final now = DateTime.now();
        final epochMs = now.millisecondsSinceEpoch;
        final fromEpoch = DateTime.fromMillisecondsSinceEpoch(epochMs);

        expect(fromEpoch.isUtc, false, reason: '기본값은 로컬 시간이다');

        final savedDate = DateTimeUtils.toLocalDateOnly(fromEpoch);
        final loadedDate = DateTimeUtils.parseLocalDate(savedDate);

        expect(loadedDate.year, fromEpoch.year);
        expect(loadedDate.month, fromEpoch.month);
        expect(loadedDate.day, fromEpoch.day);
      });
    });
  });
}
