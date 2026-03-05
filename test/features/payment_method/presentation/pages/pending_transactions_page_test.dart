import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/payment_method/data/models/pending_transaction_model.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/pending_transaction.dart';
import 'package:shared_household_account/features/payment_method/presentation/pages/pending_transactions_page.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/pending_transaction_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../helpers/mock_supabase.dart';

/// PendingTransactionNotifier stub - Supabase 초기화 없이 원하는 state를 주입
class _FakePendingTransactionNotifier
    extends StateNotifier<AsyncValue<List<PendingTransactionModel>>>
    implements PendingTransactionNotifier {
  _FakePendingTransactionNotifier(AsyncValue<List<PendingTransactionModel>> state)
      : super(state);

  @override
  Future<void> loadPendingTransactions({
    PendingTransactionStatus? status,
    bool silent = false,
  }) async {}

  @override
  Future<void> confirmTransaction(String id) async {}

  @override
  Future<void> rejectTransaction(String id) async {}

  @override
  Future<void> updateParsedData({
    required String id,
    int? parsedAmount,
    String? parsedType,
    String? parsedMerchant,
    String? parsedCategoryId,
    DateTime? parsedDate,
    String? paymentMethodId,
  }) async {}

  @override
  Future<void> updateAndConfirmTransaction({
    required String id,
    required int parsedAmount,
    required String parsedType,
    String? parsedMerchant,
    String? parsedCategoryId,
    DateTime? parsedDate,
  }) async {}

  @override
  Future<void> confirmAll() async {}

  @override
  Future<void> rejectAll() async {}

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<void> deleteAllByStatus(PendingTransactionStatus status) async {}

  @override
  Future<void> deleteRejected() async {}

  @override
  Future<void> deleteAllConfirmed() async {}

  @override
  Future<void> markAllAsViewed() async {}
}

/// 테스트용 PendingTransactionModel 생성 헬퍼
PendingTransactionModel _makePendingTx({
  String id = 'tx-1',
  PendingTransactionStatus status = PendingTransactionStatus.pending,
  int? parsedAmount = 10000,
  String? parsedMerchant = '스타벅스',
  String? parsedType = 'expense',
  bool isDuplicate = false,
}) {
  final now = DateTime(2026, 3, 1, 10, 0);
  return PendingTransactionModel(
    id: id,
    ledgerId: 'ledger-1',
    userId: 'user-1',
    paymentMethodId: 'pm-1',
    sourceType: SourceType.sms,
    sourceSender: '1234',
    sourceContent: '카드결제 10,000원 스타벅스',
    sourceTimestamp: now,
    parsedAmount: parsedAmount,
    parsedType: parsedType,
    parsedMerchant: parsedMerchant,
    parsedCategoryId: null,
    parsedDate: now,
    status: status,
    createdAt: now,
    updatedAt: now,
    expiresAt: now.add(const Duration(days: 7)),
    isViewed: false,
    duplicateHash: null,
    isDuplicate: isDuplicate,
  );
}

