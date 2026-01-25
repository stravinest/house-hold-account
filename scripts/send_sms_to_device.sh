#!/bin/bash

# 실제 기기에 SMS를 삽입하는 스크립트
# Usage: ./scripts/send_sms_to_device.sh [device_id]

DEVICE_ID="${1:-R3CT90TAG8Z}"
SENDER="15776200"
TIMESTAMP=$(date +%s)000

# SMS 내용 (네이버 현대카드)
SMS_BODY="[Web발신]
네이버 현대카드 승인
제*현
10,600원 일시불
01/25 20:44
네이버페이
누적321,747원"

echo "========================================="
echo "실제 기기에 SMS 전송"
echo "========================================="
echo "기기 ID: $DEVICE_ID"
echo "발신자: $SENDER"
echo "타임스탬프: $TIMESTAMP"
echo ""
echo "SMS 내용:"
echo "$SMS_BODY"
echo "========================================="

# 기기 연결 확인
if ! adb -s "$DEVICE_ID" get-state >/dev/null 2>&1; then
    echo "❌ 기기를 찾을 수 없습니다: $DEVICE_ID"
    echo ""
    echo "연결된 기기 목록:"
    adb devices
    exit 1
fi

echo "✅ 기기 연결 확인: $DEVICE_ID"
echo ""

# SMS 데이터베이스에 삽입
echo "📱 SMS 삽입 중..."
adb -s "$DEVICE_ID" shell "content insert --uri content://sms/inbox \
    --bind address:s:'$SENDER' \
    --bind body:s:'$SMS_BODY' \
    --bind date:i:$TIMESTAMP \
    --bind read:i:0"

if [ $? -eq 0 ]; then
    echo "✅ SMS가 성공적으로 삽입되었습니다!"
    echo ""
    echo "📋 다음 단계:"
    echo "1. 기기에서 메시지 앱을 열어 SMS 확인"
    echo "2. 앱의 로그를 확인하여 SmsListener가 작동하는지 확인:"
    echo "   adb -s $DEVICE_ID logcat -s flutter"
    echo ""
    echo "💡 TIP: SMS가 자동으로 감지되지 않으면 앱을 재시작하세요."
else
    echo "❌ SMS 삽입 실패"
    exit 1
fi
