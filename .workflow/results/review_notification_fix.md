# 코드 리뷰 결과

## 요약
- 검토 파일: 4개
- Critical: 0개 / High: 2개 / Medium: 4개 / Low: 3개

---

## High 이슈

### [learned_sms_format_repository.dart:142-143] 에러 무시로 인한 잠재적 문제 진단 어려움

- **파일**: `/Users/eungyu/Desktop/개인/project/house-hold-account/lib/features/payment_method/data/repositories/learned_sms_format_repository.dart`
- **라인**: 142-143
- **문제**: 폴백 업데이트 실패 시 에러를 완전히 무시(empty catch)하고 있어, 실제 문제 발생 시 원인 파악이 어려움
- **위험**: match_count 업데이트가 지속적으로 실패해도 인지할 수 없어 데이터 정확성 문제 발생 가능
- **현재 코드**:
```dart
} catch (e) {
  // 업데이트 실패 시 무시 (match_count는 중요하지 않음)
}
```
- **해결**: 최소한 debugPrint로 로그를 남기거나, 에러 발생 빈도를 모니터링할 수 있도록 개선
```dart
} catch (e) {
  // match_count는 중요하지 않지만 지속적 실패 시 확인 필요
  debugPrint('[LearnedSmsFormat] incrementMatchCount fallback failed: $e');
}
```

---

### [pending_transaction_repository.dart:100-104] INSERT 실패 시 에러 메시지의 정보 부족

- **파일**: `/Users/eungyu/Desktop/개인/project/house-hold-account/lib/features/payment_method/data/repositories/pending_transaction_repository.dart`
- **라인**: 100-104
- **문제**: RLS 정책으로 INSERT가 차단된 경우, 실제 원인(ledger_members 테이블의 멤버십 여부 등)을 파악하기 어려운 메시지
- **위험**: 디버깅 시 RLS 정책의 어떤 조건이 실패했는지 추적하기 어려움
- **현재 코드**:
```dart
if ((response as List).isEmpty) {
  throw Exception(
    'INSERT returned 0 rows - RLS policy may have blocked the insert. '
    'ledgerId: $ledgerId, userId: $userId, authUid: ${currentAuthUser.id}',
  );
}
```
- **해결**: 추가 진단 정보(ledger_members 존재 여부 등)를 쿼리하여 포함하거나, Supabase의 실제 에러 응답을 활용
```dart
if ((response as List).isEmpty) {
  // 추가 진단: 해당 사용자가 ledger의 멤버인지 확인
  final memberCheck = await _client
      .from('ledger_members')
      .select('role')
      .eq('ledger_id', ledgerId)
      .eq('user_id', userId)
      .maybeSingle();
  
  throw Exception(
    'INSERT returned 0 rows - RLS policy may have blocked the insert. '
    'ledgerId: $ledgerId, userId: $userId, authUid: ${currentAuthUser.id}, '
    'isMember: ${memberCheck != null}, role: ${memberCheck?['role']}',
  );
}
```

---

## Medium 이슈

### [simulate_suwonpay.sh:63-67] 인증 토큰 파일 권한 및 보안

- **파일**: `/Users/eungyu/Desktop/개인/project/house-hold-account/scripts/simulate_suwonpay.sh`
- **라인**: 63-67
- **문제**: 에뮬레이터 인증 토큰을 읽을 수 없을 때 경고만 출력하고 계속 진행하여 불필요한 실패 시도 발생
- **위험**: 토큰 없이 명령 전송 시 실패하고, 사용자에게 혼란을 줄 수 있음
- **현재 코드**:
```bash
if [ -z "$AUTH_TOKEN" ]; then
    echo "경고: 인증 토큰을 찾을 수 없습니다. ~/.emulator_console_auth_token 파일을 확인하세요."
fi
```
- **해결**: 토큰이 없으면 조기 종료하거나, 실패 가능성을 더 명확히 안내
```bash
if [ -z "$AUTH_TOKEN" ]; then
    echo "에러: 인증 토큰을 찾을 수 없습니다."
    echo "~/.emulator_console_auth_token 파일을 확인하세요."
    echo "파일이 없으면 에뮬레이터가 생성하지 않았을 수 있습니다."
    return 1
fi
```

---

