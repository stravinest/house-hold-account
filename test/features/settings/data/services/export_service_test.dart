import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/data/services/export_service.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  // Flutter 바인딩 초기화 (path_provider 등이 필요)
  TestWidgetsFlutterBinding.ensureInitialized();

  // path_provider 플러그인 mock 설정
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    },
  );

  group('ExportService Tests', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      // 한국어 Locale로 AppLocalizations 생성
      l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    });

    group('exportToExcel', () {
      test('빈 거래 목록을 Excel로 내보낼 수 있다', () async {
        // Given: 빈 거래 목록
        final transactions = <Transaction>[];
        final options = ExportOptions(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then: 파일이 생성되었는지 확인
        expect(file.existsSync(), isTrue);
        expect(file.path.endsWith('.xlsx'), isTrue);

        // Cleanup
        await file.delete();
      });

      test('거래 목록을 Excel로 내보낼 수 있다', () async {
        // Given
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 50000,
            type: 'expense',
            title: '점심 식사',
            date: DateTime(2026, 2, 12),
          ),
          TestDataFactory.transaction(
            id: 'tx2',
            amount: 100000,
            type: 'income',
            title: '월급',
            date: DateTime(2026, 2, 15),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then
        expect(file.existsSync(), isTrue);
        expect(file.path.endsWith('.xlsx'), isTrue);
        expect(file.lengthSync(), greaterThan(0));

        // Cleanup
        await file.delete();
      });

      test('날짜 범위에 맞는 거래만 내보낸다', () async {
        // Given
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 10000,
            type: 'expense',
            date: DateTime(2026, 1, 15),
          ),
          TestDataFactory.transaction(
            id: 'tx2',
            amount: 20000,
            type: 'expense',
            date: DateTime(2026, 2, 15),
          ),
          TestDataFactory.transaction(
            id: 'tx3',
            amount: 30000,
            type: 'expense',
            date: DateTime(2026, 3, 15),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then
        expect(file.existsSync(), isTrue);

        // Cleanup
        await file.delete();
      });

      test('특정 거래 타입만 필터링하여 내보낼 수 있다', () async {
        // Given
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 10000,
            type: 'expense',
            date: DateTime(2026, 2, 1),
          ),
          TestDataFactory.transaction(
            id: 'tx2',
            amount: 20000,
            type: 'income',
            date: DateTime(2026, 2, 2),
          ),
          TestDataFactory.transaction(
            id: 'tx3',
            amount: 30000,
            type: 'asset',
            date: DateTime(2026, 2, 3),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          transactionType: 'expense',
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then
        expect(file.existsSync(), isTrue);

        // Cleanup
        await file.delete();
      });

      test('선택한 컬럼만 포함하여 내보낼 수 있다', () async {
        // Given
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 10000,
            type: 'expense',
            title: '테스트',
            date: DateTime(2026, 2, 1),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          includeCategory: false,
          includePaymentMethod: false,
          includeMemo: false,
          includeAuthor: false,
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then: 파일이 정상 생성됨
        expect(file.existsSync(), isTrue);

        // Cleanup
        await file.delete();
      });
    });

    group('exportToCsv', () {
      test('거래 목록을 CSV로 내보낼 수 있다', () async {
        // Given
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 50000,
            type: 'expense',
            title: '점심 식사',
            date: DateTime(2026, 2, 12),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          format: ExportFileFormat.csv,
        );

        // When
        final file = await ExportService.exportToCsv(
          transactions,
          options,
          l10n: l10n,
        );

        // Then
        expect(file.existsSync(), isTrue);
        expect(file.path.endsWith('.csv'), isTrue);

        // CSV 파일은 BOM + UTF-8로 인코딩됨
        final bytes = await file.readAsBytes();
        expect(bytes.length, greaterThan(3)); // BOM(3바이트) + 데이터

        // Cleanup
        await file.delete();
      });

      test('빈 거래 목록을 CSV로 내보낼 수 있다', () async {
        // Given
        final transactions = <Transaction>[];
        final options = ExportOptions(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          format: ExportFileFormat.csv,
        );

        // When
        final file = await ExportService.exportToCsv(
          transactions,
          options,
          l10n: l10n,
        );

        // Then
        expect(file.existsSync(), isTrue);

        // Cleanup
        await file.delete();
      });

      test('한글 상호명이 포함된 거래를 CSV로 내보낼 수 있다', () async {
        // Given: 한글 데이터 포함
        final transactions = [
          TestDataFactory.transaction(
            id: 'tx1',
            amount: 50000,
            type: 'expense',
            title: '스타벅스 강남점',
            date: DateTime(2026, 2, 12),
          ),
          TestDataFactory.transaction(
            id: 'tx2',
            amount: 30000,
            type: 'expense',
            title: '교보문고 광화문',
            date: DateTime(2026, 2, 15),
          ),
        ];
        final options = ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          format: ExportFileFormat.csv,
        );

        // When
        final file = await ExportService.exportToCsv(
          transactions,
          options,
          l10n: l10n,
        );

        // Then: BOM이 포함되어 한글 인코딩 보장
        final bytes = await file.readAsBytes();
        expect(bytes[0], equals(0xEF)); // BOM 첫 번째 바이트
        expect(bytes[1], equals(0xBB)); // BOM 두 번째 바이트
        expect(bytes[2], equals(0xBF)); // BOM 세 번째 바이트

        // Cleanup
        await file.delete();
      });
    });

    group('ExportOptions', () {
      test('기본 옵션으로 ExportOptions를 생성할 수 있다', () {
        // Given & When
        final options = ExportOptions(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
        );

        // Then
        expect(options.includeCategory, isTrue);
        expect(options.includePaymentMethod, isTrue);
        expect(options.includeMemo, isTrue);
        expect(options.includeAuthor, isFalse);
        expect(options.includeFixedExpense, isFalse);
        expect(options.format, equals(ExportFileFormat.xlsx));
        expect(options.transactionType, isNull);
      });

      test('커스텀 옵션으로 ExportOptions를 생성할 수 있다', () {
        // Given & When
        final options = ExportOptions(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          transactionType: 'expense',
          includeCategory: false,
          includePaymentMethod: false,
          includeMemo: false,
          includeAuthor: true,
          includeFixedExpense: true,
          format: ExportFileFormat.csv,
        );

        // Then
        expect(options.transactionType, equals('expense'));
        expect(options.includeCategory, isFalse);
        expect(options.includePaymentMethod, isFalse);
        expect(options.includeMemo, isFalse);
        expect(options.includeAuthor, isTrue);
        expect(options.includeFixedExpense, isTrue);
        expect(options.format, equals(ExportFileFormat.csv));
      });
    });

    group('File Format', () {
      test('xlsx 파일명을 올바르게 생성한다', () async {
        // Given
        final transactions = [TestDataFactory.transaction()];
        final options = ExportOptions(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          format: ExportFileFormat.xlsx,
        );

        // When
        final file = await ExportService.exportToExcel(
          transactions,
          options,
          l10n: l10n,
        );

        // Then: ledger_YYMMDD_HHMM.xlsx 형식
        expect(file.path, contains('ledger_'));
        expect(file.path, endsWith('.xlsx'));

        // Cleanup
        await file.delete();
      });

      test('csv 파일명을 올바르게 생성한다', () async {
        // Given
        final transactions = [TestDataFactory.transaction()];
        final options = ExportOptions(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          format: ExportFileFormat.csv,
        );

        // When
        final file = await ExportService.exportToCsv(
          transactions,
          options,
          l10n: l10n,
        );

        // Then
        expect(file.path, contains('ledger_'));
        expect(file.path, endsWith('.csv'));

        // Cleanup
        await file.delete();
      });
    });
  });
}
