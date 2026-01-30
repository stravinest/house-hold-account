#!/bin/bash

# UTF-8 로케일 설정 (한글 인코딩 문제 방지)
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8

# 수원페이(경기지역화폐) Push 알림 시뮬레이션 스크립트
# 사용법:
#   ./scripts/simulate_suwonpay_push.sh [금액] [가맹점]
#   ./scripts/simulate_suwonpay_push.sh 15000 '스타벅스 수원역점'

AMOUNT=${1:-'15000'}
MERCHANT=${2:-'스타벅스 수원역점'}
EMULATOR_ID=${3:-'emulator-5554'}

# 금액 포맷팅 (천 단위 콤마)
format_amount() {
    echo "$1" | sed ':a;s/\B[0-9]\{3\}\>$/,&/;ta'
}

FORMATTED_AMOUNT=$(format_amount $AMOUNT)

# 잔액 (랜덤)
BALANCE=$((RANDOM % 100000 + 10000))
FORMATTED_BALANCE=$(format_amount $BALANCE)

# 인센티브 계산 (약 3%)
INCENTIVE=$((AMOUNT * 3 / 100))
FORMATTED_INCENTIVE=$(format_amount $INCENTIVE)

echo '================================================'
echo '수원페이(경기지역화폐) Push 알림 시뮬레이션'
echo '================================================'
echo "금액: ${FORMATTED_AMOUNT}원"
echo "가맹점: $MERCHANT"
echo "잔액: ${FORMATTED_BALANCE}원"
echo "인센티브: ${FORMATTED_INCENTIVE}원"
echo "에뮬레이터: $EMULATOR_ID"
echo '------------------------------------------------'

# 에뮬레이터 확인
check_emulator() {
    if ! adb devices | grep -q "$EMULATOR_ID"; then
        echo "에러: $EMULATOR_ID 에뮬레이터를 찾을 수 없습니다."
        echo '실행 중인 에뮬레이터 목록:'
        adb devices
        exit 1
    fi
}

# Push 알림 전송 (실제 경기지역화폐 알림 형식 - 개행 포함)
send_push() {
    local TITLE='경기지역화폐'
    
    # 개행을 포함한 실제 알림 형식
    # adb shell에서 개행을 처리하기 위해 $'...' 형식 사용
    local CONTENT=$'결제 완료 '"${FORMATTED_AMOUNT}"$'원\n'"${MERCHANT}"$'\n수원페이 충전형 인센티브 '"${FORMATTED_INCENTIVE}"$'원\n수원페이(수원이) 총 보유 잔액 '"${FORMATTED_BALANCE}"$'원'

    echo 'Push 알림 전송 중...'
    echo "제목: $TITLE"
    echo "내용:"
    echo "$CONTENT"
    echo '------------------------------------------------'

    # 방법 1: printf로 개행 처리
    adb -s $EMULATOR_ID shell "cmd notification post -t '$TITLE' 'gyeonggipay_test' \"$(printf '%s' "$CONTENT")\""

    echo ''
    echo 'Push 알림 전송 완료!'
}

# 메인 실행
check_emulator
send_push

echo ''
echo '================================================'
echo '완료! 에뮬레이터에서 알림을 확인하세요.'
echo '================================================'
echo ''
echo '로그 확인:'
echo "  adb logcat | grep -E '(FinancialPush|경기지역화폐|수원페이)'"
echo ''
echo 'DB 확인 (pending_transactions):'
echo '  Supabase Dashboard에서 pending_transactions 테이블 확인'
