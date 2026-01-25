#!/bin/bash

# 실물 핸드폰의 금융 앱 패키지명 확인 스크립트
# 사용법: ./scripts/check_device_packages.sh [기기ID]

DEVICE_ID=${1:-'R3CT90TAG8Z'}

echo '================================================'
echo '실물 핸드폰 금융 앱 패키지 확인'
echo '================================================'
echo "대상 기기: $DEVICE_ID"
echo ''

# 기기 연결 확인
if ! adb devices | grep -q "$DEVICE_ID"; then
    echo "에러: $DEVICE_ID 기기를 찾을 수 없습니다."
    echo ''
    echo '연결된 기기 목록:'
    adb devices -l
    exit 1
fi

echo 'KB 관련 앱:'
adb -s "$DEVICE_ID" shell pm list packages | grep -i 'kb'
echo ''

echo '카드 관련 앱:'
adb -s "$DEVICE_ID" shell pm list packages | grep -E 'card|pay'
echo ''

echo '경기지역화폐 관련 앱:'
adb -s "$DEVICE_ID" shell pm list packages | grep -E 'ggc|gyeonggi|suwon|currency'
echo ''

echo '은행 앱:'
adb -s "$DEVICE_ID" shell pm list packages | grep -E 'bank|shinhan|woori|hana'
echo ''

echo '================================================'
echo '위 목록에서 실제 사용 중인 앱을 찾아'
echo 'notification_listener_wrapper.dart의'
echo '_financialAppPackagesLower에 추가하세요.'
echo '================================================'
