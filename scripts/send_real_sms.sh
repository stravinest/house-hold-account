#!/bin/bash

# Twilio를 사용해 실제 SMS 전송
# 사용 전 아래 변수를 Twilio Console에서 확인하여 설정하세요

# Twilio 계정 정보 (필수 설정!)
TWILIO_ACCOUNT_SID="YOUR_ACCOUNT_SID"  # ACxxxxxxxxxxxxx 형태
TWILIO_AUTH_TOKEN="YOUR_AUTH_TOKEN"     # 32자리 토큰
TWILIO_PHONE_NUMBER="+1234567890"       # Twilio에서 받은 번호 (예: +12345678901)

# 수신자 번호 (테스트 기기의 전화번호)
TO_PHONE_NUMBER="+821012345678"  # 한국 번호는 +82로 시작 (010-1234-5678 → +821012345678)

# SMS 내용 (네이버 현대카드)
SMS_BODY="[Web발신]
네이버 현대카드 승인
제*현
10,600원 일시불
01/25 20:44
네이버페이
누적321,747원"

echo "========================================="
echo "Twilio를 통한 실제 SMS 전송"
echo "========================================="

# 설정 확인
if [ "$TWILIO_ACCOUNT_SID" = "YOUR_ACCOUNT_SID" ]; then
    echo "❌ 에러: Twilio 계정 정보를 설정하세요!"
    echo ""
    echo "1. Twilio Console 접속: https://console.twilio.com"
    echo "2. 다음 정보를 확인하여 스크립트 상단에 입력:"
    echo "   - TWILIO_ACCOUNT_SID"
    echo "   - TWILIO_AUTH_TOKEN"
    echo "   - TWILIO_PHONE_NUMBER (Get a Number 버튼으로 받기)"
    echo "3. TO_PHONE_NUMBER를 테스트 기기 번호로 변경"
    echo "   예: 010-1234-5678 → +821012345678"
    echo ""
    echo "💡 체험판은 인증된 번호로만 전송 가능합니다."
    echo "   Console → Phone Numbers → Verified Caller IDs에서 번호 인증 필요"
    exit 1
fi

echo "From: $TWILIO_PHONE_NUMBER"
echo "To: $TO_PHONE_NUMBER"
echo ""
echo "SMS 내용:"
echo "$SMS_BODY"
echo "========================================="
echo ""

# URL 인코딩 함수
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * ) printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}

# SMS 본문 인코딩
ENCODED_BODY=$(urlencode "$SMS_BODY")

echo "📤 SMS 전송 중..."

# Twilio API 호출
RESPONSE=$(curl -s -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json" \
    --data-urlencode "From=$TWILIO_PHONE_NUMBER" \
    --data-urlencode "To=$TO_PHONE_NUMBER" \
    --data-urlencode "Body=$SMS_BODY" \
    -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN")

# 응답 확인
if echo "$RESPONSE" | grep -q '"status"'; then
    STATUS=$(echo "$RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    SID=$(echo "$RESPONSE" | grep -o '"sid":"[^"]*"' | cut -d'"' -f4)

    echo "✅ SMS 전송 성공!"
    echo "   Status: $STATUS"
    echo "   Message SID: $SID"
    echo ""
    echo "📱 테스트 기기에서 SMS가 도착할 때까지 기다리세요 (보통 수초~수분)"
    echo ""
    echo "📋 앱 로그 확인:"
    echo "   adb -s R3CT90TAG8Z logcat -s flutter"
else
    echo "❌ SMS 전송 실패"
    echo ""
    echo "응답:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    echo ""
    echo "가능한 원인:"
    echo "1. Twilio 계정 정보가 잘못됨"
    echo "2. 수신 번호가 인증되지 않음 (체험판)"
    echo "3. 크레딧 부족"
    echo "4. 전화번호 형식 오류 (+82로 시작해야 함)"
fi
