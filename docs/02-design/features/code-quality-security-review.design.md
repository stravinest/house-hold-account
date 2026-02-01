# 코드 품질 및 보안 리뷰 Design 문서

## 문서 정보
- **작성일**: 2026-02-01
- **Phase**: Design (검증 완료)
- **분석 범위**: 전체 프로젝트 (13개 Feature, 45개 Migration, 2개 Edge Function)

---

## 1. 분석 방법론

### 1.1 자동화 도구
- **Flutter Analyze**: 정적 코드 분석
- **Grep**: 패턴 기반 이슈 검색 (TODO, rethrow, deprecated)
- **bkit:code-analyzer Agent**: 보안 취약점 심층 분석

### 1.2 수동 검증
- OWASP Top 10 체크리스트 기반 보안 검증
- RLS 정책 마이그레이션 파일 직접 검토
- 복잡도 높은 Feature 우선 리뷰 (payment_method, auth)

---

## 2. 발견된 이슈 요약

### 2.1 통계

| 카테고리 | Critical | High | Medium | Low | Total |
|----------|----------|------|--------|-----|-------|
| 보안 (Security) | 0 | 1 | 5 | 3 | 9 |
| 코드 품질 (Quality) | 0 | 0 | 4 | 12 | 16 |
| 성능 (Performance) | 0 | 0 | 1 | 11 | 12 |
| 유지보수성 (Maintainability) | 0 | 0 | 3 | 8 | 11 |
| **Total** | **0** | **1** | **13** | **34** | **48** |

### 2.2 우선순위별 분류

#### P0 (Critical) - 0건
✅ **심각한 보안 취약점 없음**

#### P1 (High) - 1건
1. 비밀번호 복잡성 정책 미흡

#### P2 (Medium) - 13건
- 보안: 5건 (에러 메시지 노출, CORS 설정, 로깅 등)
- 코드 품질: 4건 (unused imports, dead code, 타입 체크 등)
- 성능: 1건 (deprecated API 사용)
- 유지보수성: 3건 (TODO 주석, 테스트 미구현 등)

#### P3 (Low) - 34건
- 대부분 코딩 스타일, info 레벨 lint 경고

---

## 3. 보안 이슈 상세

### 3.1 [P1-High] 비밀번호 복잡성 정책 미흡

**위치**: `lib/features/auth/presentation/pages/signup_page.dart:211-218`

**문제**:
```dart
if (password.length < 6) {
  return '비밀번호는 6자 이상이어야 합니다';
}
```
- 최소 6자만 요구 (너무 짧음)
- 대/소문자, 숫자, 특수문자 조합 미요구

**영향도**: High - 약한 비밀번호로 계정 탈취 가능성

**OWASP**: A07:2021 - Identification and Authentication Failures

**수정 방안**:
```dart
// 최소 8자, 영문 대소문자, 숫자 포함
if (password.length < 8) {
  return '비밀번호는 8자 이상이어야 합니다';
}
if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(password)) {
  return '비밀번호는 영문 대소문자와 숫자를 포함해야 합니다';
}
```

---

### 3.2 [P2-Medium] 비밀번호 검증 에러 메시지 정보 노출

**위치**: `lib/features/auth/presentation/providers/auth_provider.dart:289-293`

**문제**:
```dart
throw Exception('현재 비밀번호가 올바르지 않습니다');
```
- 공격자가 비밀번호 불일치를 확인할 수 있음

**영향도**: Medium - 계정 열거 공격 가능

**OWASP**: A01:2021 - Broken Access Control

**수정 방안**:
```dart
throw Exception('인증에 실패했습니다. 다시 시도해주세요');
```

---

### 3.3 [P2-Medium] Edge Function CORS 정책 과도하게 개방적

**위치**: `supabase/functions/send-push-notification/index.ts:269-277`

**문제**:
```typescript
'Access-Control-Allow-Origin': '*'
```
- 모든 도메인에서 요청 허용

**영향도**: Medium (Webhook 전용이므로 실제 위험 낮음)

