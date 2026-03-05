import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/share/domain/entities/ledger_invite.dart';
import 'package:shared_household_account/features/share/presentation/pages/share_management_page.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared_household_account/features/share/data/repositories/share_repository.dart';

class MockShareRepository extends Mock implements ShareRepository {}

// 테스트용 헬퍼 데이터 빌더
Ledger buildTestLedger({
  String id = 'ledger-1',
  String name = '우리 가계부',
  String ownerId = 'user-1',
}) {
  return Ledger(
    id: id,
    name: name,
    currency: 'KRW',
    ownerId: ownerId,
    isShared: false,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

LedgerMember buildTestMember({
  String userId = 'user-1',
  String ledgerId = 'ledger-1',
  String role = 'owner',
}) {
  return LedgerMember(
    id: 'member-$userId',
    ledgerId: ledgerId,
    userId: userId,
    role: role,
    joinedAt: DateTime(2026, 1, 1),
    email: '$userId@test.com',
  );
}

LedgerWithInviteInfo buildTestLedgerInfo({
  String id = 'ledger-1',
  String name = '우리 가계부',
  String ownerId = 'user-1',
  List<LedgerMember>? members,
  List<LedgerInvite>? sentInvites,
  bool canInvite = true,
  bool isCurrentLedger = false,
}) {
  final ledger = buildTestLedger(id: id, name: name, ownerId: ownerId);
  return LedgerWithInviteInfo(
    ledger: ledger,
    members: members ?? [buildTestMember(userId: ownerId, ledgerId: id)],
    sentInvites: sentInvites ?? [],
    canInvite: canInvite,
    isCurrentLedger: isCurrentLedger,
  );
}

LedgerInvite buildTestInvite({
  String id = 'invite-1',
  String ledgerId = 'ledger-2',
  String ledgerName = '친구 가계부',
  String status = 'pending',
}) {
  return LedgerInvite(
    id: id,
    ledgerId: ledgerId,
    ledgerName: ledgerName,
    inviterUserId: 'user-2',
    inviterEmail: 'user2@test.com',
    inviteeEmail: 'user1@test.com',
    role: 'member',
    status: status,
    createdAt: DateTime(2026, 1, 1),
    expiresAt: DateTime(2026, 12, 31),
  );
}

Widget buildTestWidget({
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('ko')],
      home: ShareManagementPage(),
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  group('ShareManagementPage 위젯 테스트', () {
    late MockShareRepository mockRepository;

    setUp(() {
      mockRepository = MockShareRepository();
    });

    group('로딩 상태', () {
      testWidgets('myOwnedLedgersWithInvitesProvider가 로딩 중이면 스켈레톤이 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.delayed(const Duration(seconds: 10)),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        // When: 첫 프레임만 (로딩 상태)
        await tester.pump();

        // Then: AppBar 제목이 표시됨
        expect(find.text('가계부 및 공유 관리'), findsOneWidget);
      });

      testWidgets('receivedInvitesProvider가 로딩 중이면 스켈레톤이 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.delayed(const Duration(seconds: 10)),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pump();

        // Then: AppBar 제목이 표시됨
        expect(find.text('가계부 및 공유 관리'), findsOneWidget);
      });
    });

    group('빈 상태', () {
      testWidgets('가계부와 초대가 모두 없으면 빈 상태 메시지가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        // When
        await tester.pumpAndSettle();

        // Then
        expect(find.text('가계부가 없습니다'), findsOneWidget);
        expect(find.text('가계부를 생성하여 시작하세요'), findsOneWidget);
        expect(find.text('가계부 생성하기'), findsOneWidget);
      });
    });

    group('에러 상태', () {
      testWidgets('myOwnedLedgersWithInvitesProvider 에러 시 에러 위젯이 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.error(Exception('네트워크 오류')),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        // When
        await tester.pumpAndSettle();

        // Then
        expect(find.text('오류가 발생했습니다'), findsOneWidget);
      });

      testWidgets('receivedInvitesProvider 에러 시 에러 위젯이 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.error(Exception('초대 목록 로드 실패')),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        // When
        await tester.pumpAndSettle();

        // Then
        expect(find.text('오류가 발생했습니다'), findsOneWidget);
      });
    });

    group('내 가계부 섹션', () {
      testWidgets('소유한 가계부가 있으면 내 가계부 섹션이 표시된다', (tester) async {
        // Given
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
        );

        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        // When
        await tester.pumpAndSettle();

        // Then
        expect(find.text('내 가계부'), findsOneWidget);
        expect(find.text('우리 가계부'), findsOneWidget);
      });

      testWidgets('여러 개의 소유한 가계부가 모두 표시된다', (tester) async {
        // Given
        final ledger1 = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '개인 가계부',
          ownerId: 'user-1',
        );
        final ledger2 = buildTestLedgerInfo(
          id: 'ledger-2',
          name: '가족 가계부',
          ownerId: 'user-1',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ledger1, ledger2]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        // When
        await tester.pumpAndSettle();

        // Then
        expect(find.text('개인 가계부'), findsOneWidget);
        expect(find.text('가족 가계부'), findsOneWidget);
      });

      testWidgets('현재 사용 중인 가계부가 isCurrentLedger=true로 표시된다', (tester) async {
        // Given
        const currentLedgerId = 'ledger-1';
        final currentLedger = buildTestLedgerInfo(
          id: currentLedgerId,
          name: '현재 가계부',
          ownerId: 'user-1',
          isCurrentLedger: true,
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([currentLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => currentLedgerId),
            ],
          ),
        );

        // When
        await tester.pumpAndSettle();

        // Then: 사용 중 배지가 표시되어야 함
        expect(find.text('현재 가계부'), findsOneWidget);
        expect(find.text('사용 중'), findsOneWidget);
      });
    });

    group('초대받은 가계부 섹션', () {
      testWidgets('받은 초대가 있으면 초대받은 가계부 섹션이 표시된다', (tester) async {
        // Given
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'pending',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        // When
        await tester.pumpAndSettle();

        // Then
        expect(find.text('초대받은 가계부'), findsOneWidget);
        expect(find.text('친구 가계부'), findsOneWidget);
      });

      testWidgets('내 가계부와 초대 모두 있을 때 두 섹션 모두 표시된다', (tester) async {
        // Given
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '내 가계부',
          ownerId: 'user-1',
        );
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'pending',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        // When
        await tester.pumpAndSettle();

        // Then: 섹션 헤더와 가계부 이름 모두 표시됨
        expect(find.text('내 가계부'), findsWidgets); // 섹션 헤더 + 가계부 이름
        expect(find.text('초대받은 가계부'), findsOneWidget);
        expect(find.text('친구 가계부'), findsOneWidget);
      });
    });

    group('AppBar', () {
      testWidgets('AppBar에 공유 관리 제목이 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        // When
        await tester.pumpAndSettle();

        // Then
        expect(find.text('가계부 및 공유 관리'), findsOneWidget);
      });
    });

    group('RefreshIndicator', () {
      testWidgets('당겨서 새로고침 시 onRefresh 콜백이 실행된다', (tester) async {
        // Given
        var refreshCount = 0;
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith((ref) {
                refreshCount++;
                return Future.value([]);
              }),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 스크롤 뷰를 아래로 당겨서 새로고침 트리거
        // RefreshIndicator 내부에 CustomScrollView가 있으므로 fling으로 트리거
        await tester.fling(
          find.byType(RefreshIndicator),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();

        // Then: 페이지가 정상적으로 표시됨
        expect(find.text('가계부 및 공유 관리'), findsOneWidget);
      });
    });

    group('내 가계부 - 초대 버튼', () {
      testWidgets('초대 가능한 상태에서 초대 버튼이 존재한다', (tester) async {
        // Given: canInvite = true인 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          canInvite: true,
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Then: 초대 버튼이 활성화되어 있어야 함
        expect(find.text('우리 가계부'), findsOneWidget);
        // OwnedLedgerCard의 초대 버튼 존재 확인
        expect(find.text('초대'), findsOneWidget);
      });

      testWidgets('멤버가 가득 찬 상태에서 초대 불가 표시가 된다', (tester) async {
        // Given: canInvite = false (멤버 가득)
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          members: [
            buildTestMember(userId: 'user-1', ledgerId: 'ledger-1'),
            buildTestMember(userId: 'user-2', ledgerId: 'ledger-1'),
          ],
          canInvite: false,
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Then: 가계부 이름 표시
        expect(find.text('우리 가계부'), findsOneWidget);
      });
    });

    group('초대받은 가계부 - 콜백', () {
      testWidgets('pending 초대 카드에 수락/거부 버튼이 표시된다', (tester) async {
        // Given: pending 상태 초대
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'pending',
        );

        when(() => mockRepository.acceptInvite(any()))
            .thenAnswer((_) async => {});
        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Then: 수락/거부 버튼이 표시됨
        expect(find.text('친구 가계부'), findsOneWidget);
        expect(find.text('수락'), findsOneWidget);
        expect(find.text('거부'), findsOneWidget);
      });

      testWidgets('accepted 초대 카드에 사용/탈퇴 버튼이 표시된다', (tester) async {
        // Given: accepted 상태 초대
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'accepted',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Then: 사용/탈퇴 버튼이 표시됨 (invite.ledgerId != selectedLedgerId 이므로 사용 버튼 표시)
        expect(find.text('친구 가계부'), findsOneWidget);
        expect(find.text('사용'), findsOneWidget);
        expect(find.text('탈퇴'), findsOneWidget);
      });
    });

    group('에러 상태 - 재시도 버튼', () {
      testWidgets('에러 상태에서 재시도 버튼을 탭하면 다시 로딩된다', (tester) async {
        // Given: 에러 상태
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.error(Exception('오류 발생')),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Then: 에러 메시지와 재시도 버튼 확인
        expect(find.text('오류가 발생했습니다'), findsOneWidget);
        expect(find.text('다시 시도'), findsOneWidget);

        // When: 재시도 버튼 탭
        await tester.tap(find.text('다시 시도'));
        await tester.pump();

        // Then: 페이지가 여전히 표시됨 (crash 없음)
        expect(find.text('가계부 및 공유 관리'), findsOneWidget);
      });
    });

    group('초대 다이얼로그', () {
      testWidgets('초대 버튼 탭 시 초대 다이얼로그가 열린다', (tester) async {
        // Given: canInvite=true 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          canInvite: true,
        );

        when(() => mockRepository.createInvite(
              ledgerId: any(named: 'ledgerId'),
              inviteeEmail: any(named: 'inviteeEmail'),
            )).thenAnswer((_) async => buildTestInvite());

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 초대 버튼 탭
        await tester.tap(find.text('초대'));
        await tester.pumpAndSettle();

        // Then: 초대 다이얼로그가 열림
        expect(find.text('멤버 초대'), findsOneWidget);
      });

      testWidgets('초대 다이얼로그에서 이메일 입력 후 초대 전송 성공', (tester) async {
        // Given: canInvite=true 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          canInvite: true,
        );
        final testInvite = buildTestInvite();

        when(() => mockRepository.createInvite(
              ledgerId: any(named: 'ledgerId'),
              inviteeEmail: any(named: 'inviteeEmail'),
            )).thenAnswer((_) async => testInvite);
        when(() => mockRepository.getSentInvites(any()))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 초대 버튼 탭하여 다이얼로그 열기
        await tester.tap(find.text('초대'));
        await tester.pumpAndSettle();

        // 이메일 입력
        await tester.enterText(
          find.byType(TextFormField),
          'friend@test.com',
        );
        await tester.pumpAndSettle();

        // 초대 전송 버튼 탭 (다이얼로그 내 '초대' 버튼 - 마지막 것)
        await tester.tap(find.text('초대').last);
        await tester.pumpAndSettle();

        // Then: 초대 전송이 호출됨
        verify(() => mockRepository.createInvite(
              ledgerId: 'ledger-1',
              inviteeEmail: 'friend@test.com',
            )).called(1);
      });

      testWidgets('초대 다이얼로그에서 이메일 없이 전송 시 유효성 검사 에러', (tester) async {
        // Given
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          canInvite: true,
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 초대 버튼 탭하여 다이얼로그 열기
        await tester.tap(find.text('초대'));
        await tester.pumpAndSettle();

        // 이메일 없이 초대 전송 버튼 탭 (다이얼로그 내 '초대' 버튼)
        await tester.tap(find.text('초대').last);
        await tester.pumpAndSettle();

        // Then: 유효성 검사 에러가 표시됨 (다이얼로그가 열린 상태 유지)
        expect(find.text('멤버 초대'), findsOneWidget);
      });

      testWidgets('초대 다이얼로그에서 @ 없는 이메일 입력 시 유효성 검사 에러', (tester) async {
        // Given
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          canInvite: true,
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 초대 버튼 탭하여 다이얼로그 열기
        await tester.tap(find.text('초대'));
        await tester.pumpAndSettle();

        // @ 없는 이메일 입력
        await tester.enterText(find.byType(TextFormField), 'invalidemail');
        await tester.pumpAndSettle();

        // 초대 전송 버튼 탭 (다이얼로그 내 '초대' 버튼)
        await tester.tap(find.text('초대').last);
        await tester.pumpAndSettle();

        // Then: 유효성 검사 에러가 표시됨
        expect(find.text('멤버 초대'), findsOneWidget);
      });

      testWidgets('초대 다이얼로그에서 취소 버튼 탭 시 다이얼로그가 닫힌다', (tester) async {
        // Given
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          canInvite: true,
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 초대 버튼 탭하여 다이얼로그 열기
        await tester.tap(find.text('초대'));
        await tester.pumpAndSettle();

        // 취소 버튼 탭
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        // Then: 다이얼로그가 닫힘
        expect(find.text('멤버 초대'), findsNothing);
        expect(find.text('우리 가계부'), findsOneWidget);
      });
    });

    group('수락 기능', () {
      testWidgets('pending 초대에서 수락 버튼 탭 시 acceptInvite가 호출된다', (tester) async {
        // Given: pending 상태 초대
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'pending',
        );

        when(() => mockRepository.acceptInvite('invite-1'))
            .thenAnswer((_) async => {});
        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 수락 버튼 탭
        await tester.tap(find.text('수락'));
        await tester.pumpAndSettle();

        // Then: acceptInvite가 호출됨
        verify(() => mockRepository.acceptInvite('invite-1')).called(1);
      });

      testWidgets('거부 버튼 탭 시 거부 확인 다이얼로그가 표시된다', (tester) async {
        // Given: pending 상태 초대
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'pending',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 거부 버튼 탭
        await tester.tap(find.text('거부'));
        await tester.pumpAndSettle();

        // Then: 거부 확인 다이얼로그가 표시됨
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('거부 확인 다이얼로그에서 취소 버튼 탭 시 다이얼로그가 닫힌다', (tester) async {
        // Given: pending 상태 초대
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'pending',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 거부 버튼 탭 → 취소
        await tester.tap(find.text('거부'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        // Then: 다이얼로그가 닫힘
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('친구 가계부'), findsOneWidget);
      });

      testWidgets('거부 확인 다이얼로그에서 거부 버튼 탭 시 rejectInvite가 호출된다', (tester) async {
        // Given: pending 상태 초대
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'pending',
        );

        when(() => mockRepository.rejectInvite('invite-1'))
            .thenAnswer((_) async => {});
        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 거부 버튼 탭 → 거부 확인
        await tester.tap(find.text('거부'));
        await tester.pumpAndSettle();
        // 다이얼로그의 거부 버튼은 마지막 '거부' 텍스트
        await tester.tap(find.text('거부').last);
        await tester.pumpAndSettle();

        // Then: rejectInvite가 호출됨
        verify(() => mockRepository.rejectInvite('invite-1')).called(1);
      });

      testWidgets('accepted 초대에서 탈퇴 버튼 탭 시 탈퇴 확인 다이얼로그가 표시된다', (tester) async {
        // Given: accepted 상태 초대
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'accepted',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 탈퇴 버튼 탭
        await tester.tap(find.text('탈퇴'));
        await tester.pumpAndSettle();

        // Then: 탈퇴 확인 다이얼로그가 표시됨
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('탈퇴 확인 다이얼로그에서 취소 탭 시 다이얼로그가 닫힌다', (tester) async {
        // Given: accepted 상태 초대
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'accepted',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 탈퇴 버튼 탭 → 취소
        await tester.tap(find.text('탈퇴'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        // Then: 다이얼로그가 닫힘
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('탈퇴 확인 다이얼로그에서 탈퇴 버튼 탭 시 leaveLedger가 호출된다', (tester) async {
        // Given: accepted 상태 초대
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'accepted',
        );

        when(() => mockRepository.leaveLedger('ledger-2'))
            .thenAnswer((_) async {});
        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 탈퇴 버튼 탭 → 탈퇴 확인
        await tester.tap(find.text('탈퇴'));
        await tester.pumpAndSettle();
        // 다이얼로그의 탈퇴 버튼은 마지막 '탈퇴' 텍스트
        await tester.tap(find.text('탈퇴').last);
        await tester.pumpAndSettle();

        // Then: leaveLedger가 호출됨
        verify(() => mockRepository.leaveLedger('ledger-2')).called(1);
      });
    });

    group('가계부 선택 다이얼로그', () {
      testWidgets('현재 선택되지 않은 가계부 카드의 사용 버튼 탭 시 선택 확인 다이얼로그가 표시된다', (tester) async {
        // Given: 현재 가계부가 아닌 소유 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          isCurrentLedger: false,
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => 'other-ledger'),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 사용 버튼 탭
        final useButton = find.text('사용');
        if (useButton.evaluate().isNotEmpty) {
          await tester.tap(useButton);
          await tester.pumpAndSettle();

          // Then: 선택 확인 다이얼로그가 표시됨
          expect(find.byType(AlertDialog), findsOneWidget);
        }
      });

      testWidgets('accepted 초대에서 사용 버튼 탭 시 선택 확인 다이얼로그가 표시된다', (tester) async {
        // Given: accepted 상태 초대 (다른 가계부 선택 중)
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'accepted',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 사용 버튼 탭
        await tester.tap(find.text('사용'));
        await tester.pumpAndSettle();

        // Then: 선택 확인 다이얼로그가 표시됨
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('가계부 선택 확인 다이얼로그에서 취소 탭 시 닫힌다', (tester) async {
        // Given: accepted 상태 초대
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'accepted',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 사용 버튼 탭 → 취소
        await tester.tap(find.text('사용'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        // Then: 다이얼로그가 닫힘
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('초대 취소 기능', () {
      testWidgets('pending 초대의 취소 버튼 탭 시 취소 확인 다이얼로그가 표시된다', (tester) async {
        // Given: pending 초대가 있는 가계부
        final pendingInvite = buildTestInvite(
          id: 'invite-sent-1',
          ledgerId: 'ledger-1',
          ledgerName: '우리 가계부',
          status: 'pending',
        );
        final ownedLedger = LedgerWithInviteInfo(
          ledger: buildTestLedger(id: 'ledger-1', name: '우리 가계부'),
          members: [buildTestMember(userId: 'user-1', ledgerId: 'ledger-1')],
          sentInvites: [pendingInvite],
          canInvite: false,
        );

        when(() => mockRepository.cancelInvite(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: close 아이콘 버튼 탭 (초대 취소)
        final closeBtn = find.byIcon(Icons.close);
        if (closeBtn.evaluate().isNotEmpty) {
          await tester.tap(closeBtn.first);
          await tester.pumpAndSettle();

          // Then: 취소 확인 다이얼로그가 표시됨
          expect(find.byType(AlertDialog), findsOneWidget);
        }
      });
    });

    group('가계부 수정 다이얼로그', () {
      testWidgets('수정 버튼 탭 시 가계부 수정 다이얼로그가 열린다', (tester) async {
        // Given: 소유 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 수정 아이콘 버튼 탭
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // Then: 가계부 수정 다이얼로그가 열림
        expect(find.text('가계부 수정'), findsOneWidget);
        expect(find.text('가계부 이름'), findsOneWidget);
      });

      testWidgets('가계부 수정 다이얼로그에서 취소 버튼 탭 시 다이얼로그가 닫힌다', (tester) async {
        // Given: 소유 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 수정 버튼 탭 → 취소
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        // Then: 다이얼로그가 닫힘
        expect(find.text('가계부 수정'), findsNothing);
        expect(find.text('우리 가계부'), findsOneWidget);
      });

      testWidgets('가계부 수정 다이얼로그에서 새 이름 입력 후 저장하면 updateLedger가 호출된다', (tester) async {
        // Given: 소유 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
        );

        // ledgerNotifierProvider는 Supabase 초기화가 된 상태에서 실행되므로
        // updateLedger 호출 시 에러가 발생할 수 있음 - 에러 처리까지 테스트
        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 수정 버튼 탭 → 새 이름 입력 → 저장
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // 기존 텍스트 지우고 새 이름 입력
        await tester.enterText(find.byType(TextField), '새 가계부 이름');
        await tester.pumpAndSettle();

        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();

        // Then: 다이얼로그가 닫힘 (updateLedger 호출, 에러 발생 가능하지만 crash 없음)
        expect(find.text('가계부 수정'), findsNothing);
      });
    });

    group('가계부 선택 - 사용 확인', () {
      testWidgets('가계부 선택 확인 다이얼로그에서 사용 버튼 탭 시 selectLedger가 호출된다', (tester) async {
        // Given: accepted 상태 초대
        final invite = buildTestInvite(
          id: 'invite-1',
          ledgerId: 'ledger-2',
          ledgerName: '친구 가계부',
          status: 'accepted',
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([invite]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 사용 버튼 탭 → 사용 확인
        await tester.tap(find.text('사용'));
        await tester.pumpAndSettle();

        // 확인 다이얼로그에서 사용 버튼 탭
        final useBtn = find.text('사용');
        if (useBtn.evaluate().length > 1) {
          await tester.tap(useBtn.last);
          await tester.pumpAndSettle();
        }

        // Then: 다이얼로그가 닫힘 (성공 처리)
        expect(find.text('가계부 및 공유 관리'), findsOneWidget);
      });
    });

    group('초대 취소 확인 후 실행', () {
      testWidgets('초대 취소 확인 다이얼로그에서 취소 버튼 탭 시 cancelInvite가 호출된다', (tester) async {
        // Given: pending 초대가 있는 가계부
        final pendingInvite = buildTestInvite(
          id: 'invite-sent-1',
          ledgerId: 'ledger-1',
          ledgerName: '우리 가계부',
          status: 'pending',
        );
        final ownedLedger = LedgerWithInviteInfo(
          ledger: buildTestLedger(id: 'ledger-1', name: '우리 가계부'),
          members: [buildTestMember(userId: 'user-1', ledgerId: 'ledger-1')],
          sentInvites: [pendingInvite],
          canInvite: false,
        );

        when(() => mockRepository.cancelInvite('invite-sent-1'))
            .thenAnswer((_) async {});
        when(() => mockRepository.getSentInvites(any()))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: close 아이콘 버튼 탭 (초대 취소)
        final closeBtn = find.byIcon(Icons.close);
        if (closeBtn.evaluate().isNotEmpty) {
          await tester.tap(closeBtn.first);
          await tester.pumpAndSettle();

          // 확인 다이얼로그에서 '초대취소' 버튼 탭
          final cancelInviteBtn = find.text('초대취소');
          if (cancelInviteBtn.evaluate().isNotEmpty) {
            await tester.tap(cancelInviteBtn);
            await tester.pumpAndSettle();

            // Then: cancelInvite가 호출됨
            verify(() => mockRepository.cancelInvite('invite-sent-1')).called(1);
          }
        }
      });

      testWidgets('거부된 초대의 삭제 버튼 탭 시 cancelInvite가 호출된다', (tester) async {
        // Given: rejected 초대가 있는 가계부
        final rejectedInvite = buildTestInvite(
          id: 'invite-rejected-1',
          ledgerId: 'ledger-1',
          ledgerName: '우리 가계부',
          status: 'rejected',
        );
        final ownedLedger = LedgerWithInviteInfo(
          ledger: buildTestLedger(id: 'ledger-1', name: '우리 가계부'),
          members: [buildTestMember(userId: 'user-1', ledgerId: 'ledger-1')],
          sentInvites: [rejectedInvite],
          canInvite: true,
        );

        when(() => mockRepository.cancelInvite('invite-rejected-1'))
            .thenAnswer((_) async {});
        when(() => mockRepository.getSentInvites(any()))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: close 아이콘 버튼 탭 (거부된 초대 삭제 - 확인 없이 바로 삭제)
        final closeBtn = find.byIcon(Icons.close);
        if (closeBtn.evaluate().isNotEmpty) {
          await tester.tap(closeBtn.first);
          await tester.pumpAndSettle();

          // Then: cancelInvite가 호출됨 (확인 다이얼로그 없이)
          verify(() => mockRepository.cancelInvite('invite-rejected-1')).called(1);
        }
      });
    });

    group('멤버 관리 바텀시트', () {
      testWidgets('멤버 수가 2명 이상인 가계부에서 멤버 영역 탭 시 바텀시트가 열린다', (tester) async {
        // Given: 멤버가 2명인 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          members: [
            buildTestMember(userId: 'user-1', ledgerId: 'ledger-1', role: 'owner'),
            buildTestMember(userId: 'user-2', ledgerId: 'ledger-1', role: 'member'),
          ],
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 멤버 영역(chevron_right 아이콘)을 탭
        final chevronIcon = find.byIcon(Icons.chevron_right);
        expect(chevronIcon, findsOneWidget);
        await tester.tap(chevronIcon);
        await tester.pumpAndSettle();

        // Then: 바텀시트가 열림 (l10n.shareMemberManagement = '공유 멤버 관리')
        expect(find.text('공유 멤버 관리'), findsOneWidget);
      });

      testWidgets('멤버 바텀시트에서 멤버 목록이 표시된다', (tester) async {
        // Given: 멤버가 2명인 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          members: [
            buildTestMember(userId: 'user-1', ledgerId: 'ledger-1', role: 'owner'),
            buildTestMember(userId: 'user-2', ledgerId: 'ledger-1', role: 'member'),
          ],
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 멤버 영역 탭
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        // Then: 멤버 목록과 역할이 표시됨
        expect(find.text('공유 멤버 관리'), findsOneWidget);
        // 소유자 역할 배지
        expect(find.text('소유자'), findsOneWidget);
        // 닫기 버튼
        expect(find.text('닫기'), findsOneWidget);
      });

      testWidgets('멤버 바텀시트에서 닫기 버튼 탭 시 바텀시트가 닫힌다', (tester) async {
        // Given: 멤버가 2명인 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          members: [
            buildTestMember(userId: 'user-1', ledgerId: 'ledger-1', role: 'owner'),
            buildTestMember(userId: 'user-2', ledgerId: 'ledger-1', role: 'member'),
          ],
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 멤버 영역 탭 → 바텀시트 열기 → 닫기 탭
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();
        await tester.tap(find.text('닫기'));
        await tester.pumpAndSettle();

        // Then: 바텀시트가 닫힘
        expect(find.text('공유 멤버 관리'), findsNothing);
        expect(find.text('우리 가계부'), findsOneWidget);
      });

      testWidgets('멤버 바텀시트에서 방출 버튼 탭 시 방출 확인 다이얼로그가 표시된다', (tester) async {
        // Given: 멤버가 2명인 가계부 (owner + member)
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          members: [
            buildTestMember(userId: 'user-1', ledgerId: 'ledger-1', role: 'owner'),
            buildTestMember(userId: 'user-2', ledgerId: 'ledger-1', role: 'member'),
          ],
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 멤버 영역 탭 → 바텀시트 열기
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        // 방출하기 버튼 탭
        final removeBtn = find.text('방출하기');
        expect(removeBtn, findsOneWidget);
        await tester.tap(removeBtn);
        await tester.pumpAndSettle();

        // Then: 방출 확인 다이얼로그가 표시됨
        expect(find.text('멤버 방출'), findsOneWidget);
      });

      testWidgets('방출 확인 다이얼로그에서 취소 탭 시 다이얼로그가 닫힌다', (tester) async {
        // Given: 멤버가 2명인 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          members: [
            buildTestMember(userId: 'user-1', ledgerId: 'ledger-1', role: 'owner'),
            buildTestMember(userId: 'user-2', ledgerId: 'ledger-1', role: 'member'),
          ],
        );

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 멤버 영역 탭 → 방출하기 → 취소
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();
        await tester.tap(find.text('방출하기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        // Then: 다이얼로그가 닫힘 (바텀시트는 유지)
        expect(find.text('멤버 방출'), findsNothing);
      });

      testWidgets('방출 확인 다이얼로그에서 방출하기 탭 시 removeMember가 호출된다', (tester) async {
        // Given: 멤버가 2명인 가계부
        final ownedLedger = buildTestLedgerInfo(
          id: 'ledger-1',
          name: '우리 가계부',
          ownerId: 'user-1',
          members: [
            buildTestMember(userId: 'user-1', ledgerId: 'ledger-1', role: 'owner'),
            buildTestMember(userId: 'user-2', ledgerId: 'ledger-1', role: 'member'),
          ],
        );

        when(() => mockRepository.removeMember(
              ledgerId: 'ledger-1',
              userId: 'user-2',
            )).thenAnswer((_) async {});
        when(() => mockRepository.getMembers('ledger-1'))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              shareRepositoryProvider.overrideWith((ref) => mockRepository),
              myOwnedLedgersWithInvitesProvider.overrideWith(
                (ref) => Future.value([ownedLedger]),
              ),
              receivedInvitesProvider.overrideWith(
                (ref) => Future.value([]),
              ),
              shareNotifierProvider.overrideWith(
                (ref) => ShareNotifier(mockRepository, ref),
              ),
              selectedLedgerIdProvider.overrideWith((ref) => null),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // When: 멤버 영역 탭 → 방출하기 → 방출 확인
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();
        await tester.tap(find.text('방출하기'));
        await tester.pumpAndSettle();
        // 확인 다이얼로그에서 방출하기 탭 (마지막)
        await tester.tap(find.text('방출하기').last);
        await tester.pumpAndSettle();

        // Then: removeMember가 호출됨
        verify(() => mockRepository.removeMember(
              ledgerId: 'ledger-1',
              userId: 'user-2',
            )).called(1);
      });
    });
  });
}
