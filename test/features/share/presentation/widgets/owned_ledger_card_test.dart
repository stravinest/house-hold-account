import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/share/domain/entities/ledger_invite.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/features/share/presentation/widgets/owned_ledger_card.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 테스트용 헬퍼 데이터 빌더
LedgerWithInviteInfo buildLedgerInfo({
  String id = 'ledger-1',
  String name = '우리 가계부',
  String ownerId = 'user-1',
  List<LedgerMember>? members,
  List<LedgerInvite>? sentInvites,
  bool canInvite = true,
  bool isCurrentLedger = false,
}) {
  final ledger = Ledger(
    id: id,
    name: name,
    currency: 'KRW',
    ownerId: ownerId,
    isShared: false,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  return LedgerWithInviteInfo(
    ledger: ledger,
    members: members ??
        [
          LedgerMember(
            id: 'member-1',
            ledgerId: id,
            userId: 'user-1',
            role: 'owner',
            joinedAt: DateTime(2026, 1, 1),
            email: 'owner@test.com',
            displayName: '홍길동',
          ),
        ],
    sentInvites: sentInvites ?? [],
    canInvite: canInvite,
    isCurrentLedger: isCurrentLedger,
  );
}

LedgerInvite buildInvite({
  String id = 'invite-1',
  String ledgerId = 'ledger-1',
  String status = 'pending',
  String inviteeEmail = 'invitee@test.com',
  bool expired = false,
}) {
  return LedgerInvite(
    id: id,
    ledgerId: ledgerId,
    inviterUserId: 'user-1',
    inviteeEmail: inviteeEmail,
    role: 'admin',
    status: status,
    createdAt: DateTime(2026, 1, 1),
    expiresAt: expired
        ? DateTime.now().subtract(const Duration(days: 1))
        : DateTime.now().add(const Duration(days: 7)),
    ledgerName: '우리 가계부',
    inviterEmail: 'owner@test.com',
  );
}

Widget buildTestWidget(OwnedLedgerCard card) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: SingleChildScrollView(child: card),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    // OwnedLedgerCard가 SupabaseConfig.auth.currentUser?.id를 직접 호출하므로
    // 위젯 테스트에서 Supabase를 초기화해야 합니다.
    // SharedPreferences mock 설정 (Supabase auth storage가 SharedPreferences를 사용)
    SharedPreferences.setMockInitialValues({});
    // Supabase.initialize는 이미 초기화된 경우 재초기화하지 않고 기존 인스턴스를 반환합니다.
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  group('OwnedLedgerCard 위젯 테스트', () {
    // ================================================================
    // 기본 렌더링
    // ================================================================
    group('기본 렌더링', () {
      testWidgets('가계부 이름이 표시된다', (tester) async {
        // Given
        final ledgerInfo = buildLedgerInfo(name: '우리 가족 가계부');

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: ledgerInfo),
        ));
        await tester.pump();

        // Then
        expect(find.text('우리 가족 가계부'), findsOneWidget);
      });

      testWidgets('Card 위젯이 렌더링된다', (tester) async {
        // Given
        final ledgerInfo = buildLedgerInfo();

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: ledgerInfo),
        ));
        await tester.pump();

        // Then
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('수정 버튼(edit 아이콘)이 표시된다', (tester) async {
        // Given
        final ledgerInfo = buildLedgerInfo();

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: ledgerInfo),
        ));
        await tester.pump();

        // Then
        expect(find.byIcon(Icons.edit), findsOneWidget);
      });

      testWidgets('menu_book 아이콘이 표시된다', (tester) async {
        // Given
        final ledgerInfo = buildLedgerInfo();

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: ledgerInfo),
        ));
        await tester.pump();

        // Then
        expect(find.byIcon(Icons.menu_book), findsOneWidget);
      });

      testWidgets('people 아이콘이 멤버 정보 영역에 표시된다', (tester) async {
        // Given
        final ledgerInfo = buildLedgerInfo();

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: ledgerInfo),
        ));
        await tester.pump();

        // Then
        expect(find.byIcon(Icons.people), findsOneWidget);
      });
    });

    // ================================================================
    // 현재 사용중 상태
    // ================================================================
    group('현재 사용중 상태', () {
      testWidgets('isCurrentLedger가 true이면 Card elevation이 2이다', (tester) async {
        // Given
        final ledgerInfo = buildLedgerInfo(isCurrentLedger: true);

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: ledgerInfo),
        ));
        await tester.pump();

        // Then
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, 2);
      });

      testWidgets('isCurrentLedger가 false이면 Card elevation이 0이다', (tester) async {
        // Given
        final ledgerInfo = buildLedgerInfo(isCurrentLedger: false);

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: ledgerInfo),
        ));
        await tester.pump();

        // Then
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, 0);
      });

      testWidgets('isCurrentLedger가 true이면 사용중 배지가 표시된다', (tester) async {
        // Given
        final ledgerInfo = buildLedgerInfo(isCurrentLedger: true, canInvite: true);

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: ledgerInfo),
        ));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('사용 중'), findsOneWidget);
      });

      testWidgets('isCurrentLedger가 false이면 사용중 배지가 표시되지 않는다', (tester) async {
        // Given
        final ledgerInfo = buildLedgerInfo(isCurrentLedger: false);

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: ledgerInfo),
        ));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('사용 중'), findsNothing);
      });

      testWidgets('isCurrentLedger가 false이면 사용 버튼이 OutlinedButton으로 표시된다', (tester) async {
        // Given - 멤버 꽉 찬 상태(초대 버튼 없음)에서 사용 버튼만 남기도록
        final ledgerInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
            LedgerMember(
              id: 'member-2',
              ledgerId: 'ledger-1',
              userId: 'user-2',
              role: 'admin',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [],
          canInvite: false,
          isCurrentLedger: false,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onSelectLedger: () {},
          ),
        ));
        await tester.pumpAndSettle();

        // Then - 사용 버튼이 표시되어야 함
        expect(find.text('사용'), findsOneWidget);
      });

      testWidgets('isCurrentLedger가 true이면 사용 버튼이 표시되지 않는다', (tester) async {
        // Given - 멤버 꽉 찬 상태
        final ledgerInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
            LedgerMember(
              id: 'member-2',
              ledgerId: 'ledger-1',
              userId: 'user-2',
              role: 'admin',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [],
          canInvite: false,
          isCurrentLedger: true,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onSelectLedger: () {},
          ),
        ));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('사용'), findsNothing);
      });
    });

    // ================================================================
    // 수정 버튼 콜백
    // ================================================================
    group('수정 버튼', () {
      testWidgets('수정 버튼 탭 시 onEdit 콜백이 호출된다', (tester) async {
        // Given
        final ledgerInfo = buildLedgerInfo();
        var editTapped = false;

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onEdit: () => editTapped = true,
          ),
        ));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.edit));
        await tester.pump();

        // Then
        expect(editTapped, isTrue);
      });
    });

    // ================================================================
    // 초대 버튼
    // ================================================================
    group('초대 버튼', () {
      testWidgets('초대가 없는 상태에서 초대 버튼이 표시된다', (tester) async {
        // Given - 현재 사용중이고 초대 없는 경우
        final ledgerInfo = buildLedgerInfo(canInvite: true, isCurrentLedger: true);

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onInviteTap: () {},
          ),
        ));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('초대'), findsOneWidget);
      });

      testWidgets('초대 버튼 탭 시 onInviteTap 콜백이 호출된다', (tester) async {
        // Given
        final ledgerInfo = buildLedgerInfo(canInvite: true, isCurrentLedger: true);
        var inviteTapped = false;

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onInviteTap: () => inviteTapped = true,
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('초대'));
        await tester.pump();

        // Then
        expect(inviteTapped, isTrue);
      });
    });

    // ================================================================
    // 멤버 가득 찬 상태
    // ================================================================
    group('멤버 가득 찬 상태', () {
      testWidgets('멤버가 꽉 찬 경우 check_circle 아이콘이 표시된다', (tester) async {
        // Given - maxMembersPerLedger = 2
        final fullMembersInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
            LedgerMember(
              id: 'member-2',
              ledgerId: 'ledger-1',
              userId: 'user-2',
              role: 'admin',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [],
          canInvite: false,
          isCurrentLedger: true,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: fullMembersInfo),
        ));
        await tester.pumpAndSettle();

        // Then
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('멤버가 꽉 찬 경우 초대 버튼이 표시되지 않는다', (tester) async {
        // Given
        final fullMembersInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
            LedgerMember(
              id: 'member-2',
              ledgerId: 'ledger-1',
              userId: 'user-2',
              role: 'admin',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [],
          canInvite: false,
          isCurrentLedger: true,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: fullMembersInfo,
            onInviteTap: () {},
          ),
        ));
        await tester.pumpAndSettle();

        // Then - 초대 버튼 없음
        expect(find.text('초대'), findsNothing);
      });
    });

    // ================================================================
    // 초대 상태 배지
    // ================================================================
    group('초대 상태 배지', () {
      testWidgets('pending 초대가 있으면 hourglass 아이콘과 close 버튼이 표시된다', (tester) async {
        // Given
        final pendingInvite = buildInvite(status: 'pending');
        final ledgerInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [pendingInvite],
          canInvite: false,
          isCurrentLedger: true,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onCancelInvite: (_) {},
          ),
        ));
        await tester.pumpAndSettle();

        // Then
        expect(find.byIcon(Icons.hourglass_empty_outlined), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('accepted 초대가 있으면 check_circle_outlined 아이콘이 표시된다', (tester) async {
        // Given
        final acceptedInvite = buildInvite(status: 'accepted');
        final ledgerInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [acceptedInvite],
          canInvite: true,
          isCurrentLedger: true,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: ledgerInfo),
        ));
        await tester.pumpAndSettle();

        // Then
        expect(find.byIcon(Icons.check_circle_outlined), findsOneWidget);
      });

      testWidgets('rejected 초대가 있으면 block_outlined 아이콘과 close 버튼이 표시된다', (tester) async {
        // Given
        final rejectedInvite = buildInvite(status: 'rejected');
        final ledgerInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [rejectedInvite],
          canInvite: true,
          isCurrentLedger: true,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onDeleteInvite: (_) {},
          ),
        ));
        await tester.pumpAndSettle();

        // Then
        expect(find.byIcon(Icons.block_outlined), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('pending 취소 버튼 탭 시 onCancelInvite 콜백이 호출된다', (tester) async {
        // Given
        final pendingInvite = buildInvite(id: 'invite-cancel-test', status: 'pending');
        String? cancelledInviteId;

        final ledgerInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [pendingInvite],
          canInvite: false,
          isCurrentLedger: true,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onCancelInvite: (id) => cancelledInviteId = id,
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        // Then
        expect(cancelledInviteId, 'invite-cancel-test');
      });

      testWidgets('rejected 삭제 버튼 탭 시 onDeleteInvite 콜백이 호출된다', (tester) async {
        // Given
        final rejectedInvite = buildInvite(id: 'invite-delete-test', status: 'rejected');
        String? deletedInviteId;

        final ledgerInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [rejectedInvite],
          canInvite: true,
          isCurrentLedger: true,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onDeleteInvite: (id) => deletedInviteId = id,
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        // Then
        expect(deletedInviteId, 'invite-delete-test');
      });

      testWidgets('inviteeEmail이 배지 텍스트에 포함된다', (tester) async {
        // Given
        final pendingInvite = buildInvite(
          status: 'pending',
          inviteeEmail: 'test@example.com',
        );
        final ledgerInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [pendingInvite],
          canInvite: false,
          isCurrentLedger: true,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(ledgerInfo: ledgerInfo),
        ));
        await tester.pumpAndSettle();

        // Then - 이메일이 배지 텍스트에 포함되어 있어야 함
        expect(
          find.textContaining('test@example.com'),
          findsOneWidget,
        );
      });
    });

    // ================================================================
    // 사용 버튼 콜백
    // ================================================================
    group('사용 버튼 콜백', () {
      testWidgets('사용 버튼 탭 시 onSelectLedger 콜백이 호출된다', (tester) async {
        // Given - 멤버 2명(꽉 참), 사용 중 아님 → 사용 버튼만 표시
        final ledgerInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
            LedgerMember(
              id: 'member-2',
              ledgerId: 'ledger-1',
              userId: 'user-2',
              role: 'admin',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [],
          canInvite: false,
          isCurrentLedger: false,
        );

        var selectLedgerCalled = false;

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onSelectLedger: () => selectLedgerCalled = true,
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('사용'));
        await tester.pump();

        // Then
        expect(selectLedgerCalled, isTrue);
      });
    });

    // ================================================================
    // 복수 초대 상태
    // ================================================================
    group('복수 초대 상태', () {
      testWidgets('pending과 rejected 초대가 동시에 있을 때 각각 아이콘이 표시된다', (tester) async {
        // Given
        final pendingInvite = buildInvite(
          id: 'invite-pending',
          status: 'pending',
          inviteeEmail: 'pending@test.com',
        );
        final rejectedInvite = buildInvite(
          id: 'invite-rejected',
          status: 'rejected',
          inviteeEmail: 'rejected@test.com',
        );

        final ledgerInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [pendingInvite, rejectedInvite],
          canInvite: false,
          isCurrentLedger: true,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onCancelInvite: (_) {},
            onDeleteInvite: (_) {},
          ),
        ));
        await tester.pumpAndSettle();

        // Then
        expect(find.byIcon(Icons.hourglass_empty_outlined), findsOneWidget);
        expect(find.byIcon(Icons.block_outlined), findsOneWidget);
        // close 버튼이 2개 (pending 취소 + rejected 삭제)
        expect(find.byIcon(Icons.close), findsNWidgets(2));
      });

      testWidgets('accepted와 pending 초대가 동시에 있을 때 각각 표시된다', (tester) async {
        // Given
        final pendingInvite = buildInvite(
          id: 'invite-pending',
          status: 'pending',
          inviteeEmail: 'pending@test.com',
        );
        final acceptedInvite = buildInvite(
          id: 'invite-accepted',
          status: 'accepted',
          inviteeEmail: 'accepted@test.com',
        );

        final ledgerInfo = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '우리 가계부',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [
            LedgerMember(
              id: 'member-1',
              ledgerId: 'ledger-1',
              userId: 'user-1',
              role: 'owner',
              joinedAt: DateTime.now(),
            ),
          ],
          sentInvites: [pendingInvite, acceptedInvite],
          canInvite: false,
          isCurrentLedger: true,
        );

        // When
        await tester.pumpWidget(buildTestWidget(
          OwnedLedgerCard(
            ledgerInfo: ledgerInfo,
            onCancelInvite: (_) {},
          ),
        ));
        await tester.pumpAndSettle();

        // Then
        expect(find.byIcon(Icons.hourglass_empty_outlined), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outlined), findsOneWidget);
      });
    });
  });
}
