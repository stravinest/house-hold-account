import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/category/data/models/category_model.dart';
import 'package:shared_household_account/features/category/domain/entities/category.dart';

void main() {
  group('CategoryModel', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);

    final categoryModel = CategoryModel(
      id: 'test-id',
      ledgerId: 'ledger-id',
      name: '식비',
      icon: '🍔',
      color: '#FF5733',
      type: 'expense',
      isDefault: false,
      sortOrder: 0,
      createdAt: testCreatedAt,
    );

    test('Category 엔티티를 확장한다', () {
      expect(categoryModel, isA<Category>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'name': '교통비',
          'icon': '🚗',
          'color': '#00FF00',
          'type': 'expense',
          'is_default': true,
          'sort_order': 5,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = CategoryModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.ledgerId, 'ledger-id');
        expect(result.name, '교통비');
        expect(result.icon, '🚗');
        expect(result.color, '#00FF00');
        expect(result.type, 'expense');
        expect(result.isDefault, true);
        expect(result.sortOrder, 5);
        expect(result.createdAt, DateTime.parse('2026-02-12T10:00:00.000'));
      });

      test('income 타입의 카테고리를 역직렬화한다', () {
        final json = {
          'id': 'income-id',
          'ledger_id': 'ledger-id',
          'name': '급여',
          'icon': '💰',
          'color': '#00FF00',
          'type': 'income',
          'is_default': true,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = CategoryModel.fromJson(json);

        expect(result.type, 'income');
        expect(result.isIncome, true);
      });

      test('asset 타입의 카테고리를 역직렬화한다', () {
        final json = {
          'id': 'asset-id',
          'ledger_id': 'ledger-id',
          'name': '정기예금',
          'icon': '🏦',
          'color': '#0000FF',
          'type': 'asset',
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = CategoryModel.fromJson(json);

        expect(result.type, 'asset');
        expect(result.isAssetType, true);
      });

      test('다양한 날짜 형식을 파싱한다', () {
        final json1 = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '식비',
          'icon': '🍔',
          'color': '#FF5733',
          'type': 'expense',
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000Z',
        };

        final json2 = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '식비',
          'icon': '🍔',
          'color': '#FF5733',
          'type': 'expense',
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00',
        };

        final result1 = CategoryModel.fromJson(json1);
        final result2 = CategoryModel.fromJson(json2);

        expect(result1.createdAt.year, 2026);
        expect(result1.createdAt.month, 2);
        expect(result1.createdAt.day, 12);
        expect(result2.createdAt.year, 2026);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = categoryModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['ledger_id'], 'ledger-id');
        expect(json['name'], '식비');
        expect(json['icon'], '🍔');
        expect(json['color'], '#FF5733');
        expect(json['type'], 'expense');
        expect(json['is_default'], false);
        expect(json['sort_order'], 0);
        expect(json['created_at'], isA<String>());
      });

      test('created_at이 ISO 8601 형식으로 직렬화된다', () {
        final json = categoryModel.toJson();

        expect(json['created_at'], testCreatedAt.toIso8601String());
      });

      test('모든 필드가 JSON에 포함된다', () {
        final json = categoryModel.toJson();

        expect(json.containsKey('id'), true);
        expect(json.containsKey('ledger_id'), true);
        expect(json.containsKey('name'), true);
        expect(json.containsKey('icon'), true);
        expect(json.containsKey('color'), true);
        expect(json.containsKey('type'), true);
        expect(json.containsKey('is_default'), true);
        expect(json.containsKey('sort_order'), true);
        expect(json.containsKey('created_at'), true);
      });
    });

    group('toCreateJson', () {
      test('생성용 JSON을 올바르게 만든다', () {
        final json = CategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '주거비',
          icon: '🏠',
          color: '#0000FF',
          type: 'expense',
        );

        expect(json['ledger_id'], 'ledger-id');
        expect(json['name'], '주거비');
        expect(json['icon'], '🏠');
        expect(json['color'], '#0000FF');
        expect(json['type'], 'expense');
        expect(json['is_default'], false);
        expect(json['sort_order'], 0);
      });

      test('기본값이 올바르게 설정된다', () {
        final json = CategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
        );

        expect(json['is_default'], false);
        expect(json['sort_order'], 0);
      });

      test('sortOrder를 커스텀할 수 있다', () {
        final json = CategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
          sortOrder: 10,
        );

        expect(json['sort_order'], 10);
      });

      test('id와 created_at는 포함되지 않는다', () {
        final json = CategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
        );

        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_at'), false);
      });

      test('다양한 타입의 카테고리를 생성할 수 있다', () {
        final incomeJson = CategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '급여',
          icon: '💰',
          color: '#00FF00',
          type: 'income',
        );

        final expenseJson = CategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
        );

        final assetJson = CategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '정기예금',
          icon: '🏦',
          color: '#0000FF',
          type: 'asset',
        );

        expect(incomeJson['type'], 'income');
        expect(expenseJson['type'], 'expense');
        expect(assetJson['type'], 'asset');
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '식비',
          'icon': '🍔',
          'color': '#FF5733',
          'type': 'expense',
          'is_default': false,
          'sort_order': 5,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final model = CategoryModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['ledger_id'], originalJson['ledger_id']);
        expect(convertedJson['name'], originalJson['name']);
        expect(convertedJson['icon'], originalJson['icon']);
        expect(convertedJson['color'], originalJson['color']);
        expect(convertedJson['type'], originalJson['type']);
        expect(convertedJson['is_default'], originalJson['is_default']);
        expect(convertedJson['sort_order'], originalJson['sort_order']);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열을 이름으로 사용할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '',
          'icon': '🍔',
          'color': '#FF5733',
          'type': 'expense',
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = CategoryModel.fromJson(json);

        expect(result.name, '');
      });

      test('매우 긴 이름을 처리할 수 있다', () {
        final longName = '아주 긴 카테고리 이름 ' * 10;
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': longName,
          'icon': '🍔',
          'color': '#FF5733',
          'type': 'expense',
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = CategoryModel.fromJson(json);

        expect(result.name, longName);
      });

      test('음수 sortOrder를 처리할 수 있다', () {
        final json = CategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
          sortOrder: -1,
        );

        expect(json['sort_order'], -1);
      });

      test('매우 큰 sortOrder를 처리할 수 있다', () {
        final json = CategoryModel.toCreateJson(
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
          sortOrder: 999999,
        );

        expect(json['sort_order'], 999999);
      });

      test('특수 문자가 포함된 색상 값을 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '식비',
          'icon': '🍔',
          'color': 'rgba(255, 87, 51, 0.5)',
          'type': 'expense',
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = CategoryModel.fromJson(json);

        expect(result.color, 'rgba(255, 87, 51, 0.5)');
      });

      test('유니코드 이모지를 올바르게 처리한다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'name': '식비',
          'icon': '🍔🍕🍝',
          'color': '#FF5733',
          'type': 'expense',
          'is_default': false,
          'sort_order': 0,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = CategoryModel.fromJson(json);

        expect(result.icon, '🍔🍕🍝');
      });
    });
  });
}
