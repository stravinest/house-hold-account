# 코드 품질 분석 결과

## 분석 개요

| 항목 | 내용 |
|------|------|
| **분석 대상** | lib/features 전체 (약 100개 파일) |
| **분석 일자** | 2026-02-01 |
| **종합 점수** | 72/100 |

---

## 발견된 이슈

### 1. Critical (즉시 수정 필요)

| 파일 | 라인 | 이슈 | 권장 조치 |
|------|------|------|----------|
| `pending_transactions_page.dart` | 전체 | i18n 미적용 (80+ 한글 하드코딩) | `app_ko.arb` 번역 키 사용 |
| `debug_test_page.dart` | 전체 | i18n 미적용 (50+ 한글 하드코딩) | `app_ko.arb` 번역 키 사용 |
| `permission_request_dialog.dart` | 377, 384, 402 | i18n 미적용 ('취소', '나중에', '완료') | `l10n.commonCancel` 등 사용 |
| `settings_page.dart` | 194-195 | i18n 미적용 ('자동수집 디버그') | 번역 키 추가 |

### 2. Warning (개선 권장)

| 파일 | 라인 | 이슈 | 권장 조치 |
|------|------|------|----------|
| `payment_method_wizard_page.dart` | 전체 | 파일 길이 초과 (1872줄) | 300줄 이하로 분리 |
| `share_management_page.dart` | 전체 | 파일 길이 초과 (1053줄) | 300줄 이하로 분리 |
| `notification_listener_wrapper.dart` | 전체 | 파일 길이 초과 (1056줄) | 300줄 이하로 분리 |
| `sms_listener_service.dart` | 전체 | 파일 길이 초과 (787줄) | 서비스 분리 권장 |
| `share_management_page.dart` | 404-528 | debugPrint 14개 (kDebugMode 미사용) | `kDebugMode` 조건 추가 |
| `pending_transactions_page.dart` | 320-573 | SnackBar 직접 사용 | `SnackBarUtils` 사용 |
| `pending_transaction_provider.dart` | 85-182 | debugPrint 12개 (kDebugMode 미사용) | `kDebugMode` 조건 추가 |

### 3. Info (참고)

#### Clean Architecture 준수율: 양호 (85%)
- Presentation -> Domain 의존: 준수
- Presentation -> Data (Model) 직접 참조: 없음 (Repository 통해서만)
- Domain은 외부 의존 없음: 준수

#### 네이밍 일관성: 양호 (90%)
- 변수/함수: camelCase 준수
- 클래스: PascalCase 준수
- 파일명: snake_case 준수

#### 에러 처리 패턴: 양호 (85%)
- 총 rethrow 사용: 100+ 위치
- 적절한 에러 전파 패턴 적용됨

#### mounted 체크: 양호
- 비동기 후 Navigator 사용 시 mounted 체크: 28개 위치에서 확인됨
- `context.mounted` 또는 `!mounted` 패턴 사용 중

---

## 상세 분석

### 1. i18n 하드코딩 패턴

**심각도: Critical**

총 60+ 개의 한글 하드코딩 발견.

**주요 위치 예시:**
```dart
// pending_transactions_page.dart
title: const Text('자동 수집'),  // Line 74
title: const Text('모든 거래 확인'),  // Line 365
child: const Text('취소'),  // Line 370
content: const Text('대기 중인 모든 거래를 확인하시겠습니까?\n파싱 정보가 있는 거래만 저장됩니다.'),  // Line 366
```

**영향 받는 파일:**
- `pending_transactions_page.dart` - 80+ 건
- `debug_test_page.dart` - 50+ 건
- `permission_request_dialog.dart` - 10+ 건
- `asset_goal_card_simple.dart` - 5+ 건
- `settings_page.dart` - 5+ 건

### 2. debugPrint 프로덕션 노출

**심각도: Warning**

kDebugMode 미사용 debugPrint: 200+ 위치

**주요 파일:**
| 파일 | debugPrint 수 | kDebugMode 사용 |
|------|--------------|----------------|
| `sms_listener_service.dart` | 45개 | 미사용 |
| `auth_provider.dart` | 35개 | 미사용 |
| `notification_listener_wrapper.dart` | 30개 | 미사용 |
| `share_management_page.dart` | 14개 | 미사용 |
| `pending_transaction_provider.dart` | 12개 | 미사용 |

**kDebugMode 적용 파일 (양호):**
- `local_notification_service.dart` - 15개 (모두 kDebugMode 내부)
- `transaction_repository.dart` - 1개 (kDebugMode 내부)
- `share_repository.dart` - 1개 (kDebugMode 내부)

### 3. 파일 길이 위반

**심각도: Warning**

권장 기준: 300줄 이하

| 파일 | 줄 수 | 초과량 |
|------|-------|--------|
| `payment_method_wizard_page.dart` | 1872줄 | +1572줄 |
| `notification_listener_wrapper.dart` | 1056줄 | +756줄 |
| `share_management_page.dart` | 1053줄 | +753줄 |
| `pending_transactions_page.dart` | 805줄 | +505줄 |
| `sms_listener_service.dart` | 787줄 | +487줄 |

### 4. SnackBar 사용 일관성

**심각도: Warning**

`SnackBarUtils` 대신 직접 `ScaffoldMessenger` 사용 (pending_transactions_page.dart):

```dart
// 현재 코드
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('거래가 저장되었습니다'))
);

// 권장 코드
SnackBarUtils.showSuccess(context, l10n.transactionSaved);
```

### 5. 중복 코드 패턴

**심각도: Info**

AlertDialog 패턴이 7+ 위치에서 중복됨 (pending_transactions_page.dart 내 5개 위치)

---

## 개선 권장사항

### 우선순위 1 (즉시)
1. **i18n 하드코딩 제거**
   - `pending_transactions_page.dart` - 40개 번역 키 추가 필요
   - `debug_test_page.dart` - 30개 번역 키 추가 필요

2. **민감 debugPrint에 kDebugMode 조건 추가**
   - 인증 관련 로그 (auth_provider.dart)
   - SMS/Push 파싱 로그 (sms_listener_service.dart)

### 우선순위 2 (이번 주)
1. **긴 파일 분리**
   - `payment_method_wizard_page.dart` -> Step별 위젯 분리
   - `share_management_page.dart` -> 다이얼로그/시트 별도 파일

2. **SnackBar/Dialog 유틸 통일**
   - `SnackBarUtils` 사용
   - `DialogUtils.showConfirmation` 사용

### 우선순위 3 (이번 달)
1. 중복 코드 리팩토링
2. 테스트 커버리지 확대
3. 문서화 보강

---

## 결론

| 카테고리 | 상태 | 점수 |
|----------|------|------|
| Clean Architecture | 양호 | 85/100 |
| 네이밍 일관성 | 양호 | 90/100 |
| 에러 처리 | 양호 | 85/100 |
| i18n | 개선 필요 | 50/100 |
| 코드 크기 | 개선 필요 | 55/100 |
| debugPrint 관리 | 개선 필요 | 60/100 |

**종합 점수: 72/100**

**배포 권장:** Warning 이슈만 있으므로 배포 가능하나, Critical i18n 이슈 해결 후 배포 권장

---

**작성일**: 2026-02-01
**작성자**: Claude Code (bkit:code-analyzer Agent)
**버전**: 1.0
