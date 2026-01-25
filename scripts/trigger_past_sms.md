# 과거 SMS 처리 트리거 가이드

## 방법 1: Flutter DevTools 사용

1. 앱 실행 중 Flutter DevTools 접속
2. Console에서 다음 명령 실행:
   ```dart
   AutoSaveService.instance.processPastSms(days: 1, maxCount: 10)
   ```

## 방법 2: 앱 재시작

1. SMS 삽입 후 앱 완전 종료
2. 앱 재시작
3. 결제수단 관리 화면 진입
4. 자동으로 최근 SMS를 스캔 (백그라운드 처리)

## 방법 3: 코드에 임시 버튼 추가

`payment_method_management_page.dart`의 AppBar actions에 추가:

```dart
actions: [
  if (kDebugMode)
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () async {
        await AutoSaveService.instance.processPastSms(
          days: 1,
          maxCount: 10,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('과거 SMS 처리 완료')),
        );
      },
    ),
],
```

## 방법 4: ADB로 앱 재시작

```bash
# 앱 강제 종료
adb -s R3CT90TAG8Z shell am force-stop com.household.shared.shared_household_account

# 앱 재시작
adb -s R3CT90TAG8Z shell am start -n com.household.shared.shared_household_account/com.household.shared.shared_household_account.MainActivity
```
