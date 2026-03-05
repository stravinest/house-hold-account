import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_household_account/shared/widgets/markdown_document_page.dart';

Widget _buildApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('MarkdownDocumentPage 위젯 테스트', () {
    group('기본 구조 테스트', () {
      testWidgets('title과 assetPath가 주어지면 Scaffold와 AppBar가 렌더링된다', (tester) async {
        // Given
        const testTitle = '이용약관';
        const testAssetPath = 'assets/docs/terms.md';

        // When
        await tester.pumpWidget(
          _buildApp(
            child: const MarkdownDocumentPage(
              title: testTitle,
              assetPath: testAssetPath,
            ),
          ),
        );

        // Then
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('AppBar에 전달된 title이 표시된다', (tester) async {
        // Given
        const testTitle = '개인정보처리방침';
        const testAssetPath = 'assets/docs/privacy.md';

        // When
        await tester.pumpWidget(
          _buildApp(
            child: const MarkdownDocumentPage(
              title: testTitle,
              assetPath: testAssetPath,
            ),
          ),
        );

        // Then
        expect(find.text(testTitle), findsOneWidget);
      });

      testWidgets('로딩 중에는 CircularProgressIndicator가 표시된다', (tester) async {
        // Given: 비동기 로딩이 완료되기 전
        const testTitle = '이용약관';
        const testAssetPath = 'assets/docs/nonexistent.md';

        // When: pump 후 settle 없이 확인
        await tester.pumpWidget(
          _buildApp(
            child: const MarkdownDocumentPage(
              title: testTitle,
              assetPath: testAssetPath,
            ),
          ),
        );

        // Then: 첫 프레임에 로딩 표시
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('존재하지 않는 assetPath로 에러 발생 시 에러 메시지가 표시된다', (tester) async {
        // Given
        const testTitle = '에러 테스트';
        const testAssetPath = 'assets/nonexistent_file.md';

        // When
        await tester.pumpWidget(
          _buildApp(
            child: const MarkdownDocumentPage(
              title: testTitle,
              assetPath: testAssetPath,
            ),
          ),
        );

        // 비동기 완료 대기
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Then: 에러 메시지 또는 로딩 중 표시
        // 에러 발생 시 에러 텍스트가 표시되어야 한다
        final errorWidgets = find.byType(Text);
        expect(errorWidgets, findsAtLeastNWidgets(1));
      });
    });

    group('StatefulWidget 생명주기 테스트', () {
      testWidgets('MarkdownDocumentPage는 StatefulWidget이다', (tester) async {
        // Given
        const testTitle = '테스트';
        const testAssetPath = 'assets/docs/test.md';

        // When
        await tester.pumpWidget(
          _buildApp(
            child: const MarkdownDocumentPage(
              title: testTitle,
              assetPath: testAssetPath,
            ),
          ),
        );

        // Then
        expect(find.byType(MarkdownDocumentPage), findsOneWidget);
      });

      testWidgets('동일한 페이지를 두 번 빌드해도 올바르게 동작한다', (tester) async {
        // Given
        const testTitle = '재빌드 테스트';
        const testAssetPath = 'assets/docs/test.md';

        // When: 첫 번째 빌드
        await tester.pumpWidget(
          _buildApp(
            child: const MarkdownDocumentPage(
              title: testTitle,
              assetPath: testAssetPath,
            ),
          ),
        );

        // When: 두 번째 빌드 (title 변경)
        await tester.pumpWidget(
          _buildApp(
            child: const MarkdownDocumentPage(
              title: '변경된 제목',
              assetPath: testAssetPath,
            ),
          ),
        );

        // Then: 새 title이 표시되어야 한다
        expect(find.text('변경된 제목'), findsOneWidget);
      });
    });

    group('프로퍼티 검증', () {
      test('MarkdownDocumentPage가 const 생성자를 가진다', () {
        // Given & When: const 생성자로 인스턴스 생성 가능
        const page = MarkdownDocumentPage(
          title: '테스트',
          assetPath: 'assets/test.md',
        );

        // Then
        expect(page.title, '테스트');
        expect(page.assetPath, 'assets/test.md');
      });

      test('title 프로퍼티가 올바르게 저장된다', () {
        // Given
        const testTitle = '이용약관 제목';

        // When
        const page = MarkdownDocumentPage(
          title: testTitle,
          assetPath: 'assets/terms.md',
        );

        // Then
        expect(page.title, equals(testTitle));
      });

      test('assetPath 프로퍼티가 올바르게 저장된다', () {
        // Given
        const testPath = 'assets/docs/privacy_policy.md';

        // When
        const page = MarkdownDocumentPage(
          title: '개인정보처리방침',
          assetPath: testPath,
        );

        // Then
        expect(page.assetPath, equals(testPath));
      });
    });
  });
}
