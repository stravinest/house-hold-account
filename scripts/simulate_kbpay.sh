#!/bin/bash

# UTF-8 로케일 설정 (한글 인코딩 문제 방지)
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8

# KB Pay 푸시 알림 시뮬레이션 스크립트
# 사용법:
#   ./scripts/simulate_kbpay.sh [금액] [가맹점] [카드번호끝4자리]
#   ./scripts/simulate_kbpay.sh 65000 '시크릿모' 1004

AMOUNT=${1:-'65000'}
MERCHANT=${2:-'스타벅스'}
CARD_LAST4=${3:-'1004'}
EMULATOR_ID=${4:-'emulator-5554'}

# 금액 포맷팅 (천 단위 콤마)
format_amount() {
    echo "$1" | sed ':a;s/\B[0-9]\{3\}\>$/,&/;ta'
}

FORMATTED_AMOUNT=$(format_amount $AMOUNT)

# 누적 금액 (랜덤)
ACCUMULATED=$((RANDOM % 1000000 + 500000))
FORMATTED_ACCUMULATED=$(format_amount $ACCUMULATED)

# 현재 날짜/시간
DATE=$(date '+%m/%d')
TIME=$(date '+%H:%M')

# 사용자 이름 (마스킹)
USERNAME='전*규'

echo '================================================'
echo 'KB Pay 푸시 알림 시뮬레이션'
echo '================================================'
echo "금액: ${FORMATTED_AMOUNT}원"
echo "가맹점: $MERCHANT"
echo "카드 끝자리: $CARD_LAST4"
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

# Push 알림 전송 (실제 KB Pay 알림 형식)
send_push() {
    local TITLE='KB Pay'
    local CONTENT="KB Pay
KB국민카드${CARD_LAST4}승인
${USERNAME}님
${FORMATTED_AMOUNT}원 일시불
${DATE} ${TIME}
${MERCHANT}
누적${FORMATTED_ACCUMULATED}원"

    echo 'Push 알림 전송 중...'
    echo "제목: $TITLE"
    echo "내용:"
    echo "$CONTENT"
    echo '------------------------------------------------'

    # com.android.shell 패키지로 테스트 알림 전송
    # 실제 앱 패키지는 com.kbpay.* 형태일 것으로 추정
    adb -s $EMULATOR_ID shell "cmd notification post -t '$TITLE' 'kbpay_test' '$CONTENT'"

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
echo '주의: 실제 앱에서 알림이 감지되지 않는다면,'
echo '다음 사항을 확인하세요:'
echo '1. 알림 리스너 권한이 허용되어 있는지'
echo '2. KB Pay 앱의 실제 패키지명 확인 필요'
echo '   (adb shell pm list packages | grep kb)'
echo '3. notification_listener_wrapper.dart에'
echo '   KB Pay 패키지 추가 필요'
