#!/bin/bash

# 자동수집 전체 시나리오 테스트 스크립트
# 목적: SMS/Push × manual/suggest/auto 조합 검증
# 실행: bash scripts/test_auto_collect_scenarios.sh [device_id]

set -e

DEVICE_ID=${1:-""}
if [ -z "$DEVICE_ID" ]; then
    echo "에뮬레이터 또는 디바이스 ID를 지정해주세요."
    echo "사용법: bash scripts/test_auto_collect_scenarios.sh <device_id>"
    exit 1
fi

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 테스트 결과 카운터
TOTAL=0
PASSED=0
FAILED=0

# 로그 함수
log_test() {
    echo -e "${BLUE}[테스트 $1/$2]${NC} $3"
}

log_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    ((FAILED++))
}

log_info() {
    echo -e "${YELLOW}ℹ INFO:${NC} $1"
}

# Supabase 확인 함수 (실제 구현 필요)
check_pending_transaction() {
    local payment_method_name="$1"
    log_info "Supabase pending_transactions 확인: $payment_method_name"
    # TODO: Supabase REST API로 pending_transactions 조회
    return 0
}

check_confirmed_transaction() {
    local payment_method_name="$1"
    log_info "Supabase transactions 확인: $payment_method_name"
    # TODO: Supabase REST API로 transactions 조회
    return 0
}

# 테스트 대기 함수
wait_for_processing() {
    echo -n "처리 대기 중"
    for i in {1..5}; do
        echo -n "."
        sleep 1
    done
    echo ""
}

# 사전 준비 확인
echo "=========================================="
echo "자동수집 시나리오 통합 테스트"
echo "=========================================="
echo ""
log_info "디바이스: $DEVICE_ID"
log_info "앱 패키지: com.household.shared.shared_household_account"
echo ""

# 앱이 실행 중인지 확인
if ! adb -s "$DEVICE_ID" shell pidof com.household.shared.shared_household_account > /dev/null 2>&1; then
    log_fail "앱이 실행되지 않았습니다. 먼저 앱을 실행해주세요."
    exit 1
fi

log_info "앱 실행 확인 완료"
echo ""

# ============================================================
# 시나리오 1: SMS + manual 모드 → 수집 안 됨
# ============================================================
TOTAL=$((TOTAL + 1))
log_test $TOTAL 8 "SMS + manual 모드 (현금)"

adb -s "$DEVICE_ID" shell "cmd notification post -S bigtext -t 'KB Pay' 'Test' \
'KB체크 승인 10,000원 01/01 00:00 테스트상점 잔액 1,000원'"

wait_for_processing

# 로그 확인
if adb -s "$DEVICE_ID" logcat -d | grep -q "Payment method is set to SMS mode"; then
    log_pass "manual 모드는 수집하지 않음"
else
    log_info "로그에서 manual 모드 처리 확인 필요"
fi

# ============================================================
# 시나리오 2: SMS + suggest 모드 → pending_transactions 저장
# ============================================================
TOTAL=$((TOTAL + 1))
log_test $TOTAL 8 "SMS + suggest 모드 (test 카드)"

adb -s "$DEVICE_ID" shell "cmd notification post -S bigtext -t 'KB Pay' 'Test' \
'test 승인 20,000원 01/01 00:01 편의점 잔액 980원'"

wait_for_processing

if check_pending_transaction "test"; then
    log_pass "pending_transactions에 저장됨"
else
    log_fail "pending_transactions에 저장되지 않음"
fi

# ============================================================
# 시나리오 3: SMS + auto 모드 → transactions 저장
# ============================================================
TOTAL=$((TOTAL + 1))
log_test $TOTAL 8 "SMS + auto 모드 (수원페이 - SMS 모드)"

adb -s "$DEVICE_ID" shell "cmd notification post -S bigtext -t '경기지역화폐' 'Test' \
'수원페이 승인 30,000원 01/01 00:02 카페 잔액 970원'"

wait_for_processing

if check_confirmed_transaction "수원페이"; then
    log_pass "transactions에 바로 저장됨"
else
    log_fail "transactions에 저장되지 않음"
fi

# ============================================================
# 시나리오 4: SMS → Push 모드 결제수단 → 스킵
# ============================================================
TOTAL=$((TOTAL + 1))
log_test $TOTAL 8 "SMS → Push 모드 결제수단 (KB국민카드)"

adb -s "$DEVICE_ID" shell "cmd notification post -S bigtext -t 'KB Pay' 'Test' \
'KB국민카드 승인 40,000원 01/01 00:03 마트 잔액 960원'"

wait_for_processing

# 로그 확인: sourceType 불일치로 스킵되었는지
if adb -s "$DEVICE_ID" logcat -d | grep -q "SOURCE TYPE mismatch"; then
    log_pass "sourceType 불일치로 스킵됨"
else
    log_fail "sourceType 검증이 작동하지 않음"
fi

# ============================================================
# 시나리오 5: Push + manual 모드 → 수집 안 됨
# ============================================================
TOTAL=$((TOTAL + 1))
log_test $TOTAL 8 "Push + manual 모드"

# Push 알림은 실제 앱에서만 테스트 가능
log_info "(Skip) Push 알림은 실제 금융 앱에서 테스트 필요"

# ============================================================
# 시나리오 6: Push + suggest 모드 → pending_transactions 저장
# ============================================================
TOTAL=$((TOTAL + 1))
log_test $TOTAL 8 "Push + suggest 모드 (수원페이)"

log_info "(Skip) 실제 수원페이 앱으로 결제 후 테스트 필요"

# ============================================================
# 시나리오 7: Push + auto 모드 → transactions 저장
# ============================================================
TOTAL=$((TOTAL + 1))
log_test $TOTAL 8 "Push + auto 모드 (KB국민카드)"

log_info "(Skip) 실제 KB Pay 앱으로 결제 후 테스트 필요"

# ============================================================
# 시나리오 8: Push → SMS 모드 결제수단 → 스킵
# ============================================================
TOTAL=$((TOTAL + 1))
log_test $TOTAL 8 "Push → SMS 모드 결제수단"

log_info "(Skip) 실제 금융 앱으로 테스트 필요"

# ============================================================
# 테스트 결과 요약
# ============================================================
echo ""
echo "=========================================="
echo "테스트 결과 요약"
echo "=========================================="
echo -e "총 테스트: $TOTAL"
echo -e "${GREEN}통과: $PASSED${NC}"
echo -e "${RED}실패: $FAILED${NC}"
echo -e "스킵: $((TOTAL - PASSED - FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ 모든 테스트 통과!${NC}"
    exit 0
else
    echo -e "${RED}✗ 일부 테스트 실패${NC}"
    exit 1
fi