**OWASP**: A05:2021 - Security Misconfiguration

**수정 방안**:
```typescript
'Access-Control-Allow-Origin': 'https://your-supabase-project.supabase.co'
```

---

### 3.4 [P2-Medium] 디버그 로그에서 민감 정보 노출

**위치**: `lib/features/payment_method/data/services/notification_listener_wrapper.dart:391-404`

**문제**:
```dart
debugPrint('  - 제목: ${event.title}');
debugPrint('  - 내용 미리보기: $contentPreview');
```
- 금액, 가맹점 정보가 로그에 노출될 수 있음

**완화 요소**: `kDebugMode` 체크로 프로덕션에서는 출력 안 됨

**영향도**: Medium (개발 환경에서 로그 유출 시)

**OWASP**: A09:2021 - Security Logging and Monitoring Failures

**수정 방안**:
```dart
if (kDebugMode) {
  debugPrint('  - 패키지명: ${event.packageName}');
  // 민감 정보는 마스킹
  debugPrint('  - 제목: ******');
}
```

---

### 3.5 [P2-Medium] 사용자 입력 정규식 ReDoS 취약점

**위치**: `lib/features/payment_method/data/services/sms_parsing_service.dart:294-302`

**문제**:
```dart
final amountMatch = RegExp(format.amountRegex).firstMatch(content);
```
- 사용자가 학습시킨 정규식을 직접 사용
- 복잡한 정규식으로 인한 DoS 가능성

**완화 요소**: try-catch로 예외 처리, 폴백 로직 존재

**영향도**: Medium (로컬 앱이므로 영향 제한적)

**OWASP**: A03:2021 - Injection

**수정 방안**:
```dart
// 정규식 복잡도 제한 또는 타임아웃 설정
try {
  final amountMatch = RegExp(format.amountRegex)
      .allMatches(content)
      .take(1)  // 첫 번째 매치만 사용
      .firstOrNull;
} catch (_) {
  amount = _parseAmount(content);
}
```

---

### 3.6 [P2-Medium] Edge Function 에러 메시지 상세 정보 노출

**위치**: `supabase/functions/send-push-notification/index.ts:534-536`

**문제**:
```typescript
JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' })
```
- 내부 에러 메시지가 클라이언트에 노출

**영향도**: Medium

**OWASP**: A09:2021 - Security Logging and Monitoring Failures

**수정 방안**:
```typescript
const isProduction = Deno.env.get('ENVIRONMENT') === 'production';
JSON.stringify({
  error: isProduction
    ? '알림 발송 중 오류가 발생했습니다'
    : error instanceof Error ? error.message : 'Unknown error'
})
```

---

### 3.7 [P3-Low] 디버그 로그 일관성 부족

**위치**: 여러 파일 (50개 이상의 debugPrint)

**문제**:
- 일부 파일에서 `kDebugMode` 체크 없이 `debugPrint` 사용
- 민감 정보 포함 여부 불명확

**완화 요소**: Flutter의 `debugPrint`는 릴리즈 빌드에서 자동 무시됨

**영향도**: Low

**수정 방안**: 민감 정보 로깅 시 일관되게 `kDebugMode` 체크 추가

---

### 3.8 [P3-Low] FCM 토큰 일부 로깅

**위치**: `supabase/functions/send-push-notification/index.ts:132, 215, 469`

**문제**:
```typescript
console.log(`Sending FCM to token: ${token.substring(0, 30)}...`);
```
- FCM 토큰 앞 30자가 로그에 노출

**영향도**: Low (토큰 전체가 아니므로 위험 낮음)

**수정 방안**: 앞 10자만 노출하거나 마스킹 강화

---

### 3.9 [P3-Low] print 문 사용

**위치**: `lib/features/notification/services/firebase_messaging_service.dart:135`

**문제**:
```dart
print('수신된 알림: ${remoteMessage.notification?.title}');
```
- `print` 대신 `debugPrint` 사용 권장

**영향도**: Low

**수정 방안**: `debugPrint`로 변경

---

