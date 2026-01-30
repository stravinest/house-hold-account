#!/bin/bash

# ============================================================
# 자동수집 통합 로그 모니터링 스크립트
# SMS/Push 수신, 파싱, Supabase 저장 전 과정 모니터링
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

DEVICE_ID=""
FILTER_MODE="all"

usage() {
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}자동수집 통합 로그 모니터링${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo ""
    echo "사용법: $0 [옵션] [기기ID]"
    echo ""
    echo "옵션:"
    echo "  -a, --all       모든 자동수집 로그 (기본값)"
    echo "  -s, --sms       SMS 관련 로그만"
    echo "  -p, --push      Push 알림 관련 로그만"
    echo "  -d, --db        SQLite/Supabase 저장 관련 로그만"
    echo "  -e, --error     에러 로그만"
    echo "  -t, --test      테스트 채널 로그만"
    echo "  -h, --help      도움말"
    echo ""
    echo "예시:"
    echo "  $0                     # 기본 에뮬레이터, 모든 로그"
    echo "  $0 R3CT90TAG8Z         # 특정 기기"
    echo "  $0 -s                  # SMS 로그만"
    echo "  $0 -p R3CT90TAG8Z      # 특정 기기, Push 로그만"
    echo ""
}

find_device() {
    if [ -n "$DEVICE_ID" ]; then
        if adb -s "$DEVICE_ID" get-state >/dev/null 2>&1; then
            echo -e "${GREEN}기기 연결됨: $DEVICE_ID${NC}"
            return 0
        else
            echo -e "${RED}기기를 찾을 수 없습니다: $DEVICE_ID${NC}"
            return 1
        fi
    fi

    local emulator=$(adb devices | grep emulator | head -n 1 | cut -f1)
    if [ -n "$emulator" ]; then
        DEVICE_ID="$emulator"
        echo -e "${GREEN}에뮬레이터 연결됨: $DEVICE_ID${NC}"
        return 0
    fi

    local device=$(adb devices | grep -v "List" | grep "device$" | head -n 1 | cut -f1)
    if [ -n "$device" ]; then
        DEVICE_ID="$device"
        echo -e "${GREEN}실제 기기 연결됨: $DEVICE_ID${NC}"
        return 0
    fi

    echo -e "${RED}연결된 기기가 없습니다.${NC}"
    echo ""
    echo "연결된 기기 목록:"
    adb devices
    return 1
}

format_log() {
    local line="$1"
    
    if echo "$line" | grep -qE '\[TEST\]'; then
        echo -e "${MAGENTA}$line${NC}"
    elif echo "$line" | grep -qE 'FinancialSmsReceiver|SMS'; then
        if echo "$line" | grep -qiE 'error|fail|exception'; then
            echo -e "${RED}[SMS] $line${NC}"
        else
            echo -e "${CYAN}[SMS] $line${NC}"
        fi
    elif echo "$line" | grep -qE 'FinancialPushListener|Notification'; then
        if echo "$line" | grep -qiE 'error|fail|exception'; then
            echo -e "${RED}[PUSH] $line${NC}"
        else
            echo -e "${BLUE}[PUSH] $line${NC}"
        fi
    elif echo "$line" | grep -qE 'SupabaseHelper|Supabase|pending.*transaction'; then
        if echo "$line" | grep -qiE 'error|fail|exception'; then
            echo -e "${RED}[DB] $line${NC}"
        elif echo "$line" | grep -qiE 'success|created'; then
            echo -e "${GREEN}[DB] $line${NC}"
        else
            echo -e "${YELLOW}[DB] $line${NC}"
        fi
    elif echo "$line" | grep -qE 'NotificationStorage|SQLite'; then
        echo -e "${YELLOW}[SQLITE] $line${NC}"
    elif echo "$line" | grep -qE 'Parse|parsed|amount|merchant'; then
        echo -e "${WHITE}[PARSE] $line${NC}"
    elif echo "$line" | grep -qiE 'error|fail|exception'; then
        echo -e "${RED}[ERROR] $line${NC}"
    else
        echo "$line"
    fi
}

build_filter() {
    case $FILTER_MODE in
        sms)
            echo "FinancialSmsReceiver|SmsBroadcastReceiver"
            ;;
        push)
            echo "FinancialPushListener|NotificationListener"
            ;;
        db)
            echo "SupabaseHelper|NotificationStorage|SQLite|pending.*transaction|Supabase"
            ;;
        error)
            echo "error|fail|exception"
            ;;
        test)
            echo "\\[TEST\\]|MainActivity.*test|simulateSms|simulatePush"
            ;;
        all)
            echo "FinancialSmsReceiver|FinancialPushListener|SupabaseHelper|NotificationStorage|MainActivity|Parse|\\[TEST\\]"
            ;;
    esac
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            FILTER_MODE="all"
            shift
            ;;
        -s|--sms)
            FILTER_MODE="sms"
            shift
            ;;
        -p|--push)
            FILTER_MODE="push"
            shift
            ;;
        -d|--db)
            FILTER_MODE="db"
            shift
            ;;
        -e|--error)
            FILTER_MODE="error"
            shift
            ;;
        -t|--test)
            FILTER_MODE="test"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            DEVICE_ID="$1"
            shift
            ;;
    esac
done

if ! find_device; then
    exit 1
fi

FILTER=$(build_filter)

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}자동수집 로그 모니터링 시작${NC}"
echo -e "${CYAN}============================================================${NC}"
echo -e "기기: ${WHITE}$DEVICE_ID${NC}"
echo -e "필터: ${WHITE}$FILTER_MODE${NC}"
echo ""
echo -e "${YELLOW}색상 안내:${NC}"
echo -e "  ${CYAN}[SMS]${NC}    - SMS 수신/처리"
echo -e "  ${BLUE}[PUSH]${NC}   - Push 알림 수신/처리"
echo -e "  ${YELLOW}[SQLITE]${NC} - SQLite 저장"
echo -e "  ${GREEN}[DB]${NC}     - Supabase 저장 성공"
echo -e "  ${WHITE}[PARSE]${NC}  - 파싱 결과"
echo -e "  ${MAGENTA}[TEST]${NC}   - 테스트 채널"
echo -e "  ${RED}[ERROR]${NC}  - 에러"
echo ""
echo -e "중단하려면 ${WHITE}Ctrl+C${NC}를 누르세요."
echo -e "${CYAN}============================================================${NC}"
echo ""

adb -s "$DEVICE_ID" logcat -c

adb -s "$DEVICE_ID" logcat | grep --line-buffered -iE "$FILTER" | while IFS= read -r line; do
    format_log "$line"
done
