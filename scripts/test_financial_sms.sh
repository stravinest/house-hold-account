#!/bin/bash

# ============================================================
# 금융 SMS/Push 통합 테스트 스크립트
# 에뮬레이터에서 실제 BroadcastReceiver를 트리거하는 SMS 전송
# ============================================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 기본값
EMULATOR_PORT=""
AUTH_TOKEN=""

# 사용법 출력
usage() {
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}금융 SMS 테스트 스크립트 (에뮬레이터 전용)${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo ""
    echo "사용법: $0 [옵션] <템플릿>"
    echo ""
    echo "템플릿 목록:"
    echo "  kb          - KB국민카드 승인 SMS"
    echo "  shinhan     - 신한카드 승인 SMS"
    echo "  samsung     - 삼성카드 승인 SMS"
    echo "  hyundai     - 현대카드 승인 SMS"
    echo "  lotte       - 롯데카드 승인 SMS"
    echo "  woori       - 우리카드 승인 SMS"
    echo "  hana        - 하나카드 승인 SMS"
    echo "  kakao       - 카카오페이 결제 SMS"
    echo "  naver       - 네이버페이 결제 SMS"
    echo "  toss        - 토스 이체 SMS"
    echo "  income      - 입금 알림 SMS"
    echo "  custom      - 사용자 정의 SMS"
    echo "  all         - 모든 템플릿 순차 전송"
    echo ""
    echo "옵션:"
    echo "  -a, --amount <금액>     금액 설정 (기본: 랜덤)"
    echo "  -m, --merchant <상호>   가맹점명 설정 (기본: 랜덤)"
    echo "  -d, --delay <초>        all 모드에서 메시지 간 딜레이 (기본: 3)"
    echo "  -h, --help              도움말 출력"
    echo ""
    echo "예시:"
    echo "  $0 kb                           # KB국민카드 SMS 전송"
    echo "  $0 -a 50000 -m 스타벅스 kb      # 금액/가맹점 지정"
    echo "  $0 all                          # 모든 템플릿 테스트"
    echo "  $0 -d 5 all                     # 5초 간격으로 모든 템플릿"
    echo ""
}

# 에뮬레이터 연결 확인
check_emulator() {
    local device_count=$(adb devices | grep -v "List of devices" | grep -c "device$")
    
    if [ "$device_count" -eq 0 ]; then
        echo -e "${RED}에러: 실행 중인 에뮬레이터를 찾을 수 없습니다.${NC}"
        echo ""
        echo "에뮬레이터 시작 방법:"
        echo "  1. Android Studio -> AVD Manager -> 에뮬레이터 실행"
        echo "  2. 또는: emulator -avd <avd_name>"
        echo ""
        echo "연결된 기기 목록:"
        adb devices
        exit 1
    fi
    
    echo -e "${GREEN}에뮬레이터 연결됨${NC}"
}

# SMS 전송 함수
send_sms() {
    local sender="$1"
    local content="$2"
    local template_name="$3"
    
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo -e "${YELLOW}[$template_name] SMS 전송 중...${NC}"
    echo -e "  발신자: ${CYAN}$sender${NC}"
    echo -e "  내용:"
    echo "$content" | while IFS= read -r line; do
        echo -e "    ${line}"
    done
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    
    adb emu sms send "$sender" "$content" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}전송 완료!${NC}"
    else
        echo -e "${RED}전송 실패: adb emu sms send 명령 오류${NC}"
        exit 1
    fi
    echo ""
}

# 랜덤 값 생성
random_amount() {
    local amounts=(5000 10000 15000 25000 35000 50000 75000 100000 150000)
    echo "${amounts[$RANDOM % ${#amounts[@]}]}"
}

random_merchant() {
    local merchants=("스타벅스" "이마트" "쿠팡" "배달의민족" "GS25" "CU" "맥도날드" "버거킹" "올리브영" "다이소" "교보문고" "CGV" "롯데시네마")
    echo "${merchants[$RANDOM % ${#merchants[@]}]}"
}