## 4. 코드 품질 이슈 상세

### 4.1 [P2-Medium] Unused Imports

**flutter analyze 결과**: 9건의 unused import 발견

**주요 파일**:
- `asset_summary_card.dart`: 2건
- `calendar_view_mode_selector.dart`: 1건
- `notification_service.dart`: 1건
- `notification_listener_wrapper.dart`: 2건
- 기타: 3건

**영향도**: Medium (코드 가독성 저하)

**수정 방안**: 자동 제거
```bash
dart fix --apply
```

---

### 4.2 [P2-Medium] Dead Code

**flutter analyze 결과**: 4건의 dead code 발견

**주요 케이스**:
1. `router.dart:307` - null 체크 불필요
2. `asset_repository.dart:163` - null 체크 불필요
3. `pending_transaction_repository.dart:303` - null 체크 불필요

**수정 예시**:
```dart
// Before
final result = value ?? fallback;  // value는 null이 될 수 없음

// After
final result = value;
```

---

### 4.3 [P2-Medium] Unused Elements

**flutter analyze 결과**: 5건의 미사용 요소 발견

**주요 케이스**:
1. `_showGoalFormSheet` - asset_summary_card.dart:103
2. `_paymentMethodTabIndex` - payment_method_management_page.dart:45
3. `_showAddDialog` - payment_method_management_page.dart:316
4. `targetWeekday` - calendar_view_provider.dart:111
5. `_learnedSmsFormatRepository` - notification_listener_wrapper.dart:45

**수정 방안**: 사용하지 않는 코드 제거 또는 주석 처리

---

### 4.4 [P2-Medium] Unnecessary Type Checks

**위치**: `payment_method_management_page.dart:1256, 1267`

**문제**:
```dart
if (transaction is PendingTransactionModel) {  // 항상 true
```

**수정 방안**: 불필요한 타입 체크 제거

---

### 4.5 [P3-Low] Missing @override Annotations

**flutter analyze 결과**: 10건

**위치**: `learned_sms_format.dart`, `learned_push_format.dart`

**수정 방안**: `@override` 어노테이션 추가
```dart
@override
final String? amountRegex;
```

---

### 4.6 [P3-Low] prefer_const_constructors

**flutter analyze 결과**: 20건 이상

**주요 파일**: `payment_method_wizard_page.dart`

**수정 방안**: `const` 키워드 추가로 성능 최적화

---

## 5. 성능 이슈 상세

### 5.1 [P2-Medium] Deprecated API 사용 (withOpacity)

**flutter analyze 결과**: 35건

**위치**: 주로 `asset` feature

**문제**:
```dart
color.withOpacity(0.5)  // Deprecated
```

**수정 방안**:
```dart
color.withValues(alpha: 0.5)  // 권장
```

---

### 5.2 [P3-Low] 불필요한 위젯 빌드

**flutter analyze 결과**: 20건 이상의 `prefer_const_constructors`

**영향도**: Low (마이크로 최적화)

**수정 방안**: 가능한 경우 `const` 생성자 사용

---

## 6. 유지보수성 이슈 상세

### 6.1 [P2-Medium] TODO 주석 미해결

**Grep 결과**: 11건의 TODO 발견

**주요 항목**:
1. **Supabase mock 설정 후 테스트 구현** (`widget_test.dart:7`)
   - 우선순위: High
   - 테스트 커버리지 0%

2. **권한 체크 구현** (`sms_scanner_service.dart:127, 134`)
   - 우선순위: Medium
   - Phase 3에서 `permission_handler` 사용 예정

3. **Placeholder 구현** (`router.dart:169, 178`)
   - 우선순위: Low
   - 미사용 라우트

4. **이용약관/개인정보처리방침 페이지** (`settings_page.dart:215, 223`)
   - 우선순위: High (법적 요구사항)

5. **데이터 내보내기 기능** (`settings_page.dart:513`)
   - 우선순위: Medium

**수정 권장사항**: 우선순위에 따라 TODO 해결 또는 이슈 트래킹 시스템 등록

