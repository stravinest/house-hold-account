import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/utils/dialog_utils.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('DialogUtils', () {
    group('showConfirmation', () {
      testWidgets('다이얼로그가 올바른 제목과 메시지로 표시된다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      DialogUtils.showConfirmation(
                        context,
                        title: '카테고리 삭제',
                        message: '정말로 삭제하시겠습니까?',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // 버튼 클릭하여 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 다이얼로그가 표시되는지 확인
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('카테고리 삭제'), findsOneWidget);
        expect(find.text('정말로 삭제하시겠습니까?'), findsOneWidget);
      });

      testWidgets('확인 버튼을 누르면 true를 반환한다', (WidgetTester tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      result = await DialogUtils.showConfirmation(
                        context,
                        title: '삭제 확인',
                        message: '삭제하시겠습니까?',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 확인 버튼 찾기 및 클릭
        final confirmButton = find.text('확인');
        expect(confirmButton, findsOneWidget);
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        // 결과 확인
        expect(result, equals(true));
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('취소 버튼을 누르면 null을 반환한다', (WidgetTester tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      result = await DialogUtils.showConfirmation(
                        context,
                        title: '삭제 확인',
                        message: '삭제하시겠습니까?',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 취소 버튼 찾기 및 클릭
        final cancelButton = find.text('취소');
        expect(cancelButton, findsOneWidget);
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // 결과 확인
        expect(result, isNull);
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('다이얼로그 외부를 탭하면 null을 반환한다', (WidgetTester tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      result = await DialogUtils.showConfirmation(
                        context,
                        title: '삭제 확인',
                        message: '삭제하시겠습니까?',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 다이얼로그 외부 탭 (배리어 탭)
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // 결과 확인
        expect(result, isNull);
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('커스텀 확인 버튼 텍스트를 사용할 수 있다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      DialogUtils.showConfirmation(
                        context,
                        title: '삭제 확인',
                        message: '이 작업은 되돌릴 수 없습니다.',
                        confirmText: '삭제',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 커스텀 확인 버튼 텍스트 확인
        expect(find.text('삭제'), findsOneWidget);
        expect(find.text('확인'), findsNothing);
      });

      testWidgets('커스텀 취소 버튼 텍스트를 사용할 수 있다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      DialogUtils.showConfirmation(
                        context,
                        title: '삭제 확인',
                        message: '이 작업은 되돌릴 수 없습니다.',
                        cancelText: '아니오',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 커스텀 취소 버튼 텍스트 확인
        expect(find.text('아니오'), findsOneWidget);
        expect(find.text('취소'), findsNothing);
      });

      testWidgets('확인과 취소 버튼 텍스트를 모두 커스텀할 수 있다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      DialogUtils.showConfirmation(
                        context,
                        title: '저장 확인',
                        message: '변경사항을 저장하시겠습니까?',
                        confirmText: '저장',
                        cancelText: '나가기',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 커스텀 버튼 텍스트 확인
        expect(find.text('저장'), findsOneWidget);
        expect(find.text('나가기'), findsOneWidget);
        expect(find.text('확인'), findsNothing);
        expect(find.text('취소'), findsNothing);
      });

      testWidgets('기본 버튼 텍스트는 l10n을 사용한다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      DialogUtils.showConfirmation(
                        context,
                        title: '확인',
                        message: '계속하시겠습니까?',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 기본 l10n 버튼 텍스트 확인 (한국어)
        expect(find.text('확인'), findsNWidgets(2)); // 제목과 버튼
        expect(find.text('취소'), findsOneWidget);
      });

      testWidgets('두 개의 TextButton이 액션으로 표시된다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      DialogUtils.showConfirmation(
                        context,
                        title: '확인',
                        message: '메시지',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // 다이얼로그 표시
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // TextButton 개수 확인
        expect(find.byType(TextButton), findsNWidgets(2));
      });
    });

    group('다양한 메시지 형태', () {
      testWidgets('짧은 메시지를 올바르게 표시한다', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      DialogUtils.showConfirmation(
                        context,
                        title: '확인',
                        message: '삭제?',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('삭제?'), findsOneWidget);
      });

      testWidgets('긴 메시지를 올바르게 표시한다', (WidgetTester tester) async {
        const longMessage =
            '이 카테고리를 삭제하면 관련된 모든 거래 내역의 카테고리 정보가 사라집니다. '
            '이 작업은 되돌릴 수 없습니다. 정말로 삭제하시겠습니까?';

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      DialogUtils.showConfirmation(
                        context,
                        title: '삭제 확인',
                        message: longMessage,
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text(longMessage), findsOneWidget);
      });

      testWidgets('여러 줄 메시지를 올바르게 표시한다', (WidgetTester tester) async {
        const multilineMessage =
            '다음 항목들이 삭제됩니다:\n'
            '- 카테고리 정보\n'
            '- 관련 거래 내역\n'
            '- 통계 데이터';

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      DialogUtils.showConfirmation(
                        context,
                        title: '삭제 확인',
                        message: multilineMessage,
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text(multilineMessage), findsOneWidget);
      });
    });

    group('반환값 동작', () {
      testWidgets('커스텀 확인 버튼으로도 true를 반환한다', (WidgetTester tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      result = await DialogUtils.showConfirmation(
                        context,
                        title: '삭제',
                        message: '삭제하시겠습니까?',
                        confirmText: '삭제하기',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('삭제하기'));
        await tester.pumpAndSettle();

        expect(result, equals(true));
      });

      testWidgets('커스텀 취소 버튼으로도 null을 반환한다', (WidgetTester tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      result = await DialogUtils.showConfirmation(
                        context,
                        title: '저장',
                        message: '저장하시겠습니까?',
                        cancelText: '나중에',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('나중에'));
        await tester.pumpAndSettle();

        expect(result, isNull);
      });
    });
  });
}
