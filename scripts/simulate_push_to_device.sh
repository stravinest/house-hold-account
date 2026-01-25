#!/bin/bash

# UTF-8 로케일 설정
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8

# 실물 핸드폰에 푸시 알림 시뮬레이션 스크립트
# 사용법:
#   ./scripts/simulate_push_to_device.sh kbpay [금액] [가맹점] [기기ID]
#   ./scripts/simulate_push_to_device.sh suwonpay [금액] [가맹점] [기기ID]

APP_TYPE=${1:-'kbpay'}
AMOUNT=${2:-'65000'}
MERCHANT=${3:-'스타벅스'}
DEVICE_ID=${4:-'R3CT90TAG8Z'}  # 기본값: 사용자의 실물 핸드폰

echo '================================================'
echo '실물 핸드폰 푸시 알림 시뮬레이션'
echo '================================================'
echo "앱 타입: $APP_TYPE"
echo "금액: ${AMOUNT}원"
echo "가맹점: $MERCHANT"
echo "대상 기기: $DEVICE_ID"
echo '================================================'

# 연결된 기기 확인
echo '연결된 기기 목록:'
adb devices -l
echo ''

# 기기 연결 확인
if ! adb devices | grep -q "$DEVICE_ID"; then
    echo "에러: $DEVICE_ID 기기를 찾을 수 없습니다."
    echo ''
    echo '실물 핸드폰 연결 방법:'
    echo '1. 핸드폰 설정 -> 개발자 옵션 활성화'
    echo '2. USB 디버깅 활성화'
    echo '3. USB 케이블로 노트북에 연결'
    echo '4. 핸드폰에서 USB 디버깅 허용 팝업 승인'
    echo ''
    echo '기기 ID 확인: adb devices'
    exit 1
fi

# 금액 포맷팅
format_amount() {
    echo "$1" | sed ':a;s/\B[0-9]\{3\}\>$/,&/;ta'
}

FORMATTED_AMOUNT=$(format_amount "$AMOUNT")

# 현재 날짜/시간
DATE=$(date '+%m/%d')
TIME=$(date '+%H:%M')

case $APP_TYPE in
    kbpay)
        echo 'KB Pay 알림 전송 중...'
        CARD_LAST4='1004'
        USERNAME='전*규'
        ACCUMULATED=$((RANDOM % 1000000 + 500000))
        FORMATTED_ACCUMULATED=$(format_amount $ACCUMULATED)

        TITLE='KB Pay'
        CONTENT="KB Pay
KB국민카드${CARD_LAST4}승인
${USERNAME}님
${FORMATTED_AMOUNT}원 일시불
${DATE} ${TIME}
${MERCHANT}
누적${FORMATTED_ACCUMULATED}원"

        echo "제목: $TITLE"
        echo '내용:'
        echo "$CONTENT"
        echo '------------------------------------------------'

        adb -s "$DEVICE_ID" shell "cmd notification post -t '$TITLE' 'kbpay_test' '$CONTENT'"
        ;;

    suwonpay)
        echo '경기지역화폐 알림 전송 중...'
        BALANCE=$((RANDOM % 100000 + 10000))
        FORMATTED_BALANCE=$(format_amount $BALANCE)

        TITLE='경기지역화폐'
        CONTENT="결제 완료 ${FORMATTED_AMOUNT}원
${MERCHANT}
수원페이 충전형 인센티브 441원
수원페이(수원이) 총 보유 잔액 ${FORMATTED_BALANCE}원"

        echo "제목: $TITLE"
        echo '내용:'
        echo "$CONTENT"
        echo '------------------------------------------------'

        adb -s "$DEVICE_ID" shell "cmd notification post -t '$TITLE' 'suwonpay_test' '$CONTENT'"
        ;;

    *)
        echo "에러: 지원하지 않는 앱 타입입니다: $APP_TYPE"
        echo '사용법: $0 [kbpay|suwonpay] [금액] [가맹점] [기기ID]'
        echo ''
        echo '예시:'
        echo '  ./scripts/simulate_push_to_device.sh kbpay 65000 시크릿모'
        echo '  ./scripts/simulate_push_to_device.sh suwonpay 2650 파리바게뜨'
        echo '  ./scripts/simulate_push_to_device.sh kbpay 50000 스타벅스 R3CT90TAG8Z'
        exit 1
        ;;
esac

echo ''
echo '================================================'
echo '완료! 핸드폰에서 알림을 확인하세요.'
echo '================================================'
echo ''
echo '주의사항:'
echo '1. cmd notification post로 보낸 알림은 시스템 테스트 알림입니다.'
echo '2. 실제 앱 패키지명으로 전송되지 않아 NotificationListener가'
echo '   감지하지 못할 수 있습니다.'
echo ''
echo '실제 앱 알림 감지 확인 방법:'
echo '1. 실물 핸드폰에서 실제 KB Pay 또는 경기지역화폐 결제 진행'
echo '2. logcat으로 로그 확인:'
echo "   adb -s $DEVICE_ID logcat | grep NotificationListener"
echo ''
echo '실제 패키지명 확인:'
echo "   adb -s $DEVICE_ID shell pm list packages | grep -E 'kb|pay|ggc'"