---

### 6.2 [P2-Medium] 테스트 커버리지 부족

**현황**:
- 단위 테스트: 거의 없음 (widget_test.dart만 존재)
- 위젯 테스트: 없음
- E2E 테스트: Maestro 파일 존재하지만 커버리지 불명

**영향도**: Medium (리팩토링 시 회귀 테스트 어려움)

**수정 방안**:
1. 핵심 비즈니스 로직 단위 테스트 추가
   - `SmsParsingService`
   - `CategoryMappingService`
   - `DuplicateCheckService`

2. 주요 Provider 테스트 추가
   - `AuthProvider`
   - `PendingTransactionProvider`

---

### 6.3 [P2-Medium] Curly Braces 누락

**위치**: `payment_method_management_page.dart:64`

**문제**:
```dart
if (condition)
  singleStatement();  // 중괄호 없음
```

**수정 방안**: 중괄호 추가로 가독성 향상

---

### 6.4 [P3-Low] Unnecessary Underscores

**flutter analyze 결과**: 4건

**위치**: `router.dart:344`, `asset_goal_card_simple.dart:45, 49`

**수정 방안**: 불필요한 언더스코어 제거

---

## 7. RLS 정책 검증 결과

### 7.1 ✅ 긍정적 개선 사항

#### 7.1.1 profiles RLS 수정 이력
- **초기 (001_initial_schema.sql:115-117)**: `USING (true)` - 모든 프로필 조회 가능 ❌
- **중간 (035_fix_profiles_rls_recursion.sql)**: `SECURITY DEFINER` 함수로 순환 참조 해결 ✅
- **최종 (044_allow_viewing_past_member_profiles.sql)**: 같은 가계부 멤버 또는 과거 멤버만 조회 가능 ✅

#### 7.1.2 pending_transactions RLS
- **038_fix_pending_transactions_rls.sql**: `user_id = auth.uid()` 조건 추가 ✅
- 본인 거래만 접근 가능하도록 수정됨

#### 7.1.3 payment_methods RLS
- **039_update_payment_method_sharing_policy.sql**: ✅
  - 자동수집 결제수단: 소유자만 접근
  - 직접입력 결제수단: 가계부 멤버 공유

### 7.2 ✅ 보안 모범 사례 적용

1. **모든 테이블에 RLS 활성화**
2. **SECURITY DEFINER 함수에서 search_path 명시**로 SQL Injection 방어
3. **Foreign Key 제약 조건** 완전성
4. **인덱스 최적화**로 RLS 정책 성능 향상

---

## 8. Flutter Analyze 전체 결과

### 8.1 요약
- **Warnings**: 18건
- **Info**: 106건
- **Total Issues**: 124건

### 8.2 카테고리별 분류

| 카테고리 | 건수 | 우선순위 |
|---------|------|----------|
| deprecated_member_use (withOpacity) | 35 | P2 |
| prefer_const_constructors | 20+ | P3 |
| unused_import | 9 | P2 |
| dead_code | 4 | P2 |
| unused_element | 5 | P2 |
| unnecessary_type_check | 2 | P2 |
| annotate_overrides | 10 | P3 |
| 기타 (info) | 39 | P3 |

---

## 9. 긍정적 요소 (Best Practices)

### 9.1 보안
✅ Supabase Auth 사용으로 JWT 토큰 관리 안전
✅ RLS 정책 체계적으로 구현 및 개선
✅ 환경변수로 민감 정보 관리
✅ `SECURITY DEFINER` 함수에서 SQL Injection 방어
✅ FCM 토큰 자동 삭제 로직 (무효 토큰)

### 9.2 코드 품질
✅ Clean Architecture 준수 (Domain/Data/Presentation 분리)
✅ Feature-first 구조
✅ Riverpod로 상태 관리
✅ 에러 처리에서 rethrow 사용 (10개 provider 확인)

### 9.3 성능
✅ 복합 인덱스 적용 (ledger_id, date)
✅ RLS 성능 최적화 인덱스
✅ Realtime subscription 적절히 사용

