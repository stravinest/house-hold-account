#!/bin/bash

# ADB 기반 SMS 시뮬레이션 스크립트
# 사용법: ./scripts/simulate_sms.sh "보내는번호" "메시지내용"

SENDER=${1:-"15881688"}
CONTENT=${2:-"[Web발신] KB국민카드 1*2*승인 홍*동 50,000원 일시불 스타벅스코리아 01/15 14:30"}

echo "------------------------------------------------"
echo "계좌/카드 자동 저장 테스트 (SMS 시뮬레이션)"
echo "발신자: $SENDER"
echo "내용: $CONTENT"
echo "------------------------------------------------"

# 에뮬레이터 포트 확인 (기본 5554)
EMULATOR_PORT=$(adb devices | grep emulator | head -n 1 | cut -f1 | cut -d'-' -f2)

if [ -z "$EMULATOR_PORT" ]; then
    echo "에러: 실행 중인 에뮬레이터를 찾을 수 없습니다."
    exit 1
fi

echo "에뮬레이터($EMULATOR_PORT)로 SMS를 전송합니다..."

# 에뮬레이터 인증 토큰 읽기
AUTH_TOKEN=$(cat ~/.emulator_console_auth_token)

# telnet 대신 nc(netcat)를 사용하고 인증 과정을 추가합니다.
if command -v nc >/dev/null 2>&1; then
    (
        echo "auth $AUTH_TOKEN"
        sleep 0.5
        # 메시지 내용에 공백이 포함될 수 있으므로 따옴표로 감싸서 보냅니다.
        echo "sms send $SENDER \"$CONTENT\""
        sleep 1
        echo "quit"
    ) | nc localhost $EMULATOR_PORT
elif command -v telnet >/dev/null 2>&1; then
    (
        echo "auth $AUTH_TOKEN"
        sleep 0.5
        # 메시지 내용에 공백이 포함될 수 있으므로 따옴표로 감싸서 보냅니다.
        echo "sms send $SENDER \"$CONTENT\""
        sleep 1
        echo "quit"
    ) | telnet localhost $EMULATOR_PORT
else
    echo "에러: 'telnet'이나 'nc' 명령어를 찾을 수 없습니다. 'brew install telnet'으로 설치를 권장합니다."
    exit 1
fi

echo "진행 완료. 에뮬레이터 상단의 알림 또는 메시지 앱을 확인하세요."
