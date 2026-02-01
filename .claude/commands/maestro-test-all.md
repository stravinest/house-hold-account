---
description: Maestro 전체 테스트 실행 - UI 자동화 테스트
---

# Maestro Test All

Maestro를 사용하여 모든 UI 자동화 테스트를 실행합니다.

## 사전 준비

1. 테스트 에뮬레이터 실행
   - `Test_Share_1`: emulator-5554 (사용자 1)
   - `Test_Share_2`: emulator-5556 (사용자 2)

2. Supabase 테스트 계정 확인
   - user1@test.com / testpass123
   - user2@test.com / testpass123

3. 소프트 키보드 비활성화
   ```bash
   ./scripts/disable_soft_keyboard.sh
   ```

## 명령어

### 전체 자동 테스트 (권장)

```bash
bash maestro-tests/run_share_test.sh
```

### 개별 플로우 테스트

```bash
# 사용자 1 초대 플로우
maestro test maestro-tests/01_user1_invite.yaml

# 사용자 2 수락 플로우
maestro test maestro-tests/02_user2_accept.yaml
```

### 빠른 테스트

```bash
bash maestro-tests/quick_test.sh
```

## 테스트 실패 시 자동 수정

```bash
# Maestro Healer로 자동 수정
./scripts/heal-maestro.sh maestro-tests/01_user1_invite.yaml
```

## 또는 MCP 사용

Claude Code의 Maestro MCP를 통해 직접 테스트:

```
ToolSearch로 mcp__maestro__run_flow 로드 후 사용
```

## 디버깅

```bash
# 화면 구조 확인
maestro hierarchy

# 특정 디바이스 지정
ANDROID_SERIAL=emulator-5554 maestro test maestro-tests/01_user1_invite.yaml
```

## 예상 소요 시간

- 개별 플로우: 약 1-2분
- 전체 테스트: 약 5-10분