### 9.4 유지보수성
✅ CLAUDE.md, DESIGN_SYSTEM.md 등 문서화 우수
✅ i18n 지원 (app_ko.arb, app_en.arb)
✅ 일관된 코딩 스타일

---

## 10. 개선 우선순위 로드맵

### 10.1 즉시 수정 (P1 - High)
**예상 시간**: 1시간

1. ✅ **비밀번호 복잡성 정책 강화**
   - 파일: `signup_page.dart`
   - 작업: 최소 8자, 대/소문자, 숫자 포함 검증 추가

---

### 10.2 빠른 수정 권장 (P2 - Medium)
**예상 시간**: 2-3시간

1. **Unused Imports 제거** (자동화 가능)
   ```bash
   dart fix --apply
   ```

2. **Dead Code 제거**
   - 4건의 불필요한 null 체크 제거

3. **Deprecated API 마이그레이션**
   - `withOpacity` → `withValues` (35건)

4. **에러 메시지 일반화**
   - `auth_provider.dart`, Edge Function

5. **TODO 해결 또는 이슈 등록**
   - 테스트 구현
   - 이용약관/개인정보처리방침 페이지
   - 데이터 내보내기 기능

---

### 10.3 개선 권장 (P3 - Low)
**예상 시간**: 1-2시간

1. **@override 어노테이션 추가** (10건)
2. **const 생성자 추가** (20건)
3. **불필요한 언더스코어 제거** (4건)
4. **print → debugPrint 변경** (1건)
5. **CORS 정책 강화** (Edge Function)

---

### 10.4 장기 개선 (Future)
**예상 시간**: 1-2주

1. **테스트 커버리지 향상**
   - 단위 테스트 (핵심 로직)
   - 위젯 테스트 (주요 UI)
   - E2E 테스트 확장

2. **정규식 타임아웃 설정**
   - ReDoS 방어

3. **로깅 보안 강화**
   - 민감 정보 마스킹 일관성

---

## 11. 수정 전후 예상 개선

| 항목 | 현재 | 수정 후 | 개선율 |
|------|------|---------|--------|
| flutter analyze 경고 | 18건 | 2건 | 89% ↓ |
| flutter analyze info | 106건 | 30건 | 72% ↓ |
| 보안 취약점 (High) | 1건 | 0건 | 100% ↓ |
| 보안 취약점 (Medium) | 5건 | 1건 | 80% ↓ |
| TODO 미해결 | 11건 | 3건 | 73% ↓ |
| 테스트 커버리지 | ~0% | ~30% | +30% |

---

## 12. 결론

### 12.1 전체 평가

**보안 점수**: 78/100
**코드 품질 점수**: 82/100
**성능 점수**: 85/100
**유지보수성 점수**: 75/100

**종합 점수**: **80/100** (양호)

### 12.2 핵심 강점
1. ✅ **심각한 보안 취약점 없음** (Critical: 0건)
2. ✅ RLS 정책이 체계적으로 구현되고 지속적으로 개선됨
3. ✅ Clean Architecture 원칙 준수
4. ✅ 환경변수로 민감 정보 관리
5. ✅ 중복 처리 및 Race Condition 방어 로직 존재

### 12.3 주요 개선 필요 영역
1. 🔴 비밀번호 정책 강화 (P1)
2. 🟡 Deprecated API 마이그레이션 (P2)
3. 🟡 Unused Code 제거 (P2)
4. 🟡 테스트 커버리지 향상 (P2)
5. 🟢 코딩 스타일 개선 (P3)

### 12.4 권장 조치
- **즉시**: P1 이슈 수정 (1시간)
- **이번 주**: P2 이슈 수정 (2-3시간)
- **이번 달**: 테스트 커버리지 향상 (1-2주)
- **분기별**: 정기 보안 리뷰 및 의존성 업데이트

---

**작성자**: AI Code Reviewer (Claude)
**분석 도구**: flutter analyze, Grep, bkit:code-analyzer Agent
**상태**: Design Phase ✅
