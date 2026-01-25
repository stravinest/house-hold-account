#!/bin/bash

# 빠른 로그 모니터링 (R3CT90TAG8Z 전용)
DEVICE_ID='R3CT90TAG8Z'

echo '================================================'
echo '푸시 알림 로그 모니터링'
echo '================================================'
echo "기기: $DEVICE_ID"
echo ''
echo '지금 KB Pay나 경기지역화폐로 결제하세요!'
echo '알림이 오면 패키지명이 출력됩니다.'
echo ''
echo '중단: Ctrl+C'
echo '================================================'
echo ''

# 로그 초기화
adb -s "$DEVICE_ID" logcat -c

# 실시간 모니터링
adb -s "$DEVICE_ID" logcat | grep --line-buffered -E '\[NotificationListener\]|NotificationListener' | while read -r line; do
    if echo "$line" | grep -q '패키지명:'; then
        echo "🔍 $line"
    elif echo "$line" | grep -q 'packageName:'; then
        echo "🔍 $line"
    elif echo "$line" | grep -q '제목:'; then
        echo "📌 $line"
    elif echo "$line" | grep -q 'title:'; then
        echo "📌 $line"
    elif echo "$line" | grep -q '========'; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        echo "$line"
    fi
done
