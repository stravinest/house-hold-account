import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/app_update_dialog.dart';

Widget _buildTestApp(AppVersionInfo versionInfo) {
  return MaterialApp(
    home: Scaffold(
      body: AppUpdateDialog(versionInfo: versionInfo),
    ),
  );
}

void main() {
  group('AppUpdateDialog 추가 위젯 테스트', () {
    testWidgets('업데이트 버튼이 항상 표시되어야 한다', (tester) async {
      // Given
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
      );

      // When
      await tester.pumpWidget(_buildTestApp(versionInfo));
      await tester.pumpAndSettle();

      // Then: 업데이트 버튼 항상 표시
      expect(find.text('업데이트'), findsOneWidget);
    });

    testWidgets('강제 업데이트 시 AlertDialog가 표시되어야 한다', (tester) async {
      // Given
      const versionInfo = AppVersionInfo(
        version: '3.0.0',
        buildNumber: 300,
        isForceUpdate: true,
      );

      // When
      await tester.pumpWidget(_buildTestApp(versionInfo));
      await tester.pumpAndSettle();

      // Then: AlertDialog 렌더링
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('버전 정보 제목이 새 버전이 있습니다 텍스트여야 한다', (tester) async {
      // Given
      const versionInfo = AppVersionInfo(
        version: '2.5.0',
        buildNumber: 250,
      );

      // When
      await tester.pumpWidget(_buildTestApp(versionInfo));
      await tester.pumpAndSettle();

      // Then: 다이얼로그 타이틀 확인
      expect(find.text('새 버전이 있습니다'), findsOneWidget);
    });

    testWidgets('AppUpdateDialog.show() 정적 메서드로 강제 업데이트 다이얼로그를 표시할 수 있다', (tester) async {
      // Given: 강제 업데이트 버전
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        isForceUpdate: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppUpdateDialog.show(context, versionInfo),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );

      // When: 다이얼로그 열기
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // Then: 강제 업데이트 다이얼로그 표시 (나중에 버튼 없음)
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('나중에'), findsNothing);
      expect(find.text('업데이트'), findsOneWidget);
    });

    testWidgets('storeUrl이 있을 때 업데이트 버튼이 표시되어야 한다', (tester) async {
      // Given
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        storeUrl: 'https://play.google.com/store/apps/details?id=com.example',
      );

      // When
      await tester.pumpWidget(_buildTestApp(versionInfo));
      await tester.pumpAndSettle();

      // Then: 업데이트 버튼 표시
      expect(find.text('업데이트'), findsOneWidget);
    });

    testWidgets('storeUrl이 null일 때도 업데이트 버튼이 표시되어야 한다', (tester) async {
      // Given: storeUrl 없음 - 기본 URL 사용
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        storeUrl: null,
      );

      // When
      await tester.pumpWidget(_buildTestApp(versionInfo));
      await tester.pumpAndSettle();

      // Then: 업데이트 버튼 표시 (기본 URL 사용)
      expect(find.text('업데이트'), findsOneWidget);
    });

    testWidgets('릴리즈 노트가 빈 문자열이면 표시되지 않아야 한다', (tester) async {
      // Given: releaseNotes 빈 문자열
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        releaseNotes: '',
      );

      // When
      await tester.pumpWidget(_buildTestApp(versionInfo));
      await tester.pumpAndSettle();

      // Then: 릴리즈 노트 텍스트 없음 (빈 문자열은 표시 안함)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('FilledButton이 정확히 한 개 표시되어야 한다', (tester) async {
      // Given
      const versionInfo = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        isForceUpdate: false,
      );

      // When
      await tester.pumpWidget(_buildTestApp(versionInfo));
      await tester.pumpAndSettle();

      // Then: 업데이트 FilledButton 1개
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
