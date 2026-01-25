#!/bin/bash

# UTF-8 로케일 설정 (한글 인코딩 문제 방지)
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8

# 수원페이(경기지역화폐) SMS/Push 알림 시뮬레이션 스크립트
# 사용법:
#   ./scripts/simulate_suwonpay.sh sms [금액] [가맹점]
#   ./scripts/simulate_suwonpay.sh push [금액] [가맹점]
#   ./scripts/simulate_suwonpay.sh both [금액] [가맹점]

TYPE=${1:-"both"}
AMOUNT=${2:-"15000"}
MERCHANT=${3:-"스타벅스 수원역점"}
BALANCE=$((RANDOM % 100000 + 10000))
EMULATOR_ID=${4:-"emulator-5554"}

# 금액 포맷팅 (천 단위 콤마)
format_amount() {
    echo "$1" | sed ':a;s/\B[0-9]\{3\}\>$/,&/;ta'
}

FORMATTED_AMOUNT=$(format_amount $AMOUNT)
FORMATTED_BALANCE=$(format_amount $BALANCE)

# 현재 날짜/시간
DATE=$(date "+%m/%d")
TIME=$(date "+%H:%M")

echo "================================================"
echo "수원페이(경기지역화폐) 알림 시뮬레이션"
echo "================================================"
echo "타입: $TYPE"
echo "금액: ${FORMATTED_AMOUNT}원"
echo "가맹점: $MERCHANT"
echo "잔액: ${FORMATTED_BALANCE}원"
echo "에뮬레이터: $EMULATOR_ID"
echo "------------------------------------------------"

# 에뮬레이터 확인
check_emulator() {
    if ! adb devices | grep -q "$EMULATOR_ID"; then
        echo "에러: $EMULATOR_ID 에뮬레이터를 찾을 수 없습니다."
        echo "실행 중인 에뮬레이터 목록:"
        adb devices
        exit 1
    fi
}

# SMS 전송
send_sms() {
    # 발신자는 전화번호 형식이어야 에뮬레이터가 인식함
    # 실제로는 내용(CONTENT)에 "[경기지역화폐]" 키워드가 있어 금융사로 매칭됨
    local SENDER="15881234"
    local CONTENT="[경기지역화폐] ${FORMATTED_AMOUNT}원 결제 (${MERCHANT}) 잔액: ${FORMATTED_BALANCE}원"

    echo "SMS 전송 중..."
    echo "발신자: $SENDER"
    echo "내용: $CONTENT"
    echo "------------------------------------------------"

    # 에뮬레이터 포트 추출 (emulator-5554 -> 5554)
    local EMULATOR_PORT=$(echo $EMULATOR_ID | cut -d'-' -f2)

    # 인증 토큰 읽기
    local AUTH_TOKEN=$(cat ~/.emulator_console_auth_token 2>/dev/null)

    if [ -z "$AUTH_TOKEN" ]; then
        echo "에러: 인증 토큰을 찾을 수 없습니다."
        echo "~/.emulator_console_auth_token 파일을 확인하세요."
        echo "에뮬레이터가 실행 중이어야 토큰 파일이 생성됩니다."
        return 1
    fi

    # nc를 사용하여 SMS 전송 (한 줄로 연결하여 전송)
    if command -v nc >/dev/null 2>&1; then
        {
            sleep 0.3
            echo "auth $AUTH_TOKEN"
            sleep 0.3
            echo "sms send $SENDER $CONTENT"
            sleep 0.5
            echo "quit"
        } | nc localhost $EMULATOR_PORT
    elif command -v telnet >/dev/null 2>&1; then
        {
            sleep 0.3
            echo "auth $AUTH_TOKEN"
            sleep 0.3
            echo "sms send $SENDER $CONTENT"
            sleep 0.5
            echo "quit"
        } | telnet localhost $EMULATOR_PORT
    else
        echo "에러: nc 또는 telnet 명령어가 필요합니다."
        return 1
    fi

    echo "SMS 전송 완료!"
}

# Push 알림 전송 (실제 경기지역화폐 알림 형식)
send_push() {
    local TITLE="경기지역화폐"
    local CONTENT="결제 완료 ${FORMATTED_AMOUNT}원
${MERCHANT}
수원페이 충전형 인센티브 441원
수원페이(수원이) 총 보유 잔액 ${FORMATTED_BALANCE}원"

    echo "Push 알림 전송 중..."
    echo "제목: $TITLE"
    echo "내용:"
    echo "$CONTENT"
    echo "------------------------------------------------"

    adb -s $EMULATOR_ID shell "cmd notification post -t '$TITLE' 'suwonpay_test' '$CONTENT'"

    echo "Push 알림 전송 완료!"
}

# 메인 실행
check_emulator

case $TYPE in
    sms)
        send_sms
        ;;
    push)
        send_push
        ;;
    both)
        send_sms
        echo ""
        echo "2초 후 Push 알림을 전송합니다..."
        sleep 2
        send_push
        ;;
    *)
        echo "사용법: $0 [sms|push|both] [금액] [가맹점] [에뮬레이터ID]"
        echo ""
        echo "예시:"
        echo "  $0 sms 25000 '이마트 수원점'"
        echo "  $0 push 12000 'CU 수원역점'"
        echo "  $0 both 50000 '홈플러스 수원점' emulator-5556"
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo "완료! 에뮬레이터에서 알림을 확인하세요."
echo "================================================"
