#!/bin/bash

# 빠른 Maestro 테스트 스크립트 (현재 실행 중인 에뮬레이터 사용)

set -e

PROJECT_DIR="/Users/eungyu/Desktop/개인/project/house-hold-account"

echo "========================================="
echo "빠른 Maestro 테스트"
echo "========================================="
echo ""

cd "$PROJECT_DIR"

# 현재 연결된 디바이스 확인
DEVICE_COUNT=$(adb devices | grep -c "device$" || echo "0")

if [ "$DEVICE_COUNT" -eq "0" ]; then
  echo "에러: 연결된 디바이스가 없습니다."
  echo ""
  echo "다음 중 하나를 실행하세요:"
  echo "  1. 에뮬레이터 실행: flutter emulators --launch Test_Share_1"
  echo "  2. 전체 테스트 실행: bash maestro-tests/run_share_test.sh"
  exit 1
fi

DEVICE_ID=$(adb devices | grep "device$" | head -n1 | cut -f1)
echo "연결된 디바이스: $DEVICE_ID"
echo ""

# 앱이 설치되어 있는지 확인
if ! adb -s $DEVICE_ID shell pm list packages | grep -q "com.household.shared.shared_household_account"; then
  echo "앱이 설치되어 있지 않습니다. 설치 중..."
  flutter build apk --debug
  flutter install -d $DEVICE_ID
  echo "설치 완료"
  echo ""
fi

# 테스트 선택
echo "실행할 테스트를 선택하세요:"
echo "  1. 사용자 1 플로우 (초대 보내기)"
echo "  2. 사용자 2 플로우 (초대 수락)"
echo ""
read -p "선택 (1 또는 2): " choice

case $choice in
  1)
    echo ""
    echo "사용자 1 플로우 실행 중..."
    maestro test maestro-tests/01_user1_invite.yaml
    ;;
  2)
    echo ""
    echo "사용자 2 플로우 실행 중..."
    maestro test maestro-tests/02_user2_accept.yaml
    ;;
  *)
    echo "잘못된 선택입니다."
    exit 1
    ;;
esac

echo ""
echo "테스트 완료!"
echo ""