### [notification_listener_wrapper.dart:225-227] 디버그 로그에 민감 정보 포함 가능성

- **파일**: `/Users/eungyu/Desktop/개인/project/house-hold-account/lib/features/payment_method/data/services/notification_listener_wrapper.dart`
- **라인**: 186-227
- **문제**: 알림 내용(content)과 결제수단 정보를 상세히 로깅하고 있어, 릴리스 빌드에서도 로그가 출력될 수 있음
- **위험**: 사용자의 금융 거래 정보가 로그에 남을 수 있음 (금액, 가맹점, 결제수단 등)
- **현재 코드**:
```dart
debugPrint('[NotificationListener] Received notification:');
debugPrint('  - packageName: ${event.packageName}');
debugPrint('  - title: ${event.title}');
debugPrint('  - content: ${event.content}');
```
- **해결**: kDebugMode 체크를 추가하거나, 민감 정보 마스킹
```dart
if (kDebugMode) {
  debugPrint('[NotificationListener] Received notification:');
  debugPrint('  - packageName: ${event.packageName}');
  debugPrint('  - title: ${event.title}');
  // content는 금액/가맹점 정보 포함 가능 - 일부만 출력
  final contentPreview = (event.content ?? '').length > 20 
      ? '${event.content!.substring(0, 20)}...' 
      : event.content;
  debugPrint('  - content preview: $contentPreview');
}
```

---

### [learned_sms_format_repository.dart:117-145] Race condition 가능성 명시적 처리 부족

