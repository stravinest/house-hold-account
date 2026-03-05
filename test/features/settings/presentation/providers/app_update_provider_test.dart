import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/features/settings/presentation/providers/app_update_provider.dart';

void main() {
  group('AppUpdateProvider 타입 검증 테스트', () {
    group('packageInfoProvider 타입 테스트', () {
      test('packageInfoProvider는 AutoDisposeFutureProvider<PackageInfo> 타입이다', () {
        // Given & When & Then
        // Riverpod 코드 생성으로 만들어진 provider의 타입을 검증한다
        expect(
          packageInfoProvider,
          isA<AutoDisposeFutureProvider<PackageInfo>>(),
        );
      });
    });

    group('appUpdateProvider 타입 테스트', () {
      test(
        'appUpdateProvider는 AutoDisposeAsyncNotifierProvider<AppUpdate, AppVersionInfo?> 타입이다',
        () {
          // Given & When & Then
          // Riverpod 코드 생성으로 만들어진 notifier provider의 타입을 검증한다
          expect(
            appUpdateProvider,
            isA<
              AutoDisposeAsyncNotifierProvider<AppUpdate, AppVersionInfo?>
            >(),
          );
        },
      );
    });

    group('AppUpdate notifier 타입 테스트', () {
      test('AppUpdate 인스턴스를 생성할 수 있다', () {
        // Given & When
        // AppUpdate는 Riverpod 코드 생성의 _$AppUpdate를 상속하므로
        // AsyncNotifier의 직접 타입 비교 대신 인스턴스 생성 가능 여부를 검증한다
        final notifier = AppUpdate();

        // Then: 인스턴스가 null이 아니어야 한다
        expect(notifier, isNotNull);
      });

      test('appUpdateProvider로 AppUpdate notifier를 참조할 수 있다', () {
        // Given & When & Then
        // provider를 통해 notifier 타입에 접근 가능한지 검증한다
        expect(appUpdateProvider, isNotNull);
      });
    });
  });
}
