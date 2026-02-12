import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/share/domain/entities/ledger_invite.dart';
import 'package:shared_household_account/features/share/presentation/widgets/invited_ledger_card.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('InvitedLedgerCard 위젯 테스트', () {
    late LedgerInvite testInvite;

    setUp(() {
      testInvite = LedgerInvite(
        id: 'invite-1',
        ledgerId: 'ledger-1',
        inviterUserId: 'user-1',
        inviteeEmail: 'invitee@test.com',
        role: 'member',
        status: 'pending',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
        ledgerName: '우리 가족 가계부',
        inviterEmail: 'inviter@test.com',
      );
    });

    testWidgets('필수 프로퍼티로 정상 렌더링된다', (tester) async {
      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: InvitedLedgerCard(invite: testInvite),
          ),
        ),
      );

      // Then
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('우리 가족 가계부'), findsOneWidget);
    });

    testWidgets('isCurrentLedger가 true이면 사용중 배지가 표시된다', (tester) async {
      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: InvitedLedgerCard(
              invite: testInvite,
              isCurrentLedger: true,
            ),
          ),
        ),
      );

      // Then
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 2);
    });

    testWidgets('pending 상태일 때 수락/거부 버튼이 표시된다', (tester) async {
      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: InvitedLedgerCard(
              invite: testInvite,
              onAccept: () {},
              onReject: () {},
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(OutlinedButton), findsNWidgets(2));
    });

    testWidgets('수락 버튼을 탭하면 onAccept 콜백이 호출된다', (tester) async {
      // Given
      var acceptCalled = false;
      void onAccept() {
        acceptCalled = true;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: InvitedLedgerCard(
              invite: testInvite,
              onAccept: onAccept,
              onReject: () {},
            ),
          ),
        ),
      );

      // When - 수락 버튼 탭
      final acceptButtons = find.byType(OutlinedButton);
      await tester.tap(acceptButtons.last);
      await tester.pumpAndSettle();

      // Then
      expect(acceptCalled, true);
    });

    testWidgets('accepted 상태일 때 사용/탈퇴 버튼이 표시된다', (tester) async {
      // Given
      final acceptedInvite = LedgerInvite(
        id: testInvite.id,
        ledgerId: testInvite.ledgerId,
        inviterUserId: testInvite.inviterUserId,
        inviteeEmail: testInvite.inviteeEmail,
        role: testInvite.role,
        status: 'accepted',
        expiresAt: testInvite.expiresAt,
        createdAt: testInvite.createdAt,
        ledgerName: testInvite.ledgerName,
        inviterEmail: testInvite.inviterEmail,
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: InvitedLedgerCard(
              invite: acceptedInvite,
              onSelectLedger: () {},
              onLeave: () {},
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(OutlinedButton), findsNWidgets(2));
    });

    testWidgets('isCurrentLedger이면 사용 버튼이 표시되지 않는다', (tester) async {
      // Given
      final acceptedInvite = LedgerInvite(
        id: testInvite.id,
        ledgerId: testInvite.ledgerId,
        inviterUserId: testInvite.inviterUserId,
        inviteeEmail: testInvite.inviteeEmail,
        role: testInvite.role,
        status: 'accepted',
        expiresAt: testInvite.expiresAt,
        createdAt: testInvite.createdAt,
        ledgerName: testInvite.ledgerName,
        inviterEmail: testInvite.inviterEmail,
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: InvitedLedgerCard(
              invite: acceptedInvite,
              isCurrentLedger: true,
              onLeave: () {},
            ),
          ),
        ),
      );

      // Then - 탈퇴 버튼만 표시
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('rejected 상태일 때 거부됨 표시가 나온다', (tester) async {
      // Given
      final rejectedInvite = LedgerInvite(
        id: testInvite.id,
        ledgerId: testInvite.ledgerId,
        inviterUserId: testInvite.inviterUserId,
        inviteeEmail: testInvite.inviteeEmail,
        role: testInvite.role,
        status: 'rejected',
        expiresAt: testInvite.expiresAt,
        createdAt: testInvite.createdAt,
        ledgerName: testInvite.ledgerName,
        inviterEmail: testInvite.inviterEmail,
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: InvitedLedgerCard(invite: rejectedInvite),
          ),
        ),
      );

      // Then
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('isLoading이 true이면 버튼이 비활성화된다', (tester) async {
      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: InvitedLedgerCard(
              invite: testInvite,
              isLoading: true,
              onAccept: () {},
              onReject: () {},
            ),
          ),
        ),
      );

      // Then
      final buttons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
      for (final button in buttons) {
        expect(button.onPressed, isNull);
      }
    });
  });
}
