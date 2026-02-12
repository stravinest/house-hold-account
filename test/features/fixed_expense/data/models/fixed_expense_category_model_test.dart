import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/fixed_expense/data/models/fixed_expense_category_model.dart';
import 'package:shared_household_account/features/fixed_expense/domain/entities/fixed_expense_category.dart';

void main() {
  group('FixedExpenseCategoryModel', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);

    final fixedExpenseCategoryModel = FixedExpenseCategoryModel(
      id: 'test-id',
      ledgerId: 'ledger-id',
      name: '통신비',
      icon: '📱',
      color: '#6750A4',
      sortOrder: 1,
      createdAt: testCreatedAt,
    );

    test('FixedExpenseCategory 엔티티를 확장한다', () {
      expect(fixedExpenseCategoryModel, isA<FixedExpenseCategory>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'name': '관리비',
          'icon': '🏠',
          'color': '#FF5733',
          'sort_order': 2,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = FixedExpenseCategoryModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.ledgerId, 'ledger-id');
        expect(result.name, '관리비');
        expect(result.icon, '🏠');
        expect(result.color, '#FF5733');
        expect(result.sortOrder, 2);
        expect(result.createdAt, DateTime.parse('2026-02-12T10:00:00.000'));
      });

      test('icon이 null인 경우 빈 문자열로 설정된다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '통신비',
          'icon': null,
          'color': '#6750A4',
          'sort_order': 1,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = FixedExpenseCategoryModel.fromJson(json);

        expect(result.icon, '');
      });

      test('color가 null인 경우 기본값으로 설정된다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '통신비',
          'icon': '📱',
          'color': null,
          'sort_order': 1,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = FixedExpenseCategoryModel.fromJson(json);

        expect(result.color, '#6750A4');
      });

      test('sortOrder가 null인 경우 0으로 설정된다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '통신비',
          'icon': '📱',
          'color': '#6750A4',
          'sort_order': null,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = FixedExpenseCategoryModel.fromJson(json);

        expect(result.sortOrder, 0);
      });

      test('다양한 날짜 형식을 파싱한다', () {
        final json1 = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '통신비',
          'icon': '📱',
          'color': '#6750A4',
          'sort_order': 1,
          'created_at': '2026-02-12T10:00:00.000Z',
        };

        final json2 = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '통신비',
          'icon': '📱',
          'color': '#6750A4',
          'sort_order': 1,
          'created_at': '2026-02-12T10:00:00',
        };

        final result1 = FixedExpenseCategoryModel.fromJson(json1);
        final result2 = FixedExpenseCategoryModel.fromJson(json2);

        expect(result1.createdAt.year, 2026);
        expect(result1.createdAt.month, 2);
        expect(result1.createdAt.day, 12);
        expect(result2.createdAt.year, 2026);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = fixedExpenseCategoryModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['ledger_id'], 'ledger-id');
        expect(json['name'], '통신비');
        expect(json['icon'], '📱');
        expect(json['color'], '#6750A4');
        expect(json['sort_order'], 1);
      });

      test('모든 필드가 JSON에 포함된다', () {
        final json = fixedExpenseCategoryModel.toJson();

        expect(json.containsKey('id'), true);
        expect(json.containsKey('ledger_id'), true);
        expect(json.containsKey('name'), true);
        expect(json.containsKey('icon'), true);
        expect(json.containsKey('color'), true);
        expect(json.containsKey('sort_order'), true);
      });

      test('created_at은 포함되지 않는다', () {
        final json = fixedExpenseCategoryModel.toJson();

        expect(json.containsKey('created_at'), false);
      });
    });

    group('toCreateJson', () {
      test('생성용 JSON을 올바르게 만든다', () {
        final json = FixedExpenseCategoryModel.toCreateJson(
          ledgerId: 'new-ledger-id',
          name: '관리비',
          icon: '🏠',
          color: '#FF5733',
          sortOrder: 2,
        );

        expect(json['ledger_id'], 'new-ledger-id');
        expect(json['name'], '관리비');
        expect(json['icon'], '🏠');
        expect(json['color'], '#FF5733');
        expect(json['sort_order'], 2);
      });

      test('icon 기본값이 빈 문자열이다', () {
        final json = FixedExpenseCategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '통신비',
          color: '#6750A4',
        );

        expect(json['icon'], '');
      });

      test('sortOrder 기본값이 0이다', () {
        final json = FixedExpenseCategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '통신비',
          color: '#6750A4',
        );

        expect(json['sort_order'], 0);
      });

      test('id와 created_at은 포함되지 않는다', () {
        final json = FixedExpenseCategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '통신비',
          color: '#6750A4',
        );

        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_at'), false);
      });
    });

    group('toUpdateJson', () {
      test('업데이트용 JSON을 올바르게 만든다', () {
        final json = FixedExpenseCategoryModel.toUpdateJson(
          name: '새 이름',
          icon: '🆕',
          color: '#00FF00',
          sortOrder: 5,
        );

        expect(json['name'], '새 이름');
        expect(json['icon'], '🆕');
        expect(json['color'], '#00FF00');
        expect(json['sort_order'], 5);
      });

      test('name만 업데이트할 수 있다', () {
        final json = FixedExpenseCategoryModel.toUpdateJson(
          name: '새 이름',
        );

        expect(json['name'], '새 이름');
        expect(json.containsKey('icon'), false);
        expect(json.containsKey('color'), false);
        expect(json.containsKey('sort_order'), false);
      });

      test('icon만 업데이트할 수 있다', () {
        final json = FixedExpenseCategoryModel.toUpdateJson(
          name: '이름',
          icon: '🆕',
        );

        expect(json['name'], '이름');
        expect(json['icon'], '🆕');
        expect(json.containsKey('color'), false);
        expect(json.containsKey('sort_order'), false);
      });

      test('color만 업데이트할 수 있다', () {
        final json = FixedExpenseCategoryModel.toUpdateJson(
          name: '이름',
          color: '#00FF00',
        );

        expect(json['name'], '이름');
        expect(json['color'], '#00FF00');
        expect(json.containsKey('icon'), false);
        expect(json.containsKey('sort_order'), false);
      });

      test('sortOrder만 업데이트할 수 있다', () {
        final json = FixedExpenseCategoryModel.toUpdateJson(
          name: '이름',
          sortOrder: 10,
        );

        expect(json['name'], '이름');
        expect(json['sort_order'], 10);
        expect(json.containsKey('icon'), false);
        expect(json.containsKey('color'), false);
      });

      test('id, ledger_id, created_at은 포함되지 않는다', () {
        final json = FixedExpenseCategoryModel.toUpdateJson(
          name: '이름',
          icon: '🆕',
          color: '#00FF00',
          sortOrder: 5,
        );

        expect(json.containsKey('id'), false);
        expect(json.containsKey('ledger_id'), false);
        expect(json.containsKey('created_at'), false);
      });
    });

    group('copyWith', () {
      test('id를 변경할 수 있다', () {
        final copied = fixedExpenseCategoryModel.copyWith(id: 'new-id');

        expect(copied.id, 'new-id');
        expect(copied.ledgerId, 'ledger-id');
        expect(copied.name, '통신비');
      });

      test('ledgerId를 변경할 수 있다', () {
        final copied = fixedExpenseCategoryModel.copyWith(ledgerId: 'new-ledger-id');

        expect(copied.ledgerId, 'new-ledger-id');
      });

      test('name을 변경할 수 있다', () {
        final copied = fixedExpenseCategoryModel.copyWith(name: '새 이름');

        expect(copied.name, '새 이름');
      });

      test('icon을 변경할 수 있다', () {
        final copied = fixedExpenseCategoryModel.copyWith(icon: '🆕');

        expect(copied.icon, '🆕');
      });

      test('color를 변경할 수 있다', () {
        final copied = fixedExpenseCategoryModel.copyWith(color: '#00FF00');

        expect(copied.color, '#00FF00');
      });

      test('sortOrder를 변경할 수 있다', () {
        final copied = fixedExpenseCategoryModel.copyWith(sortOrder: 10);

        expect(copied.sortOrder, 10);
      });

      test('createdAt을 변경할 수 있다', () {
        final newCreatedAt = DateTime(2026, 2, 13, 10, 0, 0);
        final copied = fixedExpenseCategoryModel.copyWith(createdAt: newCreatedAt);

        expect(copied.createdAt, newCreatedAt);
      });

      test('여러 필드를 동시에 변경할 수 있다', () {
        final copied = fixedExpenseCategoryModel.copyWith(
          name: '새 이름',
          color: '#00FF00',
          sortOrder: 5,
        );

        expect(copied.name, '새 이름');
        expect(copied.color, '#00FF00');
        expect(copied.sortOrder, 5);
        expect(copied.id, 'test-id');
      });

      test('인자 없이 호출하면 동일한 값을 가진 객체를 반환한다', () {
        final copied = fixedExpenseCategoryModel.copyWith();

        expect(copied.id, fixedExpenseCategoryModel.id);
        expect(copied.ledgerId, fixedExpenseCategoryModel.ledgerId);
        expect(copied.name, fixedExpenseCategoryModel.name);
        expect(copied.icon, fixedExpenseCategoryModel.icon);
        expect(copied.color, fixedExpenseCategoryModel.color);
        expect(copied.sortOrder, fixedExpenseCategoryModel.sortOrder);
        expect(copied.createdAt, fixedExpenseCategoryModel.createdAt);
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '통신비',
          'icon': '📱',
          'color': '#6750A4',
          'sort_order': 1,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final model = FixedExpenseCategoryModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['ledger_id'], originalJson['ledger_id']);
        expect(convertedJson['name'], originalJson['name']);
        expect(convertedJson['icon'], originalJson['icon']);
        expect(convertedJson['color'], originalJson['color']);
        expect(convertedJson['sort_order'], originalJson['sort_order']);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열 이름을 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '',
          'icon': '📱',
          'color': '#6750A4',
          'sort_order': 1,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = FixedExpenseCategoryModel.fromJson(json);

        expect(result.name, '');
      });

      test('매우 긴 이름을 처리할 수 있다', () {
        final longName = '카테고리' * 500;
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': longName,
          'icon': '📱',
          'color': '#6750A4',
          'sort_order': 1,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = FixedExpenseCategoryModel.fromJson(json);

        expect(result.name, longName);
      });

      test('빈 문자열 아이콘을 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '통신비',
          'icon': '',
          'color': '#6750A4',
          'sort_order': 1,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = FixedExpenseCategoryModel.fromJson(json);

        expect(result.icon, '');
      });

      test('복수 이모지 아이콘을 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '통신비',
          'icon': '📱💻🖥️',
          'color': '#6750A4',
          'sort_order': 1,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = FixedExpenseCategoryModel.fromJson(json);

        expect(result.icon, '📱💻🖥️');
      });

      test('다양한 색상 형식을 처리할 수 있다', () {
        final colors = ['#FF5733', '#6750A4', 'rgba(255, 87, 51, 0.5)', 'red'];

        for (final color in colors) {
          final json = {
            'id': 'test-id',
            'ledger_id': 'ledger-id',
            'name': '통신비',
            'icon': '📱',
            'color': color,
            'sort_order': 1,
            'created_at': '2026-02-12T10:00:00.000',
          };

          final result = FixedExpenseCategoryModel.fromJson(json);

          expect(result.color, color);
        }
      });

      test('음수 sortOrder를 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '통신비',
          'icon': '📱',
          'color': '#6750A4',
          'sort_order': -1,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = FixedExpenseCategoryModel.fromJson(json);

        expect(result.sortOrder, -1);
      });

      test('매우 큰 sortOrder를 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '통신비',
          'icon': '📱',
          'color': '#6750A4',
          'sort_order': 999999,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = FixedExpenseCategoryModel.fromJson(json);

        expect(result.sortOrder, 999999);
      });
    });
  });
}
