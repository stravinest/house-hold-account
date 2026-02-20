#!/bin/bash
set -e

# 테스트 리포트 생성 스크립트
# reports/ 내 개별 결과 JSON을 수집하여 summary.md 생성

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAESTRO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTS_DIR="$MAESTRO_DIR/reports"
SUMMARY_FILE="$REPORTS_DIR/summary.md"

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ ! -d "$REPORTS_DIR" ] || [ -z "$(ls "$REPORTS_DIR"/*.json 2>/dev/null)" ]; then
    echo -e "${RED}[ERROR]${NC} 리포트 파일이 없습니다: $REPORTS_DIR"
    exit 1
fi

# 통계 수집
TOTAL=0
PASSED=0
FAILED=0
TOTAL_DURATION=0

# Phase별 결과 저장
declare -A PHASE_TOTAL
declare -A PHASE_PASSED
declare -A PHASE_FAILED

FAILED_TESTS=""

for json_file in "$REPORTS_DIR"/*.json; do
    test_id=$(python3 -c "import json; print(json.load(open('$json_file'))['test_id'])")
    status=$(python3 -c "import json; print(json.load(open('$json_file'))['status'])")
    phase=$(python3 -c "import json; print(json.load(open('$json_file'))['phase'])")
    duration=$(python3 -c "import json; print(json.load(open('$json_file'))['duration_seconds'])")
    error=$(python3 -c "import json; print(json.load(open('$json_file')).get('error', ''))")

    TOTAL=$((TOTAL + 1))
    TOTAL_DURATION=$((TOTAL_DURATION + duration))

    PHASE_TOTAL[$phase]=$(( ${PHASE_TOTAL[$phase]:-0} + 1 ))

    if [ "$status" = "pass" ]; then
        PASSED=$((PASSED + 1))
        PHASE_PASSED[$phase]=$(( ${PHASE_PASSED[$phase]:-0} + 1 ))
    else
        FAILED=$((FAILED + 1))
        PHASE_FAILED[$phase]=$(( ${PHASE_FAILED[$phase]:-0} + 1 ))
        FAILED_TESTS="$FAILED_TESTS\n| $test_id | $phase | ${duration}s | $error |"
    fi
done

if [ $TOTAL -gt 0 ]; then
    PASS_RATE=$(python3 -c "print(f'{($PASSED/$TOTAL)*100:.1f}')")
else
    PASS_RATE="0.0"
fi

# summary.md 생성
cat > "$SUMMARY_FILE" <<EOF
# Maestro E2E 테스트 리포트

- 실행 일시: $(date '+%Y-%m-%d %H:%M:%S')
- 총 소요 시간: ${TOTAL_DURATION}초

## 전체 통계

| 항목 | 값 |
|------|-----|
| 전체 | $TOTAL |
| 통과 | $PASSED |
| 실패 | $FAILED |
| 통과율 | ${PASS_RATE}% |

## Phase별 결과

| Phase | 전체 | 통과 | 실패 |
|-------|------|------|------|
EOF

for phase in $(echo "${!PHASE_TOTAL[@]}" | tr ' ' '\n' | sort); do
    p_total=${PHASE_TOTAL[$phase]:-0}
    p_passed=${PHASE_PASSED[$phase]:-0}
    p_failed=${PHASE_FAILED[$phase]:-0}
    echo "| $phase | $p_total | $p_passed | $p_failed |" >> "$SUMMARY_FILE"
done

if [ $FAILED -gt 0 ]; then
    cat >> "$SUMMARY_FILE" <<EOF

## 실패한 테스트

| 테스트 ID | Phase | 소요시간 | 에러 |
|-----------|-------|----------|------|
$(echo -e "$FAILED_TESTS")

> 스크린샷 경로: ~/.maestro/tests/ 에서 확인 가능
EOF
fi

echo -e "${GREEN}[OK]${NC} 리포트 생성 완료: $SUMMARY_FILE"
