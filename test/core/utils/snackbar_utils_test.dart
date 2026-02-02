import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/utils/snackbar_utils.dart';
import 'package:shared_household_account/shared/themes/design_tokens.dart';

void main() {
  group('SnackBarUtils', () {
    group('showSuccess', () {
      testWidgets('성공 메시지를 올바르게 표시한다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showSuccess(context, '카테고리가 삭제되었습니다');
                    },
                    child: const Text('Show Success'),
                  );
                },
              ),
            ),
          ),
        );

        // 버튼 클릭하여 SnackBar 표시
        await tester.tap(find.text('Show Success'));
        await tester.pump();

        // SnackBar가 표시되는지 확인
        expect(find.text('카테고리가 삭제되었습니다'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('녹색 배경색을 사용한다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showSuccess(context, '성공');
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, equals(Colors.green[700]));
      });

      testWidgets('기본 지속 시간은 SnackBarDuration.short를 사용한다', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showSuccess(context, '성공');
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.duration, equals(SnackBarDuration.short));
      });

      testWidgets('커스텀 지속 시간을 사용할 수 있다', (WidgetTester tester) async {
        const customDuration = Duration(seconds: 5);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showSuccess(
                        context,
                        '성공',
                        duration: customDuration,
                      );
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.duration, equals(customDuration));
      });
    });

    group('showError', () {
      testWidgets('에러 메시지를 올바르게 표시한다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showError(context, '삭제에 실패했습니다');
                    },
                    child: const Text('Show Error'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pump();

        expect(find.text('삭제에 실패했습니다'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('빨간색 배경색을 사용한다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showError(context, '에러');
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, equals(Colors.red[700]));
      });

      testWidgets('기본 지속 시간은 SnackBarDuration.short를 사용한다', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showError(context, '에러');
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.duration, equals(SnackBarDuration.short));
      });

      testWidgets('커스텀 지속 시간을 사용할 수 있다', (WidgetTester tester) async {
        const customDuration = Duration(seconds: 3);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showError(
                        context,
                        '에러',
                        duration: customDuration,
                      );
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.duration, equals(customDuration));
      });
    });

    group('showInfo', () {
      testWidgets('정보 메시지를 올바르게 표시한다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showInfo(context, '변경사항이 저장되었습니다');
                    },
                    child: const Text('Show Info'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Info'));
        await tester.pump();

        expect(find.text('변경사항이 저장되었습니다'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('기본 배경색을 사용한다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showInfo(context, '정보');
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        // 정보 메시지는 backgroundColor가 null (테마 기본값 사용)
        expect(snackBar.backgroundColor, isNull);
      });

      testWidgets('기본 지속 시간은 SnackBarDuration.short를 사용한다', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showInfo(context, '정보');
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.duration, equals(SnackBarDuration.short));
      });

      testWidgets('커스텀 지속 시간을 사용할 수 있다', (WidgetTester tester) async {
        const customDuration = Duration(seconds: 4);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showInfo(
                        context,
                        '정보',
                        duration: customDuration,
                      );
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.duration, equals(customDuration));
      });
    });

    group('context.mounted 체크', () {
      testWidgets('unmounted context에서는 SnackBar를 표시하지 않는다', (
        WidgetTester tester,
      ) async {
        // 이 테스트는 context.mounted가 false일 때 에러가 발생하지 않음을 확인
        BuildContext? savedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  savedContext = context;
                  return const Text('Test');
                },
              ),
            ),
          ),
        );

        // 위젯 트리에서 제거
        await tester.pumpWidget(const SizedBox.shrink());

        // unmounted context로 호출해도 에러가 발생하지 않아야 함
        expect(
          () => SnackBarUtils.showSuccess(savedContext!, '메시지'),
          returnsNormally,
        );
      });
    });

    group('다양한 메시지 길이', () {
      testWidgets('짧은 메시지를 올바르게 표시한다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showSuccess(context, '완료');
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.text('완료'), findsOneWidget);
      });

      testWidgets('긴 메시지를 올바르게 표시한다', (WidgetTester tester) async {
        const longMessage =
            '이것은 매우 긴 메시지입니다. 사용자에게 자세한 정보를 제공하기 위해 여러 문장으로 구성될 수 있습니다.';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showInfo(context, longMessage);
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.text(longMessage), findsOneWidget);
      });

      testWidgets('빈 문자열을 표시할 수 있다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SnackBarUtils.showSuccess(context, '');
                    },
                    child: const Text('Show'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        // 빈 문자열이어도 SnackBar는 표시됨
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });
  });
}
