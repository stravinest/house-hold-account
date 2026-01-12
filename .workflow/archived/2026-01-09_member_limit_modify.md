# Modify Todo: 공유 가계부 멤버 수 제한 (최대 2명)

## 메타 정보
- 생성일: 2026-01-09
- 현재 Phase: 6 (완료)
- 상태: 완료
- 리뷰 반복 횟수: 1

## 관련 문서
- 분석 결과: .workflow/context/analysis-result.md
- 요구사항: .workflow/modify-requirements.md
- 계획: ~/.claude/plans/quiet-prancing-tulip.md

---

## 작업 목록

### 1. 상수 정의
| 번호 | 작업 | 담당 | 상태 | 결과 |
|------|------|------|------|------|
| 1.1 | AppConstants에 maxMembersPerLedger 추가 | - | 완료 | Line 22에 추가 |

### 2. Repository 수정
| 번호 | 작업 | 담당 | 상태 | 결과 |
|------|------|------|------|------|
| 2.1 | 헬퍼 메서드 추가 | - | 완료 | getMemberCount, isMemberLimitReached 추가 |
| 2.2 | createInvite에 멤버 수 검증 추가 | - | 완료 | 5번째 검증 단계로 추가 |
| 2.3 | acceptInvite에 멤버 수 재확인 추가 | - | 완료 | 동시성 문제 방지 로직 추가 |

### 3. Provider 수정
| 번호 | 작업 | 담당 | 상태 | 결과 |
|------|------|------|------|------|
| 3.1 | currentLedgerMemberCountProvider 추가 | - | 완료 | Line 50-53 |
| 3.2 | canAddMemberProvider 추가 | - | 완료 | Line 56-59 |

### 4. UI 수정
| 번호 | 작업 | 담당 | 상태 | 결과 |
|------|------|------|------|------|
| 4.1 | TabBar에 멤버 수 표시 | - | 완료 | Consumer 사용, '멤버 (N/2)' 형식 |
| 4.2 | FAB 버튼 비활성화 | - | 완료 | SnackBar 피드백 포함 |
| 4.3 | 멤버 탭 정보 배너 추가 | - | 완료 | 멤버 수 + 최대 인원 경고 표시 |

### 5. 검증
| 번호 | 작업 | 담당 | 상태 | 결과 |
|------|------|------|------|------|
| 5.1 | 코드 리뷰 | code-reviewer | 완료 | FAB 접근성 개선 피드백 반영 |
| 5.2 | flutter analyze | - | 완료 | No issues (새 코드 기준) |

### 6. 추가 작업 (리뷰 피드백)
| 번호 | 작업 | 담당 | 상태 | 결과 |
|------|------|------|------|------|
| 6.1 | FAB 접근성 개선 | - | 완료 | SnackBar 피드백 추가 |
| 6.2 | DB 트리거 추가 | - | 완료 | 011_add_member_limit_trigger.sql |

---

## 변경된 파일

| 파일 | 변경 유형 | 주요 변경 내용 |
|------|----------|--------------|
| `lib/core/constants/app_constants.dart` | 수정 | maxMembersPerLedger = 2 |
| `lib/features/share/data/repositories/share_repository.dart` | 수정 | 헬퍼 메서드 + 검증 로직 |
| `lib/features/share/presentation/providers/share_provider.dart` | 수정 | 멤버 수 Provider 추가 |
| `lib/features/share/presentation/pages/share_management_page.dart` | 수정 | UI 표시 + FAB 비활성화 |
| `supabase/migrations/011_add_member_limit_trigger.sql` | 신규 | DB 트리거 + RLS 정책 |

---

## 변경 로그
- 2026-01-09 16:00: 초기 생성
- 2026-01-09 16:30: 구현 완료
- 2026-01-09 16:45: 코드 리뷰 완료, 피드백 반영
- 2026-01-09 17:00: 빌드 검증 완료
