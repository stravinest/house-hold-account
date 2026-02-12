import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_household_account/shared/widgets/markdown_document_page.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: child,
      ),
    );
  }

  group('PrivacyPolicyPage 위젯 테스트', () {
    testWidgets('MarkdownDocumentPage 위젯을 렌더링해야 한다',
        (WidgetTester tester) async {
      // When
      await tester.pumpWidget(
        buildTestWidget(
          const PrivacyPolicyPage(),
        ),
      );

      // Then
      expect(find.byType(MarkdownDocumentPage), findsOneWidget);
    });

    testWidgets('올바른 제목을 전달해야 한다', (WidgetTester tester) async {
      // When
      await tester.pumpWidget(
        buildTestWidget(
          const PrivacyPolicyPage(),
        ),
      );

      // Then
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      expect(find.text(l10n.settingsPrivacy), findsOneWidget);
    });

    testWidgets('올바른 파일 경로를 사용해야 한다', (WidgetTester tester) async {
      // When
      await tester.pumpWidget(
        buildTestWidget(
          const PrivacyPolicyPage(),
        ),
      );

      // Then
      final markdownPage = tester.widget<MarkdownDocumentPage>(
        find.byType(MarkdownDocumentPage),
      );
      expect(markdownPage.assetPath, equals('docs/privacy_policy.md'));
    });

    testWidgets('PrivacyPolicyPage는 StatelessWidget이어야 한다',
        (WidgetTester tester) async {
      // Then
      expect(const PrivacyPolicyPage(), isA<StatelessWidget>());
    });
  });
}
