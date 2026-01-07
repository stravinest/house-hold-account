#!/bin/bash

# 공유 가계부 기능 Maestro 자동 테스트 스크립트

set -e  # 에러 발생 시 스크립트 중단

PROJECT_DIR="/Users/eungyu/Desktop/개인/project/house-hold-account"
EMULATOR_DIR="/Users/eungyu/Library/Android/sdk/emulator"
ADB="/Users/eungyu/Library/Android/sdk/platform-tools/adb"

echo "========================================="
echo "공유 가계부 Maestro 테스트 시작"
echo "========================================="
echo ""

# 프로젝트 디렉토리로 이동
cd "$PROJECT_DIR"

# Step 1: 현재 실행 중인 에뮬레이터 종료
echo "[1/8] 기존 에뮬레이터 종료 중..."
$ADB devices | grep emulator | cut -f1 | while read line; do
  $ADB -s $line emu kill 2>/dev/null || true
done
sleep 3
echo "완료"
echo ""

# Step 2: 첫 번째 에뮬레이터 실행
echo "[2/8] 첫 번째 에뮬레이터(Test_Share_1) 시작 중..."
$EMULATOR_DIR/emulator -avd Test_Share_1 -no-snapshot -no-audio &
EMULATOR_PID=$!

# 에뮬레이터 부팅 대기
echo "에뮬레이터 부팅 대기 중... (최대 120초)"
$ADB wait-for-device
timeout 120 bash -c 'until $ADB shell getprop sys.boot_completed 2>/dev/null | grep -q 1; do sleep 2; done' || {
  echo "에러: 에뮬레이터 부팅 시간 초과"
  kill $EMULATOR_PID 2>/dev/null || true
  exit 1
}
sleep 5
echo "완료"
echo ""

# Step 3: 앱 빌드 및 설치
echo "[3/8] 앱 빌드 및 설치 중..."
flutter build apk --debug
EMULATOR_ID=$($ADB devices | grep emulator | cut -f1 | head -n1)
flutter install -d $EMULATOR_ID
sleep 3
echo "완료"
echo ""

# Step 4: 사용자 1 플로우 실행
echo "[4/8] 사용자 1 플로우 실행 중 (초대 보내기)..."
maestro test maestro-tests/01_user1_invite.yaml || {
  echo "에러: 사용자 1 플로우 실패"
  kill $EMULATOR_PID 2>/dev/null || true
  exit 1
}
echo "완료"
echo ""

# Step 5: 첫 번째 에뮬레이터 종료
echo "[5/8] 첫 번째 에뮬레이터 종료 중..."
$ADB -s $EMULATOR_ID emu kill
kill $EMULATOR_PID 2>/dev/null || true
sleep 5
echo "완료"
echo ""

# Step 6: 두 번째 에뮬레이터 실행
echo "[6/8] 두 번째 에뮬레이터(Test_Share_2) 시작 중..."
$EMULATOR_DIR/emulator -avd Test_Share_2 -no-snapshot -no-audio &
EMULATOR_PID=$!

# 에뮬레이터 부팅 대기
echo "에뮬레이터 부팅 대기 중... (최대 120초)"
$ADB wait-for-device
timeout 120 bash -c 'until $ADB shell getprop sys.boot_completed 2>/dev/null | grep -q 1; do sleep 2; done' || {
  echo "에러: 에뮬레이터 부팅 시간 초과"
  kill $EMULATOR_PID 2>/dev/null || true
  exit 1
}
sleep 5
echo "완료"
echo ""

# Step 7: 앱 설치
echo "[7/8] 두 번째 에뮬레이터에 앱 설치 중..."
EMULATOR_ID=$($ADB devices | grep emulator | cut -f1 | head -n1)
flutter install -d $EMULATOR_ID
sleep 3
echo "완료"
echo ""

# Step 8: 사용자 2 플로우 실행
echo "[8/8] 사용자 2 플로우 실행 중 (초대 수락)..."
maestro test maestro-tests/02_user2_accept.yaml || {
  echo "에러: 사용자 2 플로우 실패"
  kill $EMULATOR_PID 2>/dev/null || true
  exit 1
}
echo "완료"
echo ""

# 에뮬레이터 종료
echo "테스트 완료. 에뮬레이터 종료 중..."
$ADB -s $EMULATOR_ID emu kill
kill $EMULATOR_PID 2>/dev/null || true

echo ""
echo "========================================="
echo "테스트 성공!"
echo "========================================="
echo ""
echo "스크린샷 확인:"
echo "  - maestro-tests/screenshots/user1_invite_sent.png"
echo "  - maestro-tests/screenshots/user2_invite_accepted.png"
echo ""
