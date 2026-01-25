#!/bin/bash

# 금융 앱 패키지명을 찾고 자동으로 코드에 추가하는 가이드 스크립트
# 사용법: ./scripts/find_financial_packages.sh [기기ID]

DEVICE_ID=${1:-'R3CT90TAG8Z'}

echo '================================================'
echo '금융 앱 패키지명 자동 검색'
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

echo '1단계: 설치된 앱에서 금융 앱 패키지 검색 중...'
echo ''

# 결과 저장
TEMP_FILE="/tmp/financial_packages_$$.txt"
> "$TEMP_FILE"

echo '=== KB 관련 앱 ===' | tee -a "$TEMP_FILE"
adb -s "$DEVICE_ID" shell pm list packages | grep -i 'kb' | sed 's/package:/  /' | tee -a "$TEMP_FILE"
echo '' | tee -a "$TEMP_FILE"

echo '=== 페이/결제 관련 앱 ===' | tee -a "$TEMP_FILE"
adb -s "$DEVICE_ID" shell pm list packages | grep -E -i 'pay|payment' | sed 's/package:/  /' | tee -a "$TEMP_FILE"
echo '' | tee -a "$TEMP_FILE"

echo '=== 경기지역화폐 관련 앱 ===' | tee -a "$TEMP_FILE"
adb -s "$DEVICE_ID" shell pm list packages | grep -E -i 'ggc|gyeonggi|suwon|yongin|seongnam|currency|region' | sed 's/package:/  /' | tee -a "$TEMP_FILE"
echo '' | tee -a "$TEMP_FILE"

echo '=== 카드 관련 앱 ===' | tee -a "$TEMP_FILE"
adb -s "$DEVICE_ID" shell pm list packages | grep -i 'card' | sed 's/package:/  /' | tee -a "$TEMP_FILE"
echo '' | tee -a "$TEMP_FILE"

echo '=== 은행 관련 앱 ===' | tee -a "$TEMP_FILE"
adb -s "$DEVICE_ID" shell pm list packages | grep -E -i 'bank|shinhan|woori|hana|nh|ibk|kakao|toss' | sed 's/package:/  /' | tee -a "$TEMP_FILE"
echo '' | tee -a "$TEMP_FILE"

echo '================================================'
echo '2단계: 결과 저장 완료'
echo "파일 위치: $TEMP_FILE"
echo '================================================'
echo ''

echo '3단계: 실제 알림 패키지명 확인 방법'
echo ''
echo '다음 명령으로 실시간 모니터링하세요:'
echo "  ./scripts/monitor_notifications.sh $DEVICE_ID"
echo ''
echo '그 다음:'
echo '  1. KB Pay 또는 경기지역화폐로 소액 결제'
echo '  2. 알림이 오면 패키지명이 출력됩니다'
echo '  3. 출력된 패키지명을 아래 파일에 추가하세요:'
echo '     lib/features/payment_method/data/services/notification_listener_wrapper.dart'
echo ''
echo '예시:'
echo '  만약 패키지명이 "com.kbpay.android"로 출력되면,'
echo '  _financialAppPackagesLower에 다음을 추가:'
echo "  'com.kbpay.android',"
echo ''
echo '================================================'
echo '설치된 앱 목록 확인 완료!'
echo "위 목록에서 KB Pay와 경기지역화폐 앱을 찾아보세요."
echo '================================================'