format_amount() {
    printf "%'d" "$1" 2>/dev/null || echo "$1"
}

# 현재 날짜/시간
get_datetime() {
    date '+%m/%d %H:%M'
}

# ============================================================
# SMS 템플릿 정의
# ============================================================

send_kb() {
    local amount=${AMOUNT:-$(random_amount)}
    local merchant=${MERCHANT:-$(random_merchant)}
    local formatted=$(format_amount "$amount")
    local datetime=$(get_datetime)
    local card_last4=$((1000 + RANDOM % 9000))
    
    local content="[KB국민카드] ${card_last4} ${formatted}원 승인 홍*동 ${datetime} ${merchant}"
    
    send_sms "15881688" "$content" "KB국민카드"
}

send_shinhan() {
    local amount=${AMOUNT:-$(random_amount)}
    local merchant=${MERCHANT:-$(random_merchant)}
    local formatted=$(format_amount "$amount")
    local datetime=$(get_datetime)
    local card_last4=$((1000 + RANDOM % 9000))
    
    local content="[신한카드] ${card_last4} ${formatted}원 승인 홍*동님 ${datetime} ${merchant}"
    
    send_sms "15447200" "$content" "신한카드"
}

send_samsung() {
    local amount=${AMOUNT:-$(random_amount)}
    local merchant=${MERCHANT:-$(random_merchant)}
    local formatted=$(format_amount "$amount")
    local datetime=$(get_datetime)
    local card_last4=$((1000 + RANDOM % 9000))
    
    local content="[Web발신]
삼성카드${card_last4}
승인 ${formatted}원
일시불
${datetime}
${merchant}
홍*동님"
    
    send_sms "15887700" "$content" "삼성카드"
}

send_hyundai() {
    local amount=${AMOUNT:-$(random_amount)}
    local merchant=${MERCHANT:-$(random_merchant)}
    local formatted=$(format_amount "$amount")
    local datetime=$(get_datetime)
    local card_last4=$((1000 + RANDOM % 9000))
    
    local content="[Web발신]
현대카드 ${card_last4}
${formatted}원 승인
${datetime}
${merchant}
홍*동"
    
    send_sms "15776200" "$content" "현대카드"
}

send_lotte() {
    local amount=${AMOUNT:-$(random_amount)}
    local merchant=${MERCHANT:-$(random_merchant)}
    local formatted=$(format_amount "$amount")
    local datetime=$(get_datetime)
    local card_last4=$((1000 + RANDOM % 9000))
    
    local content="[Web발신]
롯데카드(${card_last4})승인
${formatted}원
일시불/${merchant}
${datetime}
홍*동님"
    
    send_sms "15889100" "$content" "롯데카드"
}

send_woori() {
    local amount=${AMOUNT:-$(random_amount)}
    local merchant=${MERCHANT:-$(random_merchant)}
    local formatted=$(format_amount "$amount")
    local datetime=$(get_datetime)
    local card_last4=$((1000 + RANDOM % 9000))
    
    local content="[Web발신]
우리카드${card_last4}
승인 ${formatted}원
${datetime}
${merchant}
홍*동님"
    
    send_sms "15889500" "$content" "우리카드"
}

send_hana() {
    local amount=${AMOUNT:-$(random_amount)}
    local merchant=${MERCHANT:-$(random_merchant)}
    local formatted=$(format_amount "$amount")
    local datetime=$(get_datetime)
    local card_last4=$((1000 + RANDOM % 9000))
    
    local content="[Web발신]
하나카드(${card_last4})
${formatted}원 승인
${datetime} ${merchant}
홍*동"
    
    send_sms "15881800" "$content" "하나카드"
}

send_kakao() {
    local amount=${AMOUNT:-$(random_amount)}
    local merchant=${MERCHANT:-$(random_merchant)}
    local formatted=$(format_amount "$amount")
    local datetime=$(get_datetime)
    
    local content="[카카오페이]
${formatted}원 결제완료
${datetime}
${merchant}
홍*동님"
    
    send_sms "15999508" "$content" "카카오페이"
}

