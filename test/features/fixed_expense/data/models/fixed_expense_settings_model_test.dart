import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/fixed_expense/data/models/fixed_expense_settings_model.dart';
import 'package:shared_household_account/features/fixed_expense/domain/entities/fixed_expense_settings.dart';

void main() {
  group('FixedExpenseSettingsModel', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final fixedExpenseSettingsModel = FixedExpenseSettingsModel(
      id: 'test-id',
      ledgerId: 'ledger-id',
      includeInExpense: true,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    test('FixedExpenseSettings 엔티티를 확장한다', () {
      expect(fixedExpenseSettingsModel, isA<FixedExpenseSettings>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'include_in_expense': true,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FixedExpenseSettingsModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.ledgerId, 'ledger-id');
        expect(result.includeInExpense, true);
        expect(result.createdAt, DateTime.parse('2026-02-12T10:00:00.000'));
        expect(result.updatedAt, DateTime.parse('2026-02-12T11:00:00.000'));
      });

      test('includeInExpense가 false인 경우를 역직렬화한다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'include_in_expense': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FixedExpenseSettingsModel.fromJson(json);

        expect(result.includeInExpense, false);
      });

      test('includeInExpense가 null인 경우 false로 설정된다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'include_in_expense': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FixedExpenseSettingsModel.fromJson(json);

        expect(result.includeInExpense, false);
      });

      test('다양한 날짜 형식을 파싱한다', () {
        final json1 = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'include_in_expense': true,
          'created_at': '2026-02-12T10:00:00.000Z',
          'updated_at': '2026-02-12T11:00:00.000Z',
        };

        final json2 = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'include_in_expense': true,
          'created_at': '2026-02-12T10:00:00',
          'updated_at': '2026-02-12T11:00:00',
        };

        final result1 = FixedExpenseSettingsModel.fromJson(json1);
        final result2 = FixedExpenseSettingsModel.fromJson(json2);

        expect(result1.createdAt.year, 2026);
        expect(result1.createdAt.month, 2);
        expect(result1.createdAt.day, 12);
        expect(result2.createdAt.year, 2026);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = fixedExpenseSettingsModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['ledger_id'], 'ledger-id');
        expect(json['include_in_expense'], true);
      });

      test('모든 필드가 JSON에 포함된다', () {
        final json = fixedExpenseSettingsModel.toJson();

        expect(json.containsKey('id'), true);
        expect(json.containsKey('ledger_id'), true);
        expect(json.containsKey('include_in_expense'), true);
      });

      test('created_at과 updated_at은 포함되지 않는다', () {
        final json = fixedExpenseSettingsModel.toJson();

        expect(json.containsKey('created_at'), false);
        expect(json.containsKey('updated_at'), false);
      });

      test('includeInExpense가 false인 경우 올바르게 직렬화된다', () {
        final model = FixedExpenseSettingsModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          includeInExpense: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final json = model.toJson();

        expect(json['include_in_expense'], false);
      });
    });

    group('toUpdateJson', () {
      test('업데이트용 JSON을 올바르게 만든다', () {
        final json = FixedExpenseSettingsModel.toUpdateJson(
          includeInExpense: true,
        );

        expect(json['include_in_expense'], true);
        expect(json['updated_at'], isA<String>());
      });

      test('includeInExpense가 false인 경우 올바르게 만든다', () {
        final json = FixedExpenseSettingsModel.toUpdateJson(
          includeInExpense: false,
        );

        expect(json['include_in_expense'], false);
        expect(json['updated_at'], isA<String>());
      });

      test('include_in_expense와 updated_at만 포함된다', () {
        final json = FixedExpenseSettingsModel.toUpdateJson(
          includeInExpense: true,
        );

        expect(json.containsKey('include_in_expense'), true);
        expect(json.containsKey('updated_at'), true);
        expect(json.containsKey('id'), false);
        expect(json.containsKey('ledger_id'), false);
        expect(json.containsKey('created_at'), false);
      });

      test('updated_at이 ISO 8601 형식이다', () {
        final json = FixedExpenseSettingsModel.toUpdateJson(
          includeInExpense: true,
        );

        expect(json['updated_at'], isA<String>());
        expect(() => DateTime.parse(json['updated_at']), returnsNormally);
      });
    });

    group('copyWith', () {
      test('id를 변경할 수 있다', () {
        final copied = fixedExpenseSettingsModel.copyWith(id: 'new-id');

        expect(copied.id, 'new-id');
        expect(copied.ledgerId, 'ledger-id');
        expect(copied.includeInExpense, true);
      });

      test('ledgerId를 변경할 수 있다', () {
        final copied = fixedExpenseSettingsModel.copyWith(ledgerId: 'new-ledger-id');

        expect(copied.ledgerId, 'new-ledger-id');
      });

      test('includeInExpense를 변경할 수 있다', () {
        final copied = fixedExpenseSettingsModel.copyWith(includeInExpense: false);

        expect(copied.includeInExpense, false);
      });

      test('createdAt을 변경할 수 있다', () {
        final newCreatedAt = DateTime(2026, 2, 13, 10, 0, 0);
        final copied = fixedExpenseSettingsModel.copyWith(createdAt: newCreatedAt);

        expect(copied.createdAt, newCreatedAt);
      });

      test('updatedAt을 변경할 수 있다', () {
        final newUpdatedAt = DateTime(2026, 2, 13, 11, 0, 0);
        final copied = fixedExpenseSettingsModel.copyWith(updatedAt: newUpdatedAt);

        expect(copied.updatedAt, newUpdatedAt);
      });

      test('여러 필드를 동시에 변경할 수 있다', () {
        final copied = fixedExpenseSettingsModel.copyWith(
          ledgerId: 'new-ledger-id',
          includeInExpense: false,
        );

        expect(copied.ledgerId, 'new-ledger-id');
        expect(copied.includeInExpense, false);
        expect(copied.id, 'test-id');
      });

      test('인자 없이 호출하면 동일한 값을 가진 객체를 반환한다', () {
        final copied = fixedExpenseSettingsModel.copyWith();

        expect(copied.id, fixedExpenseSettingsModel.id);
        expect(copied.ledgerId, fixedExpenseSettingsModel.ledgerId);
        expect(copied.includeInExpense, fixedExpenseSettingsModel.includeInExpense);
        expect(copied.createdAt, fixedExpenseSettingsModel.createdAt);
        expect(copied.updatedAt, fixedExpenseSettingsModel.updatedAt);
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'include_in_expense': true,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final model = FixedExpenseSettingsModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['ledger_id'], originalJson['ledger_id']);
        expect(convertedJson['include_in_expense'], originalJson['include_in_expense']);
      });

      test('includeInExpense가 false인 경우도 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'include_in_expense': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final model = FixedExpenseSettingsModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['include_in_expense'], false);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열 ID를 처리할 수 있다', () {
        final json = {
          'id': '',
          'ledger_id': 'ledger-id',
          'include_in_expense': true,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FixedExpenseSettingsModel.fromJson(json);

        expect(result.id, '');
      });

      test('매우 긴 ID를 처리할 수 있다', () {
        final longId = 'a' * 1000;
        final json = {
          'id': longId,
          'ledger_id': 'ledger-id',
          'include_in_expense': true,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FixedExpenseSettingsModel.fromJson(json);

        expect(result.id, longId);
      });

      test('빈 문자열 ledgerId를 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': '',
          'include_in_expense': true,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FixedExpenseSettingsModel.fromJson(json);

        expect(result.ledgerId, '');
      });

      test('createdAt과 updatedAt이 동일한 경우를 처리할 수 있다', () {
        final sameTime = '2026-02-12T10:00:00.000';
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'include_in_expense': true,
          'created_at': sameTime,
          'updated_at': sameTime,
        };

        final result = FixedExpenseSettingsModel.fromJson(json);

        expect(result.createdAt, result.updatedAt);
      });

      test('includeInExpense true와 false를 모두 처리할 수 있다', () {
        final trueJson = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'include_in_expense': true,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final falseJson = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'include_in_expense': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final trueResult = FixedExpenseSettingsModel.fromJson(trueJson);
        final falseResult = FixedExpenseSettingsModel.fromJson(falseJson);

        expect(trueResult.includeInExpense, true);
        expect(falseResult.includeInExpense, false);
      });
    });
  });
}
