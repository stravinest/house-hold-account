#!/bin/bash
set -e

# 테스트 커버리지 검증 스크립트
# 계획된 32개 테스트 중 실행되지 않은 테스트를 확인

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAESTRO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTS_DIR="$MAESTRO_DIR/reports"

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 계획된 전체 테스트 ID 목록 (32개)
ALL_TESTS=(
    c01 c02 c03 c04 c05 c06 c07 c08
    h01 h02 h03 h04 h05 h06 h07 h08
    e01 e02 e03 e04 e05 e06 e07 e08 e09 e10 e11 e12
    l01 l02 l03 l04
)

TOTAL=${#ALL_TESTS[@]}
EXECUTED=0
MISSING=()

echo -e "${GREEN}[CHECK]${NC} 테스트 커버리지 검증 (계획: ${TOTAL}개)"
echo ""

for test_id in "${ALL_TESTS[@]}"; do
    if [ -f "$REPORTS_DIR/${test_id}.json" ]; then
        EXECUTED=$((EXECUTED + 1))
    else
        MISSING+=("$test_id")
    fi
done

COVERAGE=$(python3 -c "print(f'{($EXECUTED/$TOTAL)*100:.1f}')")

echo "실행 완료: ${EXECUTED}/${TOTAL} (${COVERAGE}%)"

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}[WARN]${NC} 누락된 테스트 (${#MISSING[@]}개):"
    for m in "${MISSING[@]}"; do
        echo -e "  ${RED}-${NC} $m"
    done
else
    echo -e "${GREEN}[OK]${NC} 모든 테스트가 실행되었습니다"
fi

echo ""
echo -e "커버리지: ${COVERAGE}%"
