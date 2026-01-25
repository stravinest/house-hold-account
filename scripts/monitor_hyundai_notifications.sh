#!/bin/bash

# 현대카드 알림 실시간 모니터링 스크립트
# 사용법: ./scripts/monitor_hyundai_notifications.sh [기기ID]

DEVICE_ID="${1:-R3CT90TAG8Z}"

echo "=========================================="
echo "현대카드 알림 실시간 모니터링"
echo "기기: $DEVICE_ID"
echo "=========================================="
echo ""

# 기기 연결 확인
if ! adb -s "$DEVICE_ID" shell exit 2>/dev/null; then
    echo "❌ 기기 '$DEVICE_ID'를 찾을 수 없습니다."
    echo ""
    echo "연결된 기기 목록:"
    adb devices
    exit 1
fi

echo "✅ 기기 연결됨"
echo ""
echo "📱 모니터링 중... (Ctrl+C로 종료)"
echo "=========================================="
echo ""

# Flutter 앱 로그 필터링
# - NotificationListener: 알림 수신 로그
# - 패키지명, 제목, 내용 미리보기 출력
adb -s "$DEVICE_ID" logcat -v time | grep -E "NotificationListener|현대카드|hyundai" --color=always
