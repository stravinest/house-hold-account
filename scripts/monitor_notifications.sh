#!/bin/bash

# 실시간 푸시 알림 패키지명 모니터링 스크립트
# 사용법: ./scripts/monitor_notifications.sh [기기ID]

DEVICE_ID=${1:-'R3CT90TAG8Z'}

echo '================================================'
echo '푸시 알림 패키지명 모니터링'
echo '================================================'
echo "대상 기기: $DEVICE_ID"
echo ''
echo '이제 핸드폰에서 KB Pay 또는 경기지역화폐로'
echo '결제를 진행하세요. 알림이 오면 패키지명이 출력됩니다.'
echo ''
echo '모니터링을 중단하려면 Ctrl+C를 누르세요.'
echo '================================================'
echo ''

# 기기 연결 확인
if ! adb devices | grep -q "$DEVICE_ID"; then
    echo "에러: $DEVICE_ID 기기를 찾을 수 없습니다."
    echo ''
    echo '연결된 기기 목록:'
    adb devices -l
    exit 1
fi

# 로그 초기화 및 실시간 모니터링
adb -s "$DEVICE_ID" logcat -c  # 기존 로그 지우기

echo '로그 모니터링 시작...'
echo ''

# NotificationListener 태그의 로그만 필터링
adb -s "$DEVICE_ID" logcat | grep --line-buffered -E '\[NotificationListener\]' | while read -r line; do
    # 색상 추가 (선택사항)
    if echo "$line" | grep -q '패키지명:'; then
        echo -e "\033[1;32m$line\033[0m"  # 녹색으로 강조
    elif echo "$line" | grep -q '제목:'; then
        echo -e "\033[1;34m$line\033[0m"  # 파란색으로 강조
    elif echo "$line" | grep -q '========'; then
        echo -e "\033[1;33m$line\033[0m"  # 노란색 구분선
    else
        echo "$line"
    fi
done
