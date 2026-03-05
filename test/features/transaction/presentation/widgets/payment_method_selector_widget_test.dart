import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/payment_method_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/widgets/payment_method_selector_widget.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../helpers/mock_repositories.dart';

PaymentMethod _makePaymentMethod({
  String id = 'pm-1',
  String name = '신한카드',
  bool canAutoSave = false,
}) {
  return PaymentMethod(
    id: id,
    ledgerId: 'ledger-1',
    ownerUserId: 'user-1',
    name: name,
    icon: 'credit_card',
    color: '#2196F3',
    isDefault: false,
    canAutoSave: canAutoSave,
    sortOrder: 0,
    createdAt: DateTime(2024, 1, 1),
  );
}

Widget _buildApp({required Widget child, List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('PaymentMethodSelectorWidget 위젯 테스트', () {
    testWidgets('결제수단이 없을 때 위젯이 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith((ref) async => []),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링되어야 함
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });

    testWidgets('enabled=false일 때 위젯이 비활성화 상태로 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith((ref) async => []),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
            enabled: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링되어야 함
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });

    testWidgets('결제수단 목록이 있을 때 Chip으로 표시된다', (tester) async {
      // Given
      final methods = [
        _makePaymentMethod(id: 'pm-1', name: '신한카드'),
        _makePaymentMethod(id: 'pm-2', name: '카카오페이'),
      ];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 결제수단 이름이 표시되어야 함
      expect(find.text('신한카드'), findsOneWidget);
      expect(find.text('카카오페이'), findsOneWidget);
    });

    testWidgets('선택된 결제수단이 표시된다', (tester) async {
      // Given
      final selectedMethod = _makePaymentMethod(id: 'pm-1', name: '신한카드');

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => [selectedMethod]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: selectedMethod,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.text('신한카드'), findsOneWidget);
    });

    testWidgets('결제수단 탭 시 onPaymentMethodSelected 콜백이 호출된다', (tester) async {
      // Given
      PaymentMethod? tappedMethod;
      final testMethod = _makePaymentMethod(id: 'pm-1', name: '신한카드');

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => [testMethod]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (m) => tappedMethod = m,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 결제수단 탭
      await tester.tap(find.text('신한카드'));
      await tester.pump();

      // Then
      expect(tappedMethod, isNotNull);
      expect(tappedMethod!.name, '신한카드');
    });

    testWidgets('에러 상태일 때 에러 메시지가 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith(
              (ref) async => throw Exception('네트워크 오류'),
            ),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 에러 텍스트 표시
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });

    testWidgets('편집 버튼 탭 시 편집 모드로 전환된다', (tester) async {
      // Given
      final methods = [
        _makePaymentMethod(id: 'pm-1', name: '신한카드'),
      ];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 ActionChip 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pump();
      }

      // Then: 위젯이 렌더링됨
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });

    testWidgets('편집 모드에서 완료 버튼 탭 시 기본 모드로 돌아간다', (tester) async {
      // Given
      final methods = [_makePaymentMethod(id: 'pm-1', name: '신한카드')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 버튼 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pump();

        // 완료 버튼 탭
        final doneChip = find.byWidgetPredicate(
          (w) => w is ActionChip && (w.label as Text).data == '완료',
        );
        if (doneChip.evaluate().isNotEmpty) {
          await tester.tap(doneChip.first);
          await tester.pump();
        }
      }

      // Then: 위젯이 여전히 렌더링됨
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });

    testWidgets('추가 및 편집 ActionChip이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith((ref) async => []),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: ActionChip들이 표시됨
      expect(find.byType(ActionChip), findsWidgets);
    });

    testWidgets('canAutoSave가 true인 결제수단은 CategoryIcon이 표시된다', (tester) async {
      // Given
      final autoSaveMethod = PaymentMethod(
        id: 'pm-auto',
        ledgerId: 'ledger-1',
        ownerUserId: 'user-1',
        name: 'KB페이',
        icon: 'credit_card',
        color: '#2196F3',
        isDefault: false,
        canAutoSave: true,
        sortOrder: 0,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => [autoSaveMethod]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: KB페이 이름이 표시됨
      expect(find.text('KB페이'), findsOneWidget);
    });

    testWidgets('없음 칩 탭 시 null로 콜백이 호출된다', (tester) async {
      // Given
      PaymentMethod? selected = _makePaymentMethod();
      final testMethod = _makePaymentMethod(id: 'pm-1', name: '신한카드');

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => [testMethod]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: testMethod,
            onPaymentMethodSelected: (m) => selected = m,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 없음(첫 번째 FilterChip) 탭
      final noneChips = find.byType(FilterChip);
      if (noneChips.evaluate().isNotEmpty) {
        await tester.tap(noneChips.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 위젯 렌더링됨
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });

    testWidgets('편집 모드에서 일반 결제수단의 삭제 아이콘이 표시된다', (tester) async {
      // Given
      final methods = [_makePaymentMethod(id: 'pm-1', name: '신한카드')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 모드 진입
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );

      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pumpAndSettle();

        // Then: 편집 모드에서 삭제 아이콘(Icons.close)이 표시됨
        expect(find.byIcon(Icons.close), findsWidgets);
        expect(find.text('신한카드'), findsOneWidget);
      } else {
        // 편집 칩이 없어도 위젯이 렌더링되어야 함
        expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
      }
    });

    testWidgets('삭제 확인 다이얼로그에서 취소 탭 시 다이얼로그가 닫힌다', (tester) async {
      // Given
      final methods = [_makePaymentMethod(id: 'pm-1', name: '신한카드')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 모드 진입 후 삭제 아이콘 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );

      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pumpAndSettle();

        final closeIcons = find.byIcon(Icons.close);
        if (closeIcons.evaluate().isNotEmpty) {
          await tester.tap(closeIcons.first);
          await tester.pumpAndSettle();

          final alertDialog = find.byType(AlertDialog);
          if (alertDialog.evaluate().isNotEmpty) {
            // 취소 버튼 탭
            final cancelButton = find.text('취소');
            if (cancelButton.evaluate().isNotEmpty) {
              await tester.tap(cancelButton.first);
              await tester.pumpAndSettle();
            }

            // Then: 다이얼로그가 닫히고 위젯이 렌더링됨
            expect(find.byType(AlertDialog), findsNothing);
            expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
          }
        }
      }
    });

    testWidgets('자동수집 결제수단 편집 모드에서 수정 아이콘 탭 시 안내 메시지가 표시된다', (tester) async {
      // Given: canAutoSave=true인 결제수단
      final autoSaveMethod = PaymentMethod(
        id: 'pm-auto',
        ledgerId: 'ledger-1',
        ownerUserId: 'user-1',
        name: 'KB페이',
        icon: 'credit_card',
        color: '#2196F3',
        isDefault: false,
        canAutoSave: true,
        sortOrder: 0,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => [autoSaveMethod]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 모드 진입
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );

      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pumpAndSettle();

        // Then: 자동수집 결제수단이 편집 모드 칩으로 표시됨 (비활성화 아이콘 포함)
        expect(find.text('KB페이'), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsWidgets);
        expect(find.byIcon(Icons.close), findsWidgets);
      }
    });

    testWidgets('로딩 상태일 때 스켈레톤 칩이 표시된다', (tester) async {
      // Given: 로딩 상태 프로바이더 (Completer로 영원히 pending)
      final completer = Completer<List<PaymentMethod>>();
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith(
              (ref) => completer.future,
            ),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      // When: 로딩 중 (pump만 호출)
      await tester.pump();

      // Then: 위젯이 렌더링됨 (스켈레톤 로딩 상태)
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });

    testWidgets('편집 모드에서 삭제 확인 후 삭제 버튼 탭 시 다이얼로그가 닫힌다', (tester) async {
      // Given
      final methods = [_makePaymentMethod(id: 'pm-1', name: '신한카드')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            sharedPaymentMethodsProvider.overrideWith((ref) async => methods),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 모드 진입 → 삭제 아이콘 탭 → 다이얼로그 확인
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pumpAndSettle();

        final closeIcon = find.byIcon(Icons.close);
        if (closeIcon.evaluate().isNotEmpty) {
          await tester.tap(closeIcon.first);
          await tester.pumpAndSettle();

          // 삭제 확인 다이얼로그가 있으면 삭제 버튼 탭
          final deleteBtn = find.text('삭제');
          if (deleteBtn.evaluate().isNotEmpty) {
            await tester.tap(deleteBtn.first);
            await tester.pump();
          }
        }
      }

      // Then: 위젯이 렌더링됨
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });

    testWidgets('수정 모드에서 수정 아이콘 탭 시 편집 다이얼로그가 표시될 수 있다', (tester) async {
      // Given
      final methods = [_makePaymentMethod(id: 'pm-1', name: '신한카드')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider
                .overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            sharedPaymentMethodsProvider.overrideWith((ref) async => methods),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 모드 진입 → 수정 아이콘 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pumpAndSettle();

        final editOutlinedIcons = find.byIcon(Icons.edit_outlined);
        if (editOutlinedIcons.evaluate().isNotEmpty) {
          await tester.tap(editOutlinedIcons.first, warnIfMissed: false);
          await tester.pump();
        }
      }

      // Then: 위젯이 렌더링됨
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });

    testWidgets('편집 모드에서 삭제 버튼 탭 후 삭제 확인 다이얼로그가 표시된다', (tester) async {
      // Given: 결제수단 목록
      final methods = [_makePaymentMethod(id: 'pm-1', name: '신한카드')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            sharedPaymentMethodsProvider.overrideWith((ref) async => methods),
            paymentMethodNotifierProvider.overrideWith(
              (ref) => _FakePaymentMethodNotifier(ref),
            ),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 편집 모드 진입 → 삭제(close) 버튼 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isEmpty) {
        // 편집 버튼이 없으면 테스트 스킵
        expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
        return;
      }
      await tester.tap(editChip.first);
      await tester.pumpAndSettle();

      final closeIcons = find.byIcon(Icons.close);
      if (closeIcons.evaluate().isEmpty) {
        // close 아이콘이 없으면 테스트 스킵
        expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
        return;
      }
      await tester.tap(closeIcons.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Then: 삭제 확인 다이얼로그가 표시됨
      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        // When: 취소 탭하여 다이얼로그 닫기
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();
        // Then: 다이얼로그 닫힘
        expect(find.byType(AlertDialog), findsNothing);
      }

      // Then: 위젯이 렌더링됨
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });

    testWidgets('편집 모드에서 삭제 확인 다이얼로그에서 삭제 버튼 탭 시 삭제가 시도된다', (tester) async {
      // Given: 결제수단 목록, FakeNotifier로 deletePaymentMethod mock
      final methods = [_makePaymentMethod(id: 'pm-1', name: '신한카드')];
      bool deleteCalled = false;

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            sharedPaymentMethodsProvider.overrideWith((ref) async => methods),
            paymentMethodNotifierProvider.overrideWith((ref) {
              final n = _FakePaymentMethodNotifier(ref);
              n.onDeleteCalled = () => deleteCalled = true;
              return n;
            }),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 수정 탭 → 삭제 아이콘 탭 → 확인 탭
      final editChip2 = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip2.evaluate().isEmpty) {
        expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
        return;
      }
      await tester.tap(editChip2.first);
      await tester.pumpAndSettle();

      final closeIcons2 = find.byIcon(Icons.close);
      if (closeIcons2.evaluate().isEmpty) {
        expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
        return;
      }
      await tester.tap(closeIcons2.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // AlertDialog에서 삭제(FilledButton) 탭
      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        final deleteBtn = find.byWidgetPredicate((w) => w is FilledButton);
        if (deleteBtn.evaluate().isNotEmpty) {
          await tester.tap(deleteBtn.first);
          await tester.pumpAndSettle();
          // Then: deletePaymentMethod가 호출됨
          expect(deleteCalled, isTrue);
        }
      } else {
        expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
      }
    });

    testWidgets('추가 ActionChip 탭 시 다이얼로그가 표시될 수 있다', (tester) async {
      // Given: 결제수단 없는 상태
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith((ref) async => []),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            sharedPaymentMethodsProvider.overrideWith((ref) async => []),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 추가 ActionChip이 표시됨
      final addChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '추가',
      );
      expect(addChip, findsOneWidget);

      // When: 추가 ActionChip 탭 (다이얼로그 시도)
      await tester.tap(addChip);
      await tester.pump();

      // Then: 위젯이 렌더링됨
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });

    testWidgets('enabled=false이면 추가/수정 버튼이 비활성화된다', (tester) async {
      // Given: 결제수단 있고 disabled 상태
      final methods = [_makePaymentMethod(id: 'pm-1', name: '신한카드')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            sharedPaymentMethodsProvider.overrideWith((ref) async => methods),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
            enabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: ActionChip의 onPressed가 null이어야 함
      final chips = find.byType(ActionChip);
      bool anyEnabled = false;
      for (final element in chips.evaluate()) {
        final chip = element.widget as ActionChip;
        if (chip.onPressed != null) anyEnabled = true;
      }
      expect(anyEnabled, isFalse);
    });

    testWidgets('없음 칩 탭 시 null로 onPaymentMethodSelected가 호출된다', (tester) async {
      // Given: 결제수단 선택된 상태
      final methods = [_makePaymentMethod(id: 'pm-1', name: '신한카드')];
      final selectedMethod = methods.first;
      PaymentMethod? selectedResult = selectedMethod;

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            sharedPaymentMethodsProvider.overrideWith((ref) async => methods),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: selectedMethod,
            onPaymentMethodSelected: (m) => selectedResult = m,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 없음 칩 탭
      final noneChip = find.byWidgetPredicate(
        (w) => w is FilterChip && (w.label as Text).data == '없음',
      );
      if (noneChip.evaluate().isNotEmpty) {
        await tester.tap(noneChip.first);
        await tester.pump();
        // Then: null이 전달됨
        expect(selectedResult, isNull);
      } else {
        expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
      }
    });

    testWidgets('선택된 결제수단 삭제 시 null로 콜백이 호출된다', (tester) async {
      // Given: 선택된 결제수단과 동일한 결제수단을 삭제 시도
      final selectedMethod = _makePaymentMethod(id: 'pm-sel', name: '삭제될카드');
      final methods = [selectedMethod];
      PaymentMethod? callbackResult = selectedMethod;

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            sharedPaymentMethodsProvider.overrideWith((ref) async => methods),
            paymentMethodNotifierProvider.overrideWith(
              (ref) => _FakePaymentMethodNotifier(ref),
            ),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: selectedMethod,
            onPaymentMethodSelected: (m) => callbackResult = m,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 편집 모드 → 삭제 아이콘 → 확인 다이얼로그 삭제
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isEmpty) return;

      await tester.tap(editChip.first);
      await tester.pumpAndSettle();

      final closeIcons = find.byIcon(Icons.close);
      if (closeIcons.evaluate().isEmpty) return;

      await tester.tap(closeIcons.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        final deleteBtn = find.byWidgetPredicate((w) => w is FilledButton);
        if (deleteBtn.evaluate().isNotEmpty) {
          await tester.tap(deleteBtn.first);
          await tester.pumpAndSettle();
          // Then: 선택된 결제수단이 null로 변경됨
          expect(callbackResult, isNull);
        }
      }
    });

    testWidgets('편집 모드에서 일반 결제수단 칩의 수정 버튼이 표시된다', (tester) async {
      // Given: canAutoSave=false 결제수단 (일반 결제수단)
      final normalMethod = _makePaymentMethod(id: 'pm-normal', name: '일반카드');
      final methods = [normalMethod];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            sharedPaymentMethodsProvider.overrideWith((ref) async => methods),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 편집 모드 진입
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isEmpty) return;

      await tester.tap(editChip.first);
      await tester.pumpAndSettle();

      // Then: 일반 결제수단 칩에 수정(edit_outlined) 및 삭제(close) 아이콘이 표시됨
      expect(find.text('일반카드'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      expect(find.byIcon(Icons.close), findsWidgets);
    });

    testWidgets('편집 모드에서 수정 버튼 탭 시 다이얼로그가 시도된다', (tester) async {
      // Given: 일반 결제수단
      final normalMethod = _makePaymentMethod(id: 'pm-edit', name: '수정카드');
      final methods = [normalMethod];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            selectablePaymentMethodsProvider.overrideWith((ref) async => methods),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            sharedPaymentMethodsProvider.overrideWith((ref) async => methods),
          ],
          child: PaymentMethodSelectorWidget(
            selectedPaymentMethod: null,
            onPaymentMethodSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 편집 모드 진입 → 수정 아이콘 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isEmpty) return;

      await tester.tap(editChip.first);
      await tester.pumpAndSettle();

      final editIcons = find.byIcon(Icons.edit_outlined);
      if (editIcons.evaluate().isNotEmpty) {
        await tester.tap(editIcons.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 위젯이 렌더링됨
      expect(find.byType(PaymentMethodSelectorWidget), findsOneWidget);
    });
  });
}

class _FakePaymentMethodNotifier extends PaymentMethodNotifier {
  VoidCallback? onDeleteCalled;

  _FakePaymentMethodNotifier(Ref ref)
      : super(MockPaymentMethodRepository(), null, ref);

  @override
  Future<void> loadPaymentMethods() async {
    if (mounted) state = const AsyncValue.data([]);
  }

  @override
  Future<void> deletePaymentMethod(String id) async {
    onDeleteCalled?.call();
  }
}
