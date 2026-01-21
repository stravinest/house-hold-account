#!/bin/bash

# ADB 기반 Push 알림 시뮬레이션 스크립트
# 사용법: ./scripts/simulate_push.sh "제목" "내용"

TITLE=${1:-"KB국민카드"}
CONTENT=${2:-"승인 홍*동 50,000원 일시불 스타벅스코리아 01/21 14:30 누적 1,250,000원"}

echo "------------------------------------------------"
echo "계좌/카드 자동 저장 테스트 (Push 시뮬레이션)"
echo "제목: $TITLE"
echo "내용: $CONTENT"
echo "------------------------------------------------"

# 에뮬레이터 확인
DEVICE_ID=$(adb devices | grep emulator | head -n 1 | cut -f1)

if [ -z "$DEVICE_ID" ]; then
    echo "에러: 실행 중인 에뮬레이터를 찾을 수 없습니다."
    exit 1
fi

echo "에뮬레이터($DEVICE_ID)로 Push 알림을 전송합니다..."

# cmd notification post [-t title] <tag> <text>
# -t 뒤에 제목을 넣고, 그 뒤에 tag(식별자)와 실제 내용(text)을 넣습니다.
# 패키지명은 shell에서 실행하므로 자동으로 com.android.shell이 됩니다.
adb -s $DEVICE_ID shell "cmd notification post -t '$TITLE' 'emulator_test_tag' '$CONTENT'"

echo "진행 완료. 에뮬레이터 상단의 알림을 확인하세요."
