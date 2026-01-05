#!/bin/bash
# Maestro 테스트 실행 스크립트
# 사용법: ./scripts/run-maestro.sh [그룹명] [--parallel]

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOWS_DIR="$PROJECT_ROOT/flows"
LOGS_DIR="$PROJECT_ROOT/.maestro/logs"
REPORTS_DIR="$PROJECT_ROOT/.maestro/reports"
SCREENSHOTS_DIR="$PROJECT_ROOT/.maestro/screenshots"

# 디렉토리 생성
mkdir -p "$LOGS_DIR" "$REPORTS_DIR" "$SCREENSHOTS_DIR"

# 타임스탬프
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 환경변수 로드
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
fi

# 결과 초기화
TOTAL=0
PASSED=0
FAILED=0
FAILED_TESTS=""

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 단일 flow 실행
run_flow() {
    local flow_file="$1"
    local flow_name=$(basename "$flow_file" .yaml)
    local log_file="$LOGS_DIR/${flow_name}_${TIMESTAMP}.log"

    log_info "Running: $flow_name"

    TOTAL=$((TOTAL + 1))

    if maestro test "$flow_file" --env TEST_EMAIL="${TEST_EMAIL:-test@example.com}" --env TEST_PASSWORD="${TEST_PASSWORD:-TestPassword123!}" > "$log_file" 2>&1; then
        log_info "PASSED: $flow_name"
        PASSED=$((PASSED + 1))
        return 0
    else
        log_error "FAILED: $flow_name"
        FAILED=$((FAILED + 1))
        FAILED_TESTS="$FAILED_TESTS $flow_name"
        return 1
    fi
}

# 디렉토리 내 모든 flow 실행
run_group() {
    local group_dir="$1"
    local parallel="$2"

    if [ ! -d "$group_dir" ]; then
        log_warn "Directory not found: $group_dir"
        return 0
    fi

    local flows=$(find "$group_dir" -name "*.yaml" -type f 2>/dev/null | grep -v "setup.yaml\|teardown.yaml" || true)

    if [ -z "$flows" ]; then
        log_warn "No flows found in: $group_dir"
        return 0
    fi

    if [ "$parallel" = "true" ]; then
        log_info "Running group in parallel: $(basename $group_dir)"
        local pids=""

        for flow in $flows; do
            run_flow "$flow" &
            pids="$pids $!"
        done

        # 모든 프로세스 대기
        for pid in $pids; do
            wait $pid || true
        done
    else
        log_info "Running group sequentially: $(basename $group_dir)"
        for flow in $flows; do
            run_flow "$flow" || true
        done
    fi
}

# 모든 그룹 실행 (그룹 파일 기반)
run_all_groups() {
    local groups_file="$1"

    if [ -f "$groups_file" ]; then
        log_info "Running groups from: $groups_file"
        # TODO: groups.yaml 파싱하여 실행
        # 현재는 디렉토리 기반으로 순차 실행
    fi

    # 기본 실행 순서
    # 1. auth (순차) - 인증은 항상 먼저
    run_group "$FLOWS_DIR/auth" "false"

    # 2. common은 건너뜀 (setup/teardown 용도)

    # 3. transaction, category, share (병렬 가능)
    run_group "$FLOWS_DIR/transaction" "false"
    run_group "$FLOWS_DIR/category" "true"
    run_group "$FLOWS_DIR/share" "false"
}

# 결과 보고서 생성
generate_report() {
    local report_file="$REPORTS_DIR/summary_${TIMESTAMP}.yaml"

    cat > "$report_file" << EOF
execution:
  date: $(date +"%Y-%m-%d %H:%M:%S")
  timestamp: $TIMESTAMP

results:
  total: $TOTAL
  passed: $PASSED
  failed: $FAILED
  success_rate: $(if [ $TOTAL -gt 0 ]; then echo "scale=2; $PASSED * 100 / $TOTAL" | bc; else echo "0"; fi)%

failed_tests:
$(for t in $FAILED_TESTS; do echo "  - $t"; done)

logs_dir: $LOGS_DIR
screenshots_dir: $SCREENSHOTS_DIR
EOF

    log_info "Report saved: $report_file"
}

# 메인 실행
main() {
    local group="$1"
    local parallel="$2"

    log_info "Maestro Test Runner Started"
    log_info "Timestamp: $TIMESTAMP"

    # Maestro 설치 확인
    if ! command -v maestro &> /dev/null; then
        log_error "Maestro is not installed. Please install: brew install maestro"
        exit 1
    fi

    if [ -n "$group" ] && [ "$group" != "--parallel" ]; then
        # 특정 그룹만 실행
        if [ "$parallel" = "--parallel" ]; then
            run_group "$FLOWS_DIR/$group" "true"
        else
            run_group "$FLOWS_DIR/$group" "false"
        fi
    else
        # 전체 실행
        run_all_groups
    fi

    # 결과 보고서 생성
    generate_report

    # 결과 출력
    echo ""
    log_info "========== RESULTS =========="
    log_info "Total: $TOTAL"
    log_info "Passed: $PASSED"
    log_info "Failed: $FAILED"

    if [ $FAILED -gt 0 ]; then
        log_error "Failed tests:$FAILED_TESTS"
        exit 1
    else
        log_info "All tests passed!"
        exit 0
    fi
}

main "$@"
