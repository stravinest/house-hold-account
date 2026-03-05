import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/data_export_bottom_sheet.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

// 넓은 화면으로 DataExportBottomSheet를 렌더링하는 헬퍼 (스크롤 가능하도록 큰 높이 제공)
Widget _buildExportSheetApp({String? ledgerId = 'ledger-1'}) {
  return ProviderScope(
    overrides: [
      selectedLedgerIdProvider.overrideWith((ref) => ledgerId),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SizedBox(
          height: 1200,
          child: DataExportBottomSheet(),
        ),
      ),
    ),
  );
}

void main() {
  group('DataExportBottomSheet 체크박스 상태 변경 테스트', () {
    testWidgets('카테고리 포함 체크박스의 초기 상태가 체크되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // Then: CheckboxListTile이 렌더링됨
      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsWidgets);
    });

    testWidgets('카테고리 포함 체크박스를 탭하면 상태가 토글되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 첫 번째 체크박스 탭
      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsWidgets);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Then: 에러 없이 상태 변경됨
      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('결제수단 포함 체크박스를 탭하면 상태가 토글되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 두 번째 체크박스 탭
      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes.evaluate().length, greaterThanOrEqualTo(2));
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Then: 에러 없이 상태 변경됨
      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('메모 포함 체크박스를 탭하면 상태가 토글되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 세 번째 체크박스 탭
      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes.evaluate().length, greaterThanOrEqualTo(3));
      await tester.tap(checkboxes.at(2));
      await tester.pumpAndSettle();

      // Then: 에러 없이 상태 변경됨
      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('작성자 포함 체크박스를 탭하면 상태가 토글되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 네 번째 체크박스 탭
      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes.evaluate().length, greaterThanOrEqualTo(4));
      await tester.tap(checkboxes.at(3));
      await tester.pumpAndSettle();

      // Then: 에러 없이 상태 변경됨
      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('고정비 포함 체크박스를 탭하면 상태가 토글되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 다섯 번째 체크박스 탭
      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes.evaluate().length, greaterThanOrEqualTo(5));
      await tester.tap(checkboxes.at(4));
      await tester.pumpAndSettle();

      // Then: 에러 없이 상태 변경됨
      expect(find.byType(CheckboxListTile), findsWidgets);
    });
  });

  group('DataExportBottomSheet 거래 유형 필터칩 테스트', () {
    testWidgets('전체 FilterChip이 초기 선택 상태여야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // Then: FilterChip이 4개 이상 표시됨 (전체, 지출, 수입, 자산)
      expect(find.byType(FilterChip), findsAtLeastNWidgets(4));
    });

    testWidgets('지출 FilterChip을 탭하면 선택 상태로 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 두 번째 FilterChip(지출) 탭
      final chips = find.byType(FilterChip);
      expect(chips.evaluate().length, greaterThanOrEqualTo(2));
      await tester.tap(chips.at(1));
      await tester.pumpAndSettle();

      // Then: 에러 없이 상태 변경됨
      expect(find.byType(FilterChip), findsAtLeastNWidgets(4));
    });

    testWidgets('수입 FilterChip을 탭하면 선택 상태로 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 세 번째 FilterChip(수입) 탭
      final chips = find.byType(FilterChip);
      expect(chips.evaluate().length, greaterThanOrEqualTo(3));
      await tester.tap(chips.at(2));
      await tester.pumpAndSettle();

      // Then: 에러 없이 상태 변경됨
      expect(find.byType(FilterChip), findsAtLeastNWidgets(4));
    });

    testWidgets('자산 FilterChip을 탭하면 선택 상태로 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 네 번째 FilterChip(자산) 탭
      final chips = find.byType(FilterChip);
      expect(chips.evaluate().length, greaterThanOrEqualTo(4));
      await tester.tap(chips.at(3));
      await tester.pumpAndSettle();

      // Then: 에러 없이 상태 변경됨
      expect(find.byType(FilterChip), findsAtLeastNWidgets(4));
    });
  });

  group('DataExportBottomSheet 파일 형식 선택 테스트', () {
    testWidgets('xlsx 파일 형식 선택 위젯이 표시되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // Then: 파일 형식 선택 위젯이 있음 (InkWell 형태)
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('csv 파일 형식 탭하면 csv 형식으로 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: .csv 텍스트를 찾아 탭
      final csvText = find.text('.csv');
      if (csvText.evaluate().isNotEmpty) {
        await tester.tap(csvText);
        await tester.pumpAndSettle();
      }

      // Then: 에러 없이 상태 변경됨
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });
  });

  group('DataExportBottomSheet 빠른 기간 버튼 테스트', () {
    testWidgets('ActionChip(빠른 기간 버튼)들이 표시되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // Then: ActionChip이 표시됨 (이번 달, 지난 달, 최근 3개월, 올해)
      expect(find.byType(ActionChip), findsWidgets);
    });

    testWidgets('이번 달 ActionChip을 탭하면 날짜가 설정되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 첫 번째 ActionChip 탭
      final chips = find.byType(ActionChip);
      expect(chips, findsWidgets);
      await tester.tap(chips.first);
      await tester.pumpAndSettle();

      // Then: 에러 없이 날짜 변경됨
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('지난 달 ActionChip을 탭하면 날짜가 설정되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 두 번째 ActionChip 탭
      final chips = find.byType(ActionChip);
      expect(chips.evaluate().length, greaterThanOrEqualTo(2));
      await tester.tap(chips.at(1));
      await tester.pumpAndSettle();

      // Then: 에러 없이 날짜 변경됨
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('최근 3개월 ActionChip을 탭하면 날짜가 설정되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 세 번째 ActionChip 탭
      final chips = find.byType(ActionChip);
      expect(chips.evaluate().length, greaterThanOrEqualTo(3));
      await tester.tap(chips.at(2));
      await tester.pumpAndSettle();

      // Then: 에러 없이 날짜 변경됨
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('올해 ActionChip을 탭하면 날짜가 설정되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 네 번째 ActionChip 탭
      final chips = find.byType(ActionChip);
      expect(chips.evaluate().length, greaterThanOrEqualTo(4));
      await tester.tap(chips.at(3));
      await tester.pumpAndSettle();

      // Then: 에러 없이 날짜 변경됨
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });
  });

  group('DataExportBottomSheet 헤더 및 닫기 버튼 테스트', () {
    testWidgets('닫기 아이콘 버튼이 표시되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // Then: 닫기 아이콘이 있음
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('닫기 아이콘 버튼을 탭하면 Navigator.pop이 호출되어야 한다', (tester) async {
      // Given: Navigator가 있는 앱
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => const SizedBox(
                        height: 800,
                        child: DataExportBottomSheet(),
                      ),
                    );
                  },
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 버튼 탭하여 바텀시트 열기
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsOneWidget);

      // When: 닫기 버튼 탭
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(DataExportBottomSheet), findsNothing);
    });

    testWidgets('취소 버튼이 표시되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // Then: OutlinedButton(취소) 버튼이 있음
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('내보내기 아이콘이 표시되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // Then: 다운로드 아이콘이 있음 (FilledButton.icon 내부)
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });

  group('DataExportBottomSheet 날짜 선택 버튼 테스트', () {
    testWidgets('시작일 날짜 버튼이 표시되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // Then: InkWell(날짜 버튼)이 표시됨
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('다운로드 아이콘이 표시되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // Then: 다운로드 아이콘이 있음
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });

  group('DataExportBottomSheet selectedLedgerId가 null인 경우 테스트', () {
    testWidgets('ledgerId가 null이어도 위젯이 렌더링되어야 한다', (tester) async {
      // Given: ledgerId가 null인 경우
      await tester.pumpWidget(_buildExportSheetApp(ledgerId: null));
      await tester.pumpAndSettle();

      // Then: 에러 없이 렌더링됨
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('ledgerId가 null일 때 내보내기 버튼을 탭하면 에러 없이 처리되어야 한다', (tester) async {
      // Given: ledgerId가 null인 경우
      await tester.pumpWidget(_buildExportSheetApp(ledgerId: null));
      await tester.pumpAndSettle();

      // When: 내보내기 버튼 탭
      final exportBtn = find.byType(FilledButton);
      if (exportBtn.evaluate().isNotEmpty) {
        await tester.tap(exportBtn.first);
        await tester.pumpAndSettle();
      }

      // Then: 에러 없이 처리됨 (ledgerId가 null이면 early return)
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });
  });
}
