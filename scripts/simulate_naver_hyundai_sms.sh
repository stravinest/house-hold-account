#!/bin/bash

# 네이버 현대카드 SMS 시뮬레이션 스크립트
# 사용법: ./scripts/simulate_naver_hyundai_sms.sh [금액] [가맹점]

AMOUNT=${1:-"10,600"}
MERCHANT=${2:-"네이버페이"}
DATE=$(date +"%m/%d %H:%M")

# 현대카드 발신번호
SENDER="15776200"

# SMS 내용 (실제 받은 문자 형식)
CONTENT="[Web발신]
네이버 현대카드 승인
제*현
${AMOUNT}원 일시불
${DATE}
${MERCHANT}
누적321,747원"

echo "------------------------------------------------"
echo "네이버 현대카드 SMS 시뮬레이션"
echo "발신자: $SENDER (현대카드)"
echo "금액: ${AMOUNT}원"
echo "가맹점: $MERCHANT"
echo "날짜: $DATE"
echo "------------------------------------------------"
echo ""
echo "전송할 SMS 내용:"
echo "$CONTENT"
echo "------------------------------------------------"

# 에뮬레이터 포트 (기본 5554)
EMULATOR_PORT="5554"

# 에뮬레이터 실행 확인
if ! adb devices | grep -q "emulator-$EMULATOR_PORT"; then
    echo "에러: emulator-$EMULATOR_PORT가 실행 중이지 않습니다."
    echo "실행 중인 에뮬레이터:"
    adb devices
    exit 1
fi

echo "에뮬레이터($EMULATOR_PORT)로 SMS를 전송합니다..."

# 에뮬레이터 인증 토큰 읽기
if [ ! -f ~/.emulator_console_auth_token ]; then
    echo "에러: 인증 토큰 파일을 찾을 수 없습니다."
    echo "~/.emulator_console_auth_token 파일이 필요합니다."
    exit 1
fi

AUTH_TOKEN=$(cat ~/.emulator_console_auth_token)

# nc(netcat) 사용하여 SMS 전송
if command -v nc >/dev/null 2>&1; then
    (
        echo "auth $AUTH_TOKEN"
        sleep 0.5
        echo "sms send $SENDER \"$CONTENT\""
        sleep 1
        echo "quit"
    ) | nc localhost $EMULATOR_PORT
elif command -v telnet >/dev/null 2>&1; then
    (
        echo "auth $AUTH_TOKEN"
        sleep 0.5
        echo "sms send $SENDER \"$CONTENT\""
        sleep 1
        echo "quit"
    ) | telnet localhost $EMULATOR_PORT
else
    echo "에러: 'telnet'이나 'nc' 명령어를 찾을 수 없습니다."
    echo "'brew install telnet' 또는 'brew install netcat'으로 설치하세요."
    exit 1
fi

echo ""
echo "✅ SMS 전송 완료!"
echo "📱 에뮬레이터 상단 알림 또는 메시지 앱을 확인하세요."
echo ""
echo "💡 디버깅 로그 확인:"
echo "   adb logcat | grep -E '(SMS|payment|pending)'"