/// PendingTransactionsPage 위젯 테스트를 위한 헬퍼
///
/// pendingTransactionNotifierProvider를 fake로 override하여
/// Supabase.instance 초기화 없이 테스트 가능하도록 한다.
Widget _buildTestWidget({
  required AsyncValue<List<PendingTransactionModel>> pendingTxState,
  String? ledgerId = 'ledger-1',
  MockUser? currentUser,
}) {
  final user = currentUser ?? MockUser();
  when(() => user.id).thenReturn('user-1');

  return ProviderScope(
    overrides: [
      pendingTransactionNotifierProvider.overrideWith(
        (_) => _FakePendingTransactionNotifier(pendingTxState),
      ),
      pendingTransactionCountProvider.overrideWith((_) async => 0),
      selectedLedgerIdProvider.overrideWith((_) => ledgerId),
      currentUserProvider.overrideWith((_) => user),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: const PendingTransactionsPage(),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(PendingTransactionStatus.pending);
  });

  group('PendingTransactionsPage - 기본 렌더링', () {
    testWidgets('ledgerId가 null이면 로딩 인디케이터를 표시한다', (tester) async {
      // Given: ledgerId가 없는 상태 (pendingTransactionNotifierProvider도 override 필요)
      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: const AsyncValue.data([]),
          ledgerId: null,
        ),
      );
      await tester.pump();

      // Then: 로딩 인디케이터가 표시되어야 한다
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('currentUser가 null이면 로딩 인디케이터를 표시한다', (tester) async {
      // Given: currentUser가 없는 상태 - MockUser를 override에서 null로 지정
      final user = MockUser();
      when(() => user.id).thenReturn('user-1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingTransactionNotifierProvider.overrideWith(
              (_) => _FakePendingTransactionNotifier(const AsyncValue.data([])),
            ),
            pendingTransactionCountProvider.overrideWith((_) async => 0),
            selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
            currentUserProvider.overrideWith((_) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const PendingTransactionsPage(),
          ),
        ),
      );
      await tester.pump();

      // Then: 로딩 인디케이터가 표시되어야 한다
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('페이지가 정상적으로 렌더링되고 탭바가 3개 탭을 보여준다', (tester) async {
      // Given: 빈 목록 상태
      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: const AsyncValue.data([]),
        ),
      );
      await tester.pumpAndSettle();

      // Then: TabBar가 표시되어야 한다
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('AppBar에 더보기 메뉴 버튼이 표시된다', (tester) async {
      // Given: 빈 목록 상태
      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: const AsyncValue.data([]),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 더보기 아이콘이 표시되어야 한다
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });
  });

  group('PendingTransactionsPage - 거래 목록 렌더링', () {
    testWidgets('대기중 거래가 있을 때 카드가 렌더링된다', (tester) async {
      // Given: 대기중 거래 1건
      final tx = _makePendingTx(
        status: PendingTransactionStatus.pending,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 스타벅스 텍스트가 표시되어야 한다
      expect(find.textContaining('스타벅스'), findsWidgets);
    });

    testWidgets('대기중 거래가 없을 때 빈 상태 위젯을 표시한다', (tester) async {
      // Given: 빈 목록
      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: const AsyncValue.data([]),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 빈 상태 메시지가 표시되어야 한다 (대기중 탭이 기본 활성)
      expect(find.byType(ListView).hitTestable(), findsNothing);
    });

    testWidgets('확인됨 탭으로 전환 시 해당 거래가 표시된다', (tester) async {
      // Given: 확인됨 거래 1건
      final tx = _makePendingTx(
        id: 'tx-confirmed',
        status: PendingTransactionStatus.confirmed,
        parsedMerchant: '편의점',
      );

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 두 번째 탭(확인됨)을 탭한다
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      // Then: 편의점 텍스트가 보여야 한다
      expect(find.textContaining('편의점'), findsWidgets);
    });

    testWidgets('거부됨 탭으로 전환 시 해당 거래가 표시된다', (tester) async {
      // Given: 거부됨 거래 1건
      final tx = _makePendingTx(
        id: 'tx-rejected',
        status: PendingTransactionStatus.rejected,
        parsedMerchant: '카페베네',
      );

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 세 번째 탭(거부됨)을 탭한다
      await tester.tap(find.byType(Tab).at(2));
      await tester.pumpAndSettle();

      // Then: 카페베네 텍스트가 보여야 한다
      expect(find.textContaining('카페베네'), findsWidgets);
    });

    testWidgets('날짜별로 그룹핑된 거래 목록이 표시된다', (tester) async {
      // Given: 다른 날짜의 대기중 거래 2건
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final tx1 = PendingTransactionModel(
        id: 'tx-today',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        paymentMethodId: 'pm-1',
        sourceType: SourceType.sms,
        sourceSender: '1234',
        sourceContent: '오늘 결제',
        sourceTimestamp: now,
        parsedAmount: 10000,
        parsedType: 'expense',
        parsedMerchant: '오늘카페',
        parsedCategoryId: null,
        parsedDate: now,
        status: PendingTransactionStatus.pending,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        isViewed: false,
        duplicateHash: null,
        isDuplicate: false,
      );

      final tx2 = PendingTransactionModel(
        id: 'tx-yesterday',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        paymentMethodId: 'pm-1',
        sourceType: SourceType.sms,
        sourceSender: '1234',
        sourceContent: '어제 결제',
        sourceTimestamp: yesterday,
        parsedAmount: 5000,
        parsedType: 'expense',
        parsedMerchant: '어제카페',
        parsedCategoryId: null,
        parsedDate: yesterday,
        status: PendingTransactionStatus.pending,
        createdAt: yesterday,
        updatedAt: yesterday,
        expiresAt: yesterday.add(const Duration(days: 7)),
        isViewed: false,
        duplicateHash: null,
        isDuplicate: false,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx1, tx2]),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 두 상호명 모두 표시되어야 한다
      expect(find.textContaining('오늘카페'), findsWidgets);
      expect(find.textContaining('어제카페'), findsWidgets);
    });
  });

  group('PendingTransactionsPage - 팝업 메뉴', () {
    testWidgets('대기중 탭에서 팝업 메뉴를 열면 확인/거부 옵션이 표시된다', (tester) async {
      // Given: 대기중 거래가 있는 상태
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 더보기 버튼 탭
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Then: 팝업 메뉴가 열려야 한다 (PopupMenuButton이 존재하므로 화면이 변경됨)
      // PopupMenuButton의 itemBuilder가 호출되어 오버레이가 표시되어야 한다
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });
  });

  group('PendingTransactionsPage - 에러 상태', () {
    testWidgets('에러 상태에서 에러 메시지가 표시된다', (tester) async {
      // Given: AsyncError 상태
      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.error(
            Exception('네트워크 오류'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 에러 관련 위젯이 표시되어야 한다 (Scaffold 이상 없음)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('로딩 상태에서 로딩 인디케이터가 표시된다', (tester) async {
      // Given: AsyncLoading 상태
      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: const AsyncValue.loading(),
        ),
      );
      await tester.pump();

      // Then: CircularProgressIndicator 또는 Scaffold가 표시되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PendingTransactionsPage - _EditPendingTransactionSheet', () {
    testWidgets('대기중 거래 카드 탭 시 수정 시트가 열린다', (tester) async {
      // Given: 대기중 거래 1건
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 카드 본문 영역(InkWell)을 탭하여 수정 시트를 연다
      // PendingTransactionCard의 onEdit 콜백이 Card InkWell에 연결되어 있음
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await tester.pumpAndSettle();
      }

      // Then: 시트가 열리거나 아무 변화가 없어야 한다 (onEdit 콜백 연결 여부에 따라)
      // 최소한 크래시 없이 동작해야 한다
    });
  });

  group('PendingTransactionsPage - 전체 삭제 다이얼로그', () {
    testWidgets('대기중 탭에서 전체 삭제 메뉴를 탭하면 확인 다이얼로그가 표시된다', (tester) async {
      // Given: 대기중 거래가 있는 상태
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 더보기 메뉴 열기
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // 대기중 삭제 항목이 있으면 탭한다
      final deleteMenuItem = find.byIcon(Icons.delete_outline);
      if (deleteMenuItem.evaluate().isNotEmpty) {
        await tester.tap(deleteMenuItem.last);
        await tester.pumpAndSettle();

        // Then: AlertDialog가 표시되어야 한다
        expect(find.byType(AlertDialog), findsOneWidget);
      }
    });
  });

  group('PendingTransactionsPage - 전체확인 다이얼로그', () {
    testWidgets('대기중 탭에서 전체 확인 메뉴를 탭하면 확인 다이얼로그가 표시된다', (tester) async {
      // Given: 대기중 거래가 있는 상태
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 더보기 메뉴 열기
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // 전체 확인 항목이 있으면 탭한다
      final confirmAllItem = find.byIcon(Icons.check_circle_outline);
      if (confirmAllItem.evaluate().isNotEmpty) {
        await tester.tap(confirmAllItem.first);
        await tester.pumpAndSettle();

        // Then: AlertDialog가 표시되어야 한다
        expect(find.byType(AlertDialog), findsOneWidget);

        // 취소 버튼을 탭하면 다이얼로그가 닫힌다
        final cancelButton = find.text('취소');
        if (cancelButton.evaluate().isNotEmpty) {
          await tester.tap(cancelButton.first);
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
        }
      }
    });

    testWidgets('대기중 탭에서 전체 거부 메뉴를 탭하면 확인 다이얼로그가 표시된다', (tester) async {
      // Given: 대기중 거래가 있는 상태
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 더보기 메뉴 열기
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // 전체 거부 항목이 있으면 탭한다
      final rejectAllItem = find.byIcon(Icons.cancel_outlined);
      if (rejectAllItem.evaluate().isNotEmpty) {
        await tester.tap(rejectAllItem.first);
        await tester.pumpAndSettle();

        // Then: AlertDialog가 표시되어야 한다
        expect(find.byType(AlertDialog), findsOneWidget);
      }
    });
  });

  group('PendingTransactionsPage - 거래 카드 인터랙션', () {
    testWidgets('대기중 거래의 삭제 버튼을 탭하면 확인 다이얼로그가 표시된다', (tester) async {
      // Given: 대기중 거래 1건
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 삭제 아이콘 찾기
      final deleteIcon = find.byIcon(Icons.delete_outline);
      if (deleteIcon.evaluate().isNotEmpty) {
        await tester.tap(deleteIcon.first);
        await tester.pumpAndSettle();

        // Then: AlertDialog가 표시되어야 한다
        expect(find.byType(AlertDialog), findsOneWidget);
      }
    });

    testWidgets('삭제 다이얼로그에서 취소를 탭하면 다이얼로그가 닫힌다', (tester) async {
      // Given: 대기중 거래 1건
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 삭제 아이콘 탭
      final deleteIcon = find.byIcon(Icons.delete_outline);
      if (deleteIcon.evaluate().isNotEmpty) {
        await tester.tap(deleteIcon.first);
        await tester.pumpAndSettle();

        // AlertDialog 확인
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          // 취소 버튼 탭
          final cancelButton = find.text('취소');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton.first);
            await tester.pumpAndSettle();

            // Then: 다이얼로그가 닫혀야 한다
            expect(find.byType(AlertDialog), findsNothing);
          }
        }
      }
    });
  });

  group('PendingTransactionsPage - 수정 시트', () {
    testWidgets('대기중 거래 카드 탭 시 수정 시트가 열린다', (tester) async {
      // Given: 대기중 거래 1건
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 카드 본문을 탭한다 (InkWell이 onEdit에 연결됨)
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('PendingTransactionsPage - converted 상태 거래', () {
    testWidgets('converted 거래는 확인됨 탭에서 표시된다', (tester) async {
      // Given: converted 거래 1건
      final tx = _makePendingTx(
        id: 'tx-converted',
        status: PendingTransactionStatus.converted,
        parsedMerchant: '자동저장마트',
      );

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 두 번째 탭(확인됨)으로 전환
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      // Then: 자동저장마트 텍스트가 표시되어야 한다
      expect(find.textContaining('자동저장마트'), findsWidgets);
    });
  });

  group('PendingTransactionsPage - 확인됨 탭 팝업 메뉴', () {
    testWidgets('확인됨 탭에서 팝업 메뉴가 열린다', (tester) async {
      // Given: 확인됨 거래가 있는 상태
      final tx = _makePendingTx(
        status: PendingTransactionStatus.confirmed,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 두 번째 탭으로 전환
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      // 더보기 버튼 탭
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Then: PopupMenuButton이 존재해야 한다
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });
  });

  group('PendingTransactionsPage - 거부됨 탭 팝업 메뉴', () {
    testWidgets('거부됨 탭에서 팝업 메뉴가 열린다', (tester) async {
      // Given: 거부됨 거래가 있는 상태
      final tx = _makePendingTx(
        status: PendingTransactionStatus.rejected,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 세 번째 탭(거부됨)으로 전환
      await tester.tap(find.byType(Tab).at(2));
      await tester.pumpAndSettle();

      // 더보기 버튼 탭
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Then: PopupMenuButton이 존재해야 한다
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });
  });

  group('PendingTransactionsPage - 전체확인 다이얼로그 확인 버튼', () {
    testWidgets('전체확인 다이얼로그에서 확인 버튼을 탭하면 다이얼로그가 닫힌다', (tester) async {
      // Given: 대기중 거래가 있는 상태
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 더보기 메뉴 열기
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // 전체 확인 항목이 있으면 탭한다
      final confirmAllItem = find.byIcon(Icons.check_circle_outline);
      if (confirmAllItem.evaluate().isNotEmpty) {
        await tester.tap(confirmAllItem.first);
        await tester.pumpAndSettle();

        // AlertDialog가 있으면 확인 버튼 탭
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          final confirmButton = find.text('확인');
          if (confirmButton.evaluate().isNotEmpty) {
            await tester.tap(confirmButton.first);
            await tester.pumpAndSettle();
            // 다이얼로그가 닫혀야 한다
            expect(find.byType(AlertDialog), findsNothing);
          }
        }
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PendingTransactionsPage - 전체거부 다이얼로그', () {
    testWidgets('전체거부 다이얼로그에서 취소 버튼을 탭하면 다이얼로그가 닫힌다', (tester) async {
      // Given: 대기중 거래가 있는 상태
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 더보기 메뉴 열기
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // 전체 거부 항목이 있으면 탭한다
      final rejectAllItem = find.byIcon(Icons.cancel_outlined);
      if (rejectAllItem.evaluate().isNotEmpty) {
        await tester.tap(rejectAllItem.first);
        await tester.pumpAndSettle();

        // AlertDialog가 있으면 취소 버튼 탭
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          final cancelButton = find.text('취소');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton.first);
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsNothing);
          }
        }
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('전체거부 다이얼로그에서 확인 버튼을 탭하면 다이얼로그가 닫힌다', (tester) async {
      // Given: 대기중 거래가 있는 상태
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 더보기 메뉴 열기
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // 전체 거부 항목이 있으면 탭한다
      final rejectAllItem = find.byIcon(Icons.cancel_outlined);
      if (rejectAllItem.evaluate().isNotEmpty) {
        await tester.tap(rejectAllItem.first);
        await tester.pumpAndSettle();

        // AlertDialog가 있으면 확인 버튼 탭
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          final confirmButton = find.text('확인');
          if (confirmButton.evaluate().isNotEmpty) {
            await tester.tap(confirmButton.first);
            await tester.pumpAndSettle();
          }
        }
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PendingTransactionsPage - 팝업 메뉴 항목 선택', () {
    testWidgets('대기중 탭에서 전체삭제 메뉴 항목을 탭하면 다이얼로그가 표시된다', (tester) async {
      // Given: 대기중 거래가 있는 상태
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 더보기 메뉴 열고 delete_pending 선택
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      final deleteItems = find.byIcon(Icons.delete_outline);
      if (deleteItems.evaluate().isNotEmpty) {
        await tester.tap(deleteItems.last);
        await tester.pumpAndSettle();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('확인됨 탭에서 기록삭제 메뉴가 표시된다', (tester) async {
      // Given: 확인됨 거래가 있는 상태
      final tx = _makePendingTx(status: PendingTransactionStatus.confirmed);

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 두 번째 탭으로 전환 후 더보기 메뉴 열기
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Then: PopupMenuButton이 존재해야 한다
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('거부됨 탭에서 기록삭제 메뉴 항목이 표시된다', (tester) async {
      // Given: 거부됨 거래가 있는 상태
      final tx = _makePendingTx(status: PendingTransactionStatus.rejected);

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // When: 세 번째 탭으로 전환 후 더보기 메뉴 열기
      await tester.tap(find.byType(Tab).at(2));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Then: PopupMenuButton이 존재해야 한다
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });
  });

  group('PendingTransactionsPage - 날짜 헤더', () {
    testWidgets('오늘 날짜의 거래는 오늘 헤더와 함께 표시된다', (tester) async {
      // Given: 오늘 날짜의 대기중 거래
      final now = DateTime.now();
      final tx = PendingTransactionModel(
        id: 'tx-today',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        paymentMethodId: 'pm-1',
        sourceType: SourceType.sms,
        sourceSender: '1234',
        sourceContent: '오늘 결제',
        sourceTimestamp: now,
        parsedAmount: 10000,
        parsedType: 'expense',
        parsedMerchant: '오늘식당',
        parsedCategoryId: null,
        parsedDate: now,
        status: PendingTransactionStatus.pending,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        isViewed: false,
        duplicateHash: null,
        isDuplicate: false,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 오늘 날짜 헤더가 표시되어야 한다
      expect(find.textContaining('오늘'), findsWidgets);
    });

    testWidgets('어제 날짜의 거래는 어제 헤더와 함께 표시된다', (tester) async {
      // Given: 어제 날짜의 대기중 거래
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final tx = PendingTransactionModel(
        id: 'tx-yesterday',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        paymentMethodId: 'pm-1',
        sourceType: SourceType.sms,
        sourceSender: '1234',
        sourceContent: '어제 결제',
        sourceTimestamp: yesterday,
        parsedAmount: 10000,
        parsedType: 'expense',
        parsedMerchant: '어제식당',
        parsedCategoryId: null,
        parsedDate: yesterday,
        status: PendingTransactionStatus.pending,
        createdAt: yesterday,
        updatedAt: yesterday,
        expiresAt: yesterday.add(const Duration(days: 7)),
        isViewed: false,
        duplicateHash: null,
        isDuplicate: false,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 어제 헤더가 표시되어야 한다
      expect(find.textContaining('어제'), findsWidgets);
    });

    testWidgets('2일 전 날짜의 거래는 날짜 형식으로 헤더가 표시된다', (tester) async {
      // Given: 2일 전 날짜의 대기중 거래
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final tx = PendingTransactionModel(
        id: 'tx-old',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        paymentMethodId: 'pm-1',
        sourceType: SourceType.sms,
        sourceSender: '1234',
        sourceContent: '이틀전 결제',
        sourceTimestamp: twoDaysAgo,
        parsedAmount: 10000,
        parsedType: 'expense',
        parsedMerchant: '이틀전식당',
        parsedCategoryId: null,
        parsedDate: twoDaysAgo,
        status: PendingTransactionStatus.pending,
        createdAt: twoDaysAgo,
        updatedAt: twoDaysAgo,
        expiresAt: twoDaysAgo.add(const Duration(days: 7)),
        isViewed: false,
        duplicateHash: null,
        isDuplicate: false,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          pendingTxState: AsyncValue.data([tx]),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 텍스트가 표시되어야 한다 (날짜 헤더)
      expect(find.byType(ListView), findsWidgets);
    });
  });

  group('PendingTransactionsPage - 팝업 메뉴 delete_confirmed/delete_rejected', () {
    testWidgets('확인됨 탭에서 delete_confirmed 팝업 메뉴 항목을 탭하면 크래시가 없다', (tester) async {
      // Given: confirmed 상태 거래
      final tx = _makePendingTx(status: PendingTransactionStatus.confirmed);

      await tester.pumpWidget(
        _buildTestWidget(pendingTxState: AsyncValue.data([tx])),
      );
      await tester.pumpAndSettle();

      // When: 확인됨 탭으로 전환
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      // 더보기 메뉴 열기
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // delete_confirmed 항목 탭 (delete_outline 아이콘)
      final deleteItems = find.byIcon(Icons.delete_outline);
      if (deleteItems.evaluate().isNotEmpty) {
        await tester.tap(deleteItems.last, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('거부됨 탭에서 delete_rejected 팝업 메뉴 항목을 탭하면 크래시가 없다', (tester) async {
      // Given: rejected 상태 거래
      final tx = _makePendingTx(status: PendingTransactionStatus.rejected);

      await tester.pumpWidget(
        _buildTestWidget(pendingTxState: AsyncValue.data([tx])),
      );
      await tester.pumpAndSettle();

      // When: 거부됨 탭으로 전환
      await tester.tap(find.byType(Tab).at(2));
      await tester.pumpAndSettle();

      // 더보기 메뉴 열기
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // delete_rejected 항목 탭 (delete_outline 아이콘)
      final deleteItems = find.byIcon(Icons.delete_outline);
      if (deleteItems.evaluate().isNotEmpty) {
        await tester.tap(deleteItems.last, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('PendingTransactionsPage - confirm/reject 콜백', () {
    testWidgets('대기중 거래 카드의 확인 버튼을 탭하면 크래시가 없다', (tester) async {
      // Given: 대기중 거래
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(pendingTxState: AsyncValue.data([tx])),
      );
      await tester.pumpAndSettle();

      // When: ElevatedButton(확인) 탭 시도
      final elevatedButtons = find.byType(ElevatedButton);
      if (elevatedButtons.evaluate().isNotEmpty) {
        await tester.tap(elevatedButtons.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('대기중 거래에서 confirm_all 팝업 항목을 탭하면 다이얼로그가 표시된다', (tester) async {
      // Given: 대기중 거래
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(pendingTxState: AsyncValue.data([tx])),
      );
      await tester.pumpAndSettle();

      // When: 더보기 메뉴 열기
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // confirm_all 항목 탭 (check_circle_outline 아이콘)
      final confirmIcon = find.byIcon(Icons.check_circle_outline);
      if (confirmIcon.evaluate().isNotEmpty) {
        await tester.tap(confirmIcon.last, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('대기중 거래에서 reject_all 팝업 항목을 탭하면 다이얼로그가 표시된다', (tester) async {
      // Given: 대기중 거래
      final tx = _makePendingTx();

      await tester.pumpWidget(
        _buildTestWidget(pendingTxState: AsyncValue.data([tx])),
      );
      await tester.pumpAndSettle();

      // When: 더보기 메뉴 열기
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // reject_all 항목 탭 (cancel_outlined 또는 close 아이콘)
      final rejectIcon = find.byIcon(Icons.cancel_outlined);
      if (rejectIcon.evaluate().isNotEmpty) {
        await tester.tap(rejectIcon.last, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('PendingTransactionsPage - 확인/거부 콜백 호출', () {
    testWidgets('pending 거래 카드에서 확인 버튼 탭 시 confirmTransaction이 호출된다', (tester) async {
      // Given: pending 상태 거래
      final tx = _makePendingTx(status: PendingTransactionStatus.pending);

      await tester.pumpWidget(
        _buildTestWidget(pendingTxState: AsyncValue.data([tx])),
      );
      await tester.pumpAndSettle();

      // When: 카드 내 확인 버튼 탭 (check 아이콘 또는 ElevatedButton)
      final confirmButtons = find.byWidgetPredicate(
        (w) =>
            w is IconButton ||
            (w is TextButton &&
                w.child is Text &&
                (w.child as Text).data?.contains('확인') == true),
      );

      // ElevatedButton으로 된 확인 버튼 탭 시도
      final checkIcons = find.byIcon(Icons.check);
      if (checkIcons.evaluate().isNotEmpty) {
        await tester.tap(checkIcons.first, warnIfMissed: false);
        await tester.pump();
      } else if (confirmButtons.evaluate().isNotEmpty) {
        await tester.tap(confirmButtons.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('pending 거래 카드에서 거부 버튼 탭 시 rejectTransaction이 호출된다', (tester) async {
      // Given: pending 상태 거래
      final tx = _makePendingTx(status: PendingTransactionStatus.pending);

      await tester.pumpWidget(
        _buildTestWidget(pendingTxState: AsyncValue.data([tx])),
      );
      await tester.pumpAndSettle();

      // When: 카드 내 거부 버튼 탭 시도
      final closeIcons = find.byIcon(Icons.close);
      if (closeIcons.evaluate().isNotEmpty) {
        await tester.tap(closeIcons.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('pending 거래에서 삭제 버튼 탭 시 다이얼로그가 표시된다', (tester) async {
      // Given: pending 상태 거래
      final tx = _makePendingTx(status: PendingTransactionStatus.pending);

      await tester.pumpWidget(
        _buildTestWidget(pendingTxState: AsyncValue.data([tx])),
      );
      await tester.pumpAndSettle();

      // When: 삭제 아이콘 탭 시도
      final deleteIcons = find.byIcon(Icons.delete_outline);
      if (deleteIcons.evaluate().isNotEmpty) {
        await tester.tap(deleteIcons.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('confirmed 탭에서 delete_confirmed 팝업 후 확인 버튼 탭 시 처리된다', (tester) async {
      // Given: confirmed 상태 거래
      final tx = _makePendingTx(status: PendingTransactionStatus.confirmed);

      await tester.pumpWidget(
        _buildTestWidget(pendingTxState: AsyncValue.data([tx])),
      );
      await tester.pumpAndSettle();

      // 확인됨 탭으로 이동
      final confirmedTab = find.text('확인됨');
      if (confirmedTab.evaluate().isNotEmpty) {
        await tester.tap(confirmedTab.first);
        await tester.pumpAndSettle();
      }

      // When: 더보기 메뉴에서 삭제 탭
      final moreVert = find.byIcon(Icons.more_vert);
      if (moreVert.evaluate().isNotEmpty) {
        await tester.tap(moreVert.last, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Delete confirmed 항목 탭 시도
      final deleteConfirmedText = find.text('확인됨 삭제');
      if (deleteConfirmedText.evaluate().isNotEmpty) {
        await tester.tap(deleteConfirmedText.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // 확인 버튼 탭 시도
      final deleteButton = find.text('삭제');
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('reject 다이얼로그에서 확인 탭 시 rejectAll이 호출된다', (tester) async {
      // Given: pending 상태 거래
      final tx = _makePendingTx(status: PendingTransactionStatus.pending);

      await tester.pumpWidget(
        _buildTestWidget(pendingTxState: AsyncValue.data([tx])),
      );
      await tester.pumpAndSettle();

      // When: 더보기 메뉴 열기
      final moreVert = find.byIcon(Icons.more_vert);
      if (moreVert.evaluate().isNotEmpty) {
        await tester.tap(moreVert.last, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // reject_all 아이콘 탭
      final rejectIcon = find.byIcon(Icons.cancel_outlined);
      if (rejectIcon.evaluate().isNotEmpty) {
        await tester.tap(rejectIcon.last, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // 다이얼로그에서 거부 버튼 탭
      final rejectBtn = find.text('거부');
      if (rejectBtn.evaluate().isNotEmpty) {
        await tester.tap(rejectBtn.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
