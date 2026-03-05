import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/presentation/pages/transaction_guide_page.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/guide_common_widgets.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget _buildTestApp() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: const TransactionGuidePage(),
  );
}

void main() {
  group('TransactionGuidePage 위젯 테스트', () {
    testWidgets('기본 구조가 렌더링되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('안내 배너(GuideInfoBanner)가 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byType(GuideInfoBanner), findsOneWidget);
    });

    testWidgets('스텝 헤더(GuideStepHeader)들이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then - 6개의 스텝이 있음
      expect(find.byType(GuideStepHeader), findsAtLeastNWidgets(1));
    });

    testWidgets('스텝 카드(GuideStepCard)들이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byType(GuideStepCard), findsAtLeastNWidgets(1));
    });

    testWidgets('페이지를 스크롤해도 오류 없이 동작해야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // ListView 스크롤
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // Then - 스크롤 후에도 페이지가 정상 렌더링되어야 한다
      expect(find.byType(TransactionGuidePage), findsOneWidget);
    });

    testWidgets('TransactionGuidePage는 StatelessWidget이어야 한다', (tester) async {
      // Then
      expect(const TransactionGuidePage(), isA<StatelessWidget>());
    });
  });
}
