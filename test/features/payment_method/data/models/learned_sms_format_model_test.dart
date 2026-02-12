import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/models/learned_sms_format_model.dart';
import 'package:shared_household_account/features/payment_method/data/services/financial_constants.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/learned_sms_format.dart';

void main() {
  group('LearnedSmsFormatModel', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final learnedFormatModel = LearnedSmsFormatModel(
      id: 'test-id',
      paymentMethodId: 'payment-method-id',
      senderPattern: 'KB',
      senderKeywords: ['KB카드', 'KB국민'],
      amountRegex: r'(\d{1,3}(,\d{3})*|\d+)원',
      typeKeywords: {
        'expense': ['승인', '결제'],
        'income': ['입금', '수령'],
      },
      merchantRegex: r'가맹점\s*[:：]\s*(.+)',
      dateRegex: r'(\d{2})/(\d{2})\s+(\d{2}):(\d{2})',
      sampleSms: '[Web발신]\n승인 10,000원\nKB카드\n스타벅스',
      isSystem: false,
      confidence: 0.9,
      matchCount: 10,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    test('LearnedSmsFormat 엔티티를 확장한다', () {
      expect(learnedFormatModel, isA<LearnedSmsFormat>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'payment_method_id': 'payment-method-id',
          'sender_pattern': 'KB',
          'sender_keywords': ['KB카드', 'KB국민'],
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인', '결제'],
            'income': ['입금'],
          },
          'merchant_regex': r'가맹점\s*[:：]\s*(.+)',
          'date_regex': r'(\d{2})/(\d{2})',
          'sample_sms': '[Web발신]',
          'is_system': true,
          'confidence': 0.95,
          'match_count': 20,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedSmsFormatModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.paymentMethodId, 'payment-method-id');
        expect(result.senderPattern, 'KB');
        expect(result.senderKeywords, ['KB카드', 'KB국민']);
        expect(result.amountRegex, r'\d+원');
        expect(result.typeKeywords['expense'], ['승인', '결제']);
        expect(result.typeKeywords['income'], ['입금']);
        expect(result.merchantRegex, r'가맹점\s*[:：]\s*(.+)');
        expect(result.dateRegex, r'(\d{2})/(\d{2})');
        expect(result.sampleSms, '[Web발신]');
        expect(result.isSystem, true);
        expect(result.confidence, 0.95);
        expect(result.matchCount, 20);
      });

      test('typeKeywords가 String(JSON encoded)일 때 파싱한다', () {
        final typeKeywordsMap = {
          'expense': ['승인', '결제'],
          'income': ['입금'],
        };
        final json = {
          'id': 'json-id',
          'payment_method_id': 'payment-method-id',
          'sender_pattern': 'KB',
          'sender_keywords': ['KB카드'],
          'amount_regex': r'\d+원',
          'type_keywords': jsonEncode(typeKeywordsMap),
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedSmsFormatModel.fromJson(json);

        expect(result.typeKeywords['expense'], ['승인', '결제']);
        expect(result.typeKeywords['income'], ['입금']);
      });

      test('typeKeywords가 null일 때 기본값을 사용한다', () {
        final json = {
          'id': 'json-id',
          'payment_method_id': 'payment-method-id',
          'sender_pattern': 'KB',
          'sender_keywords': ['KB카드'],
          'amount_regex': r'\d+원',
          'type_keywords': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedSmsFormatModel.fromJson(json);

        expect(result.typeKeywords, FinancialConstants.defaultTypeKeywords);
      });

      test('senderKeywords가 null일 때 빈 리스트를 사용한다', () {
        final json = {
          'id': 'json-id',
          'payment_method_id': 'payment-method-id',
          'sender_pattern': 'KB',
          'sender_keywords': null,
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인'],
          },
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedSmsFormatModel.fromJson(json);

        expect(result.senderKeywords, isEmpty);
      });

      test('null 값들을 올바르게 처리한다', () {
        final json = {
          'id': 'json-id',
          'payment_method_id': 'payment-method-id',
          'sender_pattern': 'KB',
          'sender_keywords': [],
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인'],
          },
          'merchant_regex': null,
          'date_regex': null,
          'sample_sms': null,
          'is_system': null,
          'confidence': null,
          'match_count': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedSmsFormatModel.fromJson(json);

        expect(result.merchantRegex, null);
        expect(result.dateRegex, null);
        expect(result.sampleSms, null);
        expect(result.isSystem, false);
        expect(result.confidence, 0.8);
        expect(result.matchCount, 0);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = learnedFormatModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['payment_method_id'], 'payment-method-id');
        expect(json['sender_pattern'], 'KB');
        expect(json['sender_keywords'], ['KB카드', 'KB국민']);
        expect(json['amount_regex'], r'(\d{1,3}(,\d{3})*|\d+)원');
        expect(json['type_keywords']['expense'], ['승인', '결제']);
        expect(json['type_keywords']['income'], ['입금', '수령']);
        expect(json['merchant_regex'], r'가맹점\s*[:：]\s*(.+)');
        expect(json['date_regex'], r'(\d{2})/(\d{2})\s+(\d{2}):(\d{2})');
        expect(json['sample_sms'], '[Web발신]\n승인 10,000원\nKB카드\n스타벅스');
        expect(json['is_system'], false);
        expect(json['confidence'], 0.9);
        expect(json['match_count'], 10);
        expect(json['created_at'], isA<String>());
        expect(json['updated_at'], isA<String>());
      });

      test('null 값들을 올바르게 직렬화한다', () {
        final model = LearnedSmsFormatModel(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          senderKeywords: [],
          amountRegex: r'\d+원',
          typeKeywords: {},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final json = model.toJson();

        expect(json['merchant_regex'], null);
        expect(json['date_regex'], null);
        expect(json['sample_sms'], null);
      });
    });

    group('toCreateJson', () {
      test('생성용 JSON을 올바르게 만든다', () {
        final json = LearnedSmsFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          senderKeywords: ['KB카드', 'KB국민'],
          amountRegex: r'\d+원',
          typeKeywords: {
            'expense': ['승인', '결제'],
          },
          merchantRegex: r'가맹점\s*[:：]\s*(.+)',
          dateRegex: r'(\d{2})/(\d{2})',
          sampleSms: '[Web발신]',
          isSystem: true,
          confidence: 0.95,
        );

        expect(json['payment_method_id'], 'payment-method-id');
        expect(json['sender_pattern'], 'KB');
        expect(json['sender_keywords'], ['KB카드', 'KB국민']);
        expect(json['amount_regex'], r'\d+원');
        expect(json['type_keywords']['expense'], ['승인', '결제']);
        expect(json['merchant_regex'], r'가맹점\s*[:：]\s*(.+)');
        expect(json['date_regex'], r'(\d{2})/(\d{2})');
        expect(json['sample_sms'], '[Web발신]');
        expect(json['is_system'], true);
        expect(json['confidence'], 0.95);
      });

      test('기본값이 올바르게 설정된다', () {
        final json = LearnedSmsFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          amountRegex: r'\d+원',
        );

        expect(json['sender_keywords'], isEmpty);
        expect(json['type_keywords'], FinancialConstants.defaultTypeKeywords);
        expect(json['is_system'], false);
        expect(json['confidence'], 0.8);
      });

      test('null 필드들은 JSON에 포함되지 않는다', () {
        final json = LearnedSmsFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          amountRegex: r'\d+원',
        );

        expect(json.containsKey('merchant_regex'), false);
        expect(json.containsKey('date_regex'), false);
        expect(json.containsKey('sample_sms'), false);
      });
    });

    group('fromEntity / toEntity', () {
      test('Entity를 Model로 변환할 수 있다', () {
        final entity = LearnedSmsFormat(
          id: 'entity-id',
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          senderKeywords: ['KB카드'],
          amountRegex: r'\d+원',
          typeKeywords: {'expense': ['승인']},
          isSystem: true,
          confidence: 0.9,
          matchCount: 15,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final model = LearnedSmsFormatModel.fromEntity(entity);

        expect(model.id, entity.id);
        expect(model.paymentMethodId, entity.paymentMethodId);
        expect(model.senderPattern, entity.senderPattern);
        expect(model.senderKeywords, entity.senderKeywords);
        expect(model.amountRegex, entity.amountRegex);
        expect(model.typeKeywords, entity.typeKeywords);
        expect(model.isSystem, entity.isSystem);
        expect(model.confidence, entity.confidence);
        expect(model.matchCount, entity.matchCount);
      });

      test('Model을 Entity로 변환할 수 있다', () {
        final entity = learnedFormatModel.toEntity();

        expect(entity, isA<LearnedSmsFormat>());
        expect(entity.id, learnedFormatModel.id);
        expect(entity.paymentMethodId, learnedFormatModel.paymentMethodId);
        expect(entity.senderPattern, learnedFormatModel.senderPattern);
        expect(entity.senderKeywords, learnedFormatModel.senderKeywords);
        expect(entity.amountRegex, learnedFormatModel.amountRegex);
        expect(entity.typeKeywords, learnedFormatModel.typeKeywords);
        expect(entity.isSystem, learnedFormatModel.isSystem);
        expect(entity.confidence, learnedFormatModel.confidence);
        expect(entity.matchCount, learnedFormatModel.matchCount);
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'payment_method_id': 'payment-method-id',
          'sender_pattern': 'KB',
          'sender_keywords': ['KB카드'],
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인', '결제'],
          },
          'merchant_regex': r'가맹점\s*[:：]\s*(.+)',
          'date_regex': r'(\d{2})/(\d{2})',
          'sample_sms': '[Web발신]',
          'is_system': false,
          'confidence': 0.9,
          'match_count': 10,
          'created_at': '2026-02-12T10:00:00.000Z',
          'updated_at': '2026-02-12T11:00:00.000Z',
        };

        final model = LearnedSmsFormatModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['sender_pattern'], originalJson['sender_pattern']);
        expect(convertedJson['amount_regex'], originalJson['amount_regex']);
        expect(convertedJson['confidence'], originalJson['confidence']);
        expect(convertedJson['match_count'], originalJson['match_count']);
      });
    });

    group('엣지 케이스', () {
      test('빈 senderKeywords를 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'payment_method_id': 'payment-method-id',
          'sender_pattern': 'KB',
          'sender_keywords': [],
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인'],
          },
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedSmsFormatModel.fromJson(json);

        expect(result.senderKeywords, isEmpty);
      });

      test('복잡한 typeKeywords를 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'payment_method_id': 'payment-method-id',
          'sender_pattern': 'KB',
          'sender_keywords': [],
          'amount_regex': r'\d+원',
          'type_keywords': {
            'expense': ['승인', '결제'],
            'income': ['입금'],
          },
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = LearnedSmsFormatModel.fromJson(json);

        expect(result.typeKeywords['expense'], ['승인', '결제']);
        expect(result.typeKeywords['income'], ['입금']);
      });

      test('매우 긴 정규식을 처리할 수 있다', () {
        final longRegex = r'(\d{1,3}(,\d{3})*|\d+)' * 10;
        final json = LearnedSmsFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          amountRegex: longRegex,
        );

        expect(json['amount_regex'], longRegex);
      });

      test('confidence 경계값을 처리할 수 있다', () {
        final json1 = LearnedSmsFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          amountRegex: r'\d+원',
          confidence: 0.0,
        );
        final json2 = LearnedSmsFormatModel.toCreateJson(
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          amountRegex: r'\d+원',
          confidence: 1.0,
        );

        expect(json1['confidence'], 0.0);
        expect(json2['confidence'], 1.0);
      });

      test('매우 긴 sampleSms를 처리할 수 있다', () {
        final longSms = '[Web발신]\n' * 100;
        final model = LearnedSmsFormatModel(
          id: learnedFormatModel.id,
          paymentMethodId: learnedFormatModel.paymentMethodId,
          senderPattern: learnedFormatModel.senderPattern,
          senderKeywords: learnedFormatModel.senderKeywords,
          amountRegex: learnedFormatModel.amountRegex,
          typeKeywords: learnedFormatModel.typeKeywords,
          merchantRegex: learnedFormatModel.merchantRegex,
          dateRegex: learnedFormatModel.dateRegex,
          sampleSms: longSms,
          isSystem: learnedFormatModel.isSystem,
          confidence: learnedFormatModel.confidence,
          matchCount: learnedFormatModel.matchCount,
          createdAt: learnedFormatModel.createdAt,
          updatedAt: learnedFormatModel.updatedAt,
        );
        final json = model.toJson();

        expect(json['sample_sms'], longSms);
      });
    });
  });
}
