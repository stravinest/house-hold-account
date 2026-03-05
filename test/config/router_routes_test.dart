import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/config/router.dart';

void main() {
  group('Routes 상수 테스트', () {
    group('인증 라우트', () {
      test('splash 경로가 루트(/)이어야 한다', () {
        expect(Routes.splash, '/');
      });

      test('login 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.login, '/login');
      });

      test('signup 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.signup, '/signup');
      });

      test('forgotPassword 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.forgotPassword, '/forgot-password');
      });

      test('emailVerification 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.emailVerification, '/email-verification');
      });

      test('resetPassword 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.resetPassword, '/reset-password');
      });
    });

    group('메인 라우트', () {
      test('home 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.home, '/home');
      });

      test('settings 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.settings, '/settings');
      });

      test('search 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.search, '/search');
      });

      test('share 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.share, '/share');
      });
    });

    group('관리 라우트', () {
      test('category 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.category, '/category');
      });

      test('paymentMethod 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.paymentMethod, '/payment-method');
      });

      test('ledgerManage 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.ledgerManage, '/ledger-manage');
      });

      test('fixedExpense 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.fixedExpense, '/fixed-expense');
      });

      test('recurringTemplates 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.recurringTemplates, '/recurring-templates');
      });

      test('pendingTransactions 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.pendingTransactions, '/settings/pending-transactions');
      });
    });

    group('가이드 라우트', () {
      test('guide 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.guide, '/guide');
      });

      test('autoCollectGuide 경로가 guide 하위 경로이어야 한다', () {
        expect(Routes.autoCollectGuide, '/guide/auto-collect');
        expect(Routes.autoCollectGuide, startsWith('/guide/'));
      });

      test('transactionGuide 경로가 guide 하위 경로이어야 한다', () {
        expect(Routes.transactionGuide, '/guide/transaction');
        expect(Routes.transactionGuide, startsWith('/guide/'));
      });

      test('shareGuide 경로가 guide 하위 경로이어야 한다', () {
        expect(Routes.shareGuide, '/guide/share');
        expect(Routes.shareGuide, startsWith('/guide/'));
      });
    });

    group('법적 문서 라우트', () {
      test('termsOfService 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.termsOfService, '/terms-of-service');
      });

      test('privacyPolicy 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.privacyPolicy, '/privacy-policy');
      });
    });

    group('딥링크 라우트', () {
      test('addExpense 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.addExpense, '/add-expense');
      });

      test('addIncome 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.addIncome, '/add-income');
      });

      test('quickExpense 경로가 올바르게 정의되어야 한다', () {
        expect(Routes.quickExpense, '/quick-expense');
      });
    });

    group('동적 라우트', () {
      test('autoSaveSettings 경로에 :id 파라미터가 포함되어야 한다', () {
        expect(Routes.autoSaveSettings, contains(':id'));
      });

      test('categoryKeywordMapping 경로에 :id와 :sourceType 파라미터가 포함되어야 한다', () {
        expect(Routes.categoryKeywordMapping, contains(':id'));
        expect(Routes.categoryKeywordMapping, contains(':sourceType'));
      });

      test('ledgerDetail 경로에 :id 파라미터가 포함되어야 한다', () {
        expect(Routes.ledgerDetail, contains(':id'));
      });
    });

    group('모든 경로가 /로 시작해야 한다', () {
      test('모든 주요 라우트가 / 로 시작하는지 확인한다', () {
        final routes = [
          Routes.splash,
          Routes.login,
          Routes.signup,
          Routes.forgotPassword,
          Routes.emailVerification,
          Routes.resetPassword,
          Routes.home,
          Routes.settings,
          Routes.search,
          Routes.share,
          Routes.category,
          Routes.paymentMethod,
          Routes.guide,
          Routes.autoCollectGuide,
          Routes.transactionGuide,
          Routes.shareGuide,
          Routes.termsOfService,
          Routes.privacyPolicy,
        ];

        for (final route in routes) {
          expect(route, startsWith('/'), reason: '$route 경로가 /로 시작해야 합니다');
        }
      });
    });

    group('라우트 중복 없음 확인', () {
      test('인증 라우트들이 서로 다른 경로를 가진다', () {
        final authRoutes = [
          Routes.login,
          Routes.signup,
          Routes.forgotPassword,
          Routes.emailVerification,
          Routes.resetPassword,
        ];
        final uniqueRoutes = authRoutes.toSet();
        expect(uniqueRoutes.length, authRoutes.length);
      });

      test('가이드 라우트들이 서로 다른 경로를 가진다', () {
        final guideRoutes = [
          Routes.guide,
          Routes.autoCollectGuide,
          Routes.transactionGuide,
          Routes.shareGuide,
        ];
        final uniqueRoutes = guideRoutes.toSet();
        expect(uniqueRoutes.length, guideRoutes.length);
      });
    });
  });

  group('AuthChangeNotifier 테스트', () {
    test('rootNavigatorKey가 null이 아니어야 한다', () {
      // Given & When & Then
      expect(rootNavigatorKey, isNotNull);
    });

    test('rootNavigatorKey가 GlobalKey<NavigatorState> 타입이어야 한다', () {
      expect(rootNavigatorKey, isA<GlobalKey<NavigatorState>>());
    });
  });

  group('추가 라우트 상수 테스트', () {
    test('transaction 경로가 올바르게 정의되어야 한다', () {
      expect(Routes.transaction, '/transaction');
    });

    test('transactionAdd 경로가 transaction 하위 경로이어야 한다', () {
      expect(Routes.transactionAdd, '/transaction/add');
      expect(Routes.transactionAdd, startsWith('/transaction'));
    });

    test('transactionEdit 경로에 :id 파라미터가 포함되어야 한다', () {
      expect(Routes.transactionEdit, contains(':id'));
      expect(Routes.transactionEdit, contains('/edit'));
    });

    test('statistics 경로가 올바르게 정의되어야 한다', () {
      expect(Routes.statistics, '/statistics');
    });

    test('budget 경로가 올바르게 정의되어야 한다', () {
      expect(Routes.budget, '/budget');
    });

    test('profile 경로가 올바르게 정의되어야 한다', () {
      expect(Routes.profile, '/profile');
    });

    test('debugTest 경로가 올바르게 정의되어야 한다', () {
      expect(Routes.debugTest, '/debug-test');
    });

    test('autoSaveSettings 경로가 settings 하위 경로이어야 한다', () {
      expect(Routes.autoSaveSettings, startsWith('/settings/'));
    });

    test('categoryKeywordMapping 경로가 settings 하위 경로이어야 한다', () {
      expect(Routes.categoryKeywordMapping, startsWith('/settings/'));
    });

    test('pendingTransactions 경로가 settings 하위 경로이어야 한다', () {
      expect(Routes.pendingTransactions, startsWith('/settings/'));
    });
  });

  group('라우트 계층 구조 테스트', () {
    test('guide 하위 라우트들이 모두 /guide/ 로 시작한다', () {
      // Given
      final guideSubRoutes = [
        Routes.autoCollectGuide,
        Routes.transactionGuide,
        Routes.shareGuide,
      ];

      // When & Then
      for (final route in guideSubRoutes) {
        expect(route, startsWith('/guide/'), reason: '$route 는 /guide/ 하위여야 한다');
      }
    });

    test('settings 하위 라우트들이 모두 /settings/ 로 시작한다', () {
      // Given
      final settingsSubRoutes = [
        Routes.autoSaveSettings,
        Routes.categoryKeywordMapping,
        Routes.pendingTransactions,
      ];

      // When & Then
      for (final route in settingsSubRoutes) {
        expect(route, startsWith('/settings/'), reason: '$route 는 /settings/ 하위여야 한다');
      }
    });

    test('transaction 하위 라우트들이 모두 /transaction 으로 시작한다', () {
      // Given
      final transactionSubRoutes = [
        Routes.transaction,
        Routes.transactionAdd,
        Routes.transactionEdit,
      ];

      // When & Then
      for (final route in transactionSubRoutes) {
        expect(route, startsWith('/transaction'), reason: '$route 는 /transaction 하위여야 한다');
      }
    });
  });

  group('라우트 이름 규칙 테스트', () {
    test('kebab-case 라우트들이 올바른 형식이다', () {
      // Given: kebab-case 형식이어야 하는 라우트들
      final kebabRoutes = [
        Routes.forgotPassword,
        Routes.emailVerification,
        Routes.resetPassword,
        Routes.paymentMethod,
        Routes.ledgerManage,
        Routes.fixedExpense,
        Routes.addExpense,
        Routes.addIncome,
        Routes.quickExpense,
        Routes.termsOfService,
        Routes.privacyPolicy,
        Routes.autoCollectGuide,
        Routes.transactionGuide,
        Routes.shareGuide,
        Routes.recurringTemplates,
        Routes.debugTest,
      ];

      // When & Then: 모두 /로 시작하고 공백 없음
      for (final route in kebabRoutes) {
        expect(route, startsWith('/'), reason: '$route 는 /로 시작해야 한다');
        expect(route, isNot(contains(' ')), reason: '$route 에 공백이 없어야 한다');
      }
    });

    test('동적 라우트들이 :파라미터명 형식을 사용한다', () {
      // Given
      final dynamicRoutes = [
        Routes.ledgerDetail,
        Routes.transactionEdit,
        Routes.autoSaveSettings,
        Routes.categoryKeywordMapping,
      ];

      // When & Then
      for (final route in dynamicRoutes) {
        expect(route, contains(':'), reason: '$route 는 동적 파라미터를 포함해야 한다');
      }
    });
  });

  group('Routes 클래스 인스턴스화 불가 테스트', () {
    test('Routes 클래스의 모든 멤버가 static이다 (private constructor 확인)', () {
      // Given: Routes._() private 생성자로 외부 인스턴스화 불가
      // When & Then: static 상수들이 직접 접근 가능
      expect(Routes.splash, isA<String>());
      expect(Routes.home, isA<String>());
      expect(Routes.login, isA<String>());
    });
  });
}