send_naver() {
    local amount=${AMOUNT:-$(random_amount)}
    local merchant=${MERCHANT:-$(random_merchant)}
    local formatted=$(format_amount "$amount")
    local datetime=$(get_datetime)
    local card_last4=$((1000 + RANDOM % 9000))
    
    local content="[Web발신]
네이버 현대카드 승인
홍*동
${formatted}원 일시불
${datetime}
네이버페이
누적321,747원"
    
    send_sms "15776200" "$content" "네이버페이"
}

send_toss() {
    local amount=${AMOUNT:-$(random_amount)}
    local formatted=$(format_amount "$amount")
    local datetime=$(get_datetime)
    
    local content="[토스]
홍*동님께
${formatted}원 입금
${datetime}
잔액 1,234,567원"
    
    send_sms "15997700" "$content" "토스 입금"
}

send_income() {
    local amount=${AMOUNT:-$(random_amount)}
    local formatted=$(format_amount "$amount")
    local datetime=$(get_datetime)
    
    local content="[Web발신]
[KB국민] 입금
${formatted}원
${datetime}
홍*동
잔액 5,678,901원"
    
    send_sms "15881688" "$content" "입금 알림"
}

send_custom() {
    local sender=${CUSTOM_SENDER:-"15881688"}
    local content=${CUSTOM_CONTENT:-"[테스트] 커스텀 SMS 메시지입니다."}
    
    send_sms "$sender" "$content" "커스텀"
}

send_all() {
    local delay=${DELAY:-3}
    
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}모든 템플릿 순차 전송 (딜레이: ${delay}초)${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo ""
    
    send_kb
    sleep "$delay"
    
    send_shinhan
    sleep "$delay"
    
    send_samsung
    sleep "$delay"
    
    send_hyundai
    sleep "$delay"
    
    send_lotte
    sleep "$delay"
    
    send_woori
    sleep "$delay"
    
    send_hana
    sleep "$delay"
    
    send_kakao
    sleep "$delay"
    
    send_naver
    sleep "$delay"
    
    send_toss
    sleep "$delay"
    
    send_income
    
    echo ""
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN}모든 템플릿 전송 완료!${NC}"
    echo -e "${GREEN}============================================================${NC}"
}

# ============================================================
# 메인 로직
# ============================================================

# 옵션 파싱
AMOUNT=""
MERCHANT=""
DELAY=3
CUSTOM_SENDER=""
CUSTOM_CONTENT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--amount)
            AMOUNT="$2"
            shift 2
            ;;
        -m|--merchant)
            MERCHANT="$2"
            shift 2
            ;;
        -d|--delay)
            DELAY="$2"
            shift 2
            ;;
        -s|--sender)
            CUSTOM_SENDER="$2"
            shift 2
            ;;
        -c|--content)
            CUSTOM_CONTENT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            TEMPLATE="$1"
            shift
            ;;
    esac
done

if [ -z "$TEMPLATE" ]; then
    usage
    exit 1
fi

# 에뮬레이터 확인
check_emulator

echo ""

# 템플릿 실행
case $TEMPLATE in
    kb)         send_kb ;;
    shinhan)    send_shinhan ;;
    samsung)    send_samsung ;;
    hyundai)    send_hyundai ;;
    lotte)      send_lotte ;;
    woori)      send_woori ;;
    hana)       send_hana ;;
    kakao)      send_kakao ;;
    naver)      send_naver ;;
    toss)       send_toss ;;
    income)     send_income ;;
    custom)     send_custom ;;
    all)        send_all ;;
    *)
        echo -e "${RED}에러: 알 수 없는 템플릿: $TEMPLATE${NC}"
        echo ""
        usage
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}다음 단계:${NC}"
echo -e "  1. 에뮬레이터에서 앱 확인"
echo -e "  2. 로그 모니터링: ${YELLOW}./scripts/monitor_auto_collect.sh${NC}"
echo -e "  3. Supabase 확인: pending_transactions 테이블"
echo -e "${CYAN}============================================================${NC}"
