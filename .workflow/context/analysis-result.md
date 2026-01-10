# 현황 분석 결과

## 수정 대상: 공유 가계부 멤버 수 제한 (최대 2명)

### 관련 파일

| 파일 | 역할 | 수정 필요 |
|------|------|----------|
| `lib/core/constants/app_constants.dart` | 앱 상수 정의 | O (상수 추가) |
| `lib/features/share/data/repositories/share_repository.dart` | 비즈니스 로직 | O (검증 로직 추가) |
| `lib/features/share/presentation/providers/share_provider.dart` | 상태 관리 | X |
| `lib/features/share/presentation/pages/share_management_page.dart` | UI | O (멤버 수 표시, 제한 안내) |
| `supabase/migrations/001_initial_schema.sql` | DB 스키마 | 선택 (DB 레벨 제약) |

### 현재 검증 항목 (createInvite)

1. 자기 자신에게 초대 방지
2. 가입된 사용자인지 확인
3. 이미 멤버인지 확인
4. 대기 중인 초대가 있는지 확인
5. **멤버 수 제한 - 없음** (추가 필요)

### 현재 UI/UX 상태

#### 강점
- 탭 기반 구조 (멤버/받은 초대/보낸 초대)
- 역할 표시 (소유자/관리자/멤버)
- 에러 메시지 자동 표시

#### 개선점
- 현재 멤버 수 표시 없음
- 멤버 제한 도달 시 안내 없음
- 초대 버튼 비활성화 처리 없음

### 식별된 엣지 케이스

| 번호 | 엣지 케이스 | 처리 방안 |
|------|------------|----------|
| 1 | 초대 생성 시 멤버가 이미 2명인 경우 | 에러 메시지 표시, 초대 생성 불가 |
| 2 | 초대 수락 시 동시에 여러 명이 수락 (동시성) | acceptInvite에서도 멤버 수 재확인 |
| 3 | 대기 중인 초대가 있는데 멤버가 가득 찬 경우 | 수락 시 에러 처리, 초대 자동 만료 고려 |
| 4 | 소유자 1명 + 멤버 1명 = 2명일 때 추가 초대 | 2명 제한이면 추가 초대 불가 |
| 5 | FAB 버튼 클릭 전 멤버 수 확인 | 사전 확인 후 안내 다이얼로그 표시 |

### 의존성

```
AppConstants.maxMembersPerLedger (새로 추가)
        ↓
ShareRepository.createInvite() (검증 추가)
ShareRepository.acceptInvite() (검증 추가)
        ↓
ShareNotifier (변경 불필요 - 에러 자동 전파)
        ↓
ShareManagementPage (멤버 수 표시 UI 추가)
```

### 수정 지점 요약

1. **AppConstants** (Line 10 이후)
   - `maxMembersPerLedger = 2` 상수 추가

2. **ShareRepository.createInvite()** (Line 89-90 사이)
   - 현재 멤버 수 확인 로직 추가
   - 2명 이상이면 Exception throw

3. **ShareRepository.acceptInvite()** (Line 155-157 사이)
   - 초대 수락 전 멤버 수 재확인
   - 동시성 문제 방지

4. **ShareManagementPage** (선택적)
   - 멤버 탭에 현재 인원 표시 (예: "멤버 2/2명")
   - FAB 버튼 클릭 시 제한 도달 안내