- **파일**: `/Users/eungyu/Desktop/개인/project/house-hold-account/lib/features/payment_method/data/repositories/learned_sms_format_repository.dart`
- **라인**: 117-145
- **문제**: RPC 함수가 없을 때 폴백으로 read-then-write 패턴을 사용하여 동시성 문제 발생 가능
- **위험**: 동시에 여러 알림이 처리될 때 match_count가 정확하지 않을 수 있음
- **현재 코드**:
```dart
// RPC 함수가 없으면 직접 업데이트 (race condition 가능성 있음)
final current = await _client
    .from('learned_sms_formats')
    .select('match_count')
    .eq('id', id)
    .maybeSingle();
// ... 이후 update
```
- **해결**: 주석에 이미 언급되어 있으나, RPC 함수를 생성하는 마이그레이션을 추가하는 것이 바람직함. 또는 Supabase의 RPC로 원자적 증가 구현
```sql
-- supabase/migrations/xxx_add_increment_function.sql
CREATE OR REPLACE FUNCTION increment_sms_format_match_count(format_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE learned_sms_formats 
  SET match_count = match_count + 1, updated_at = NOW()
  WHERE id = format_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

### [notification_listener_wrapper.dart:68] 테스트용 패키지 하드코딩

- **파일**: `/Users/eungyu/Desktop/개인/project/house-hold-account/lib/features/payment_method/data/services/notification_listener_wrapper.dart`
- **라인**: 68
- **문제**: `com.android.shell` (ADB 테스트용)이 프로덕션 코드에 하드코딩되어 있음
- **위험**: 릴리스 빌드에서 shell 명령을 통한 알림이 금융 알림으로 처리될 수 있음 (보안상 미미하나 의도치 않은 동작 가능)
- **현재 코드**:
```dart
'com.android.shell', // For ADB testing
```
- **해결**: kDebugMode로 조건부 포함하거나, 테스트 환경 변수로 분리
```dart
static final Set<String> _financialAppPackagesLower = {
  'com.kbcard.cxh.appcard',
  // ... 다른 패키지들 ...
  if (kDebugMode) 'com.android.shell', // ADB 테스트용 - 디버그 모드에서만
};
```

---

## Low 이슈

### [simulate_suwonpay.sh:1-142] 한글 인코딩 주의 필요

- **파일**: `/Users/eungyu/Desktop/개인/project/house-hold-account/scripts/simulate_suwonpay.sh`
- **문제**: 스크립트에 한글이 포함되어 있어 일부 환경에서 인코딩 문제가 발생할 수 있음
- **위험**: 로케일 설정이 다른 환경에서 실행 시 문자가 깨질 수 있음
- **해결**: 스크립트 상단에 로케일 설정 추가
```bash
#!/bin/bash
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8
```

---

### [pending_transaction_repository.dart:210] catch 블록에서 에러 타입 미지정

- **파일**: `/Users/eungyu/Desktop/개인/project/house-hold-account/lib/features/payment_method/data/repositories/pending_transaction_repository.dart`
- **라인**: 210
- **문제**: `catch (_)`로 모든 예외를 무시하고 있어, 예상치 못한 에러도 삼켜버림
- **현재 코드**:
```dart
} catch (_) {
  return false;
}
```
- **해결**: 특정 예외만 처리하거나, 로깅 추가
```dart
} catch (e) {
  debugPrint('[PendingTransaction] checkDuplicate failed: $e');
  return false;
}
```

---

### [notification_listener_wrapper.dart:358] incrementMatchCount 실패 무시

- **파일**: `/Users/eungyu/Desktop/개인/project/house-hold-account/lib/features/payment_method/data/services/notification_listener_wrapper.dart`
- **라인**: 358
- **문제**: `incrementMatchCount` 호출의 결과를 확인하지 않고 있음 (await는 하지만 에러 처리 없음)
- **현재 코드**:
```dart
await _learnedSmsFormatRepository.incrementMatchCount(learnedFormat.id);
```
- **해결**: 현재 `incrementMatchCount`가 내부적으로 에러를 삼키므로 문제는 없지만, 호출자 측에서도 try-catch 고려
```dart
try {
  await _learnedSmsFormatRepository.incrementMatchCount(learnedFormat.id);
} catch (e) {
  // match_count 업데이트 실패는 치명적이지 않음
  debugPrint('[ProcessNotification] incrementMatchCount failed: $e');
}
```

---

## 긍정적인 점

1. **체계적인 디버그 로깅**: `notification_listener_wrapper.dart`에 추가된 디버그 로그가 문제 진단에 매우 유용함. 각 단계별로 상태를 확인할 수 있어 디버깅이 용이함

2. **방어적 프로그래밍**: `learned_sms_format_repository.dart`에서 `.single()` 대신 `.maybeSingle()`을 사용하여 결과가 없을 때의 예외를 방지함 - 이전에 발생했던 에러를 잘 수정함

3. **인증 검증 강화**: `pending_transaction_repository.dart`에서 RLS 정책 에러 진단을 위해 auth.currentUser 검증을 추가한 것은 좋은 접근

4. **에러 전파 원칙 준수**: `_createPendingTransaction`에서 에러 발생 시 `rethrow`하여 호출자에게 에러를 전파하고 있음 (프로젝트 CLAUDE.md 원칙 준수)

5. **코드 일관성**: 프로젝트의 코딩 컨벤션(작은따옴표 사용, 한글 주석 금지 등)을 잘 따르고 있음

---

## 추가 권장사항

### 1. RPC 함수 마이그레이션 추가
`increment_sms_format_match_count` RPC 함수가 없어 폴백 로직이 실행되고 있음. Supabase 마이그레이션으로 함수를 추가하는 것이 좋음:
```sql
-- supabase/migrations/xxx_add_increment_match_count.sql
CREATE OR REPLACE FUNCTION increment_sms_format_match_count(format_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE learned_sms_formats 
  SET match_count = COALESCE(match_count, 0) + 1,
      updated_at = NOW()
  WHERE id = format_id;
END;
$$;
```

### 2. 디버그 로그 릴리스 빌드 분리
현재 추가된 디버그 로그들이 릴리스 빌드에서도 출력될 수 있음. `kDebugMode` 체크를 추가하거나, 별도의 로깅 유틸리티를 만들어 환경별로 제어하는 것이 좋음

### 3. 테스트 코드 추가
수정된 코드에 대한 단위 테스트 추가 권장:
- `incrementMatchCount`의 RPC 실패 시 폴백 동작 테스트
- `createPendingTransaction`의 RLS 에러 시나리오 테스트
- Push 알림 파싱 및 저장 플로우 통합 테스트

### 4. 시뮬레이션 스크립트 문서화
`scripts/simulate_suwonpay.sh` 사용법을 README 또는 개발 문서에 추가하여 팀원들이 쉽게 테스트할 수 있도록 안내

---

## 리뷰어
- 리뷰 일시: 2026-01-23
- 리뷰 도구: Claude Code (Senior Code Review)
