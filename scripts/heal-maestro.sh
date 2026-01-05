#!/bin/bash
# Maestro 테스트 자동 복구 스크립트
# 실패한 테스트를 분석하고 healer agent를 호출합니다.
# 사용법: ./scripts/heal-maestro.sh [flow_file] [--max-attempts N]

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOWS_DIR="$PROJECT_ROOT/flows"
LOGS_DIR="$PROJECT_ROOT/.maestro/logs"
REPORTS_DIR="$PROJECT_ROOT/.maestro/reports"

MAX_ATTEMPTS=3
CURRENT_ATTEMPT=0

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_heal() {
    echo -e "${CYAN}[HEAL]${NC} $1"
}

# 최근 실패 로그 찾기
find_failed_logs() {
    find "$LOGS_DIR" -name "*.log" -type f -mmin -60 -exec grep -l "FAILED\|Error\|Exception" {} \; 2>/dev/null || true
}

# 실패 원인 분석
analyze_failure() {
    local log_file="$1"

    log_heal "Analyzing failure: $log_file"

    # 일반적인 실패 패턴 검출
    if grep -q "Unable to find element" "$log_file"; then
        echo "ELEMENT_NOT_FOUND"
    elif grep -q "Timeout\|exceeded" "$log_file"; then
        echo "TIMEOUT"
    elif grep -q "Assertion failed\|Expected.*but found" "$log_file"; then
        echo "ASSERTION_FAILED"
    elif grep -q "App crashed\|Exception\|Error" "$log_file"; then
        echo "APP_CRASH"
    else
        echo "UNKNOWN"
    fi
}

# 단일 flow 테스트 실행
test_flow() {
    local flow_file="$1"
    local flow_name=$(basename "$flow_file" .yaml)
    local log_file="$LOGS_DIR/${flow_name}_heal_$(date +%s).log"

    log_info "Testing: $flow_name"

    if maestro test "$flow_file" > "$log_file" 2>&1; then
        log_info "PASSED: $flow_name"
        return 0
    else
        log_error "FAILED: $flow_name"
        return 1
    fi
}

# Healer Agent 호출 (Claude 프롬프트 출력)
call_healer_agent() {
    local flow_file="$1"
    local failure_type="$2"
    local log_content="$3"

    log_heal "Calling maestro-healer-agent..."

    # Claude에게 전달할 프롬프트 생성
    cat << EOF

========== HEALER AGENT 호출 ==========

다음 실패한 Maestro 테스트를 수정해주세요:

실패한 flow 파일: $flow_file

실패 유형: $failure_type

실패 로그:
\`\`\`
$log_content
\`\`\`

수정 규칙:
1. selector 변경이 최우선
2. 필요시 waitForAnimationToEnd 추가
3. 테스트 목적 변경 금지
4. 어설션 제거 금지

Task(
  subagent_type: "maestro-healer-agent",
  prompt: "위 내용 참고하여 수정"
)

=========================================

EOF
}

# 자동 복구 시도
heal_flow() {
    local flow_file="$1"
    local max_attempts="$2"

    log_heal "Starting heal process for: $flow_file"
    log_heal "Max attempts: $max_attempts"

    CURRENT_ATTEMPT=0

    while [ $CURRENT_ATTEMPT -lt $max_attempts ]; do
        CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1))
        log_heal "Attempt $CURRENT_ATTEMPT of $max_attempts"

        # 테스트 실행
        local log_file="$LOGS_DIR/heal_attempt_${CURRENT_ATTEMPT}.log"

        if maestro test "$flow_file" > "$log_file" 2>&1; then
            log_info "Test passed after $CURRENT_ATTEMPT attempt(s)"
            return 0
        fi

        # 실패 분석
        local failure_type=$(analyze_failure "$log_file")
        local log_content=$(tail -50 "$log_file")

        # APP_CRASH는 flow 수정으로 해결 불가
        if [ "$failure_type" = "APP_CRASH" ]; then
            log_error "App crash detected. Cannot heal via flow modification."
            log_error "Please fix the app code first."
            return 1
        fi

        # Healer agent 호출 (Claude 프롬프트)
        call_healer_agent "$flow_file" "$failure_type" "$log_content"

        log_warn "Waiting for manual fix or Claude intervention..."
        log_warn "Press Enter after fix to retry, or Ctrl+C to abort"
        read -r
    done

    log_error "Max attempts ($max_attempts) reached. Manual review required."
    return 1
}

# 모든 실패 로그 처리
heal_all_failures() {
    local failed_logs=$(find_failed_logs)

    if [ -z "$failed_logs" ]; then
        log_info "No recent failures found."
        return 0
    fi

    log_heal "Found failed tests:"
    echo "$failed_logs"

    for log in $failed_logs; do
        # 로그에서 flow 파일 이름 추출
        local flow_name=$(basename "$log" .log | sed 's/_[0-9]*$//')
        local flow_file=$(find "$FLOWS_DIR" -name "${flow_name}.yaml" -type f | head -1)

        if [ -n "$flow_file" ]; then
            heal_flow "$flow_file" "$MAX_ATTEMPTS" || true
        else
            log_warn "Cannot find flow file for: $flow_name"
        fi
    done
}

# 메인 실행
main() {
    local flow_file="$1"
    shift || true

    # 인자 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            --max-attempts)
                MAX_ATTEMPTS="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    log_heal "Maestro Healer Started"
    log_heal "Max attempts: $MAX_ATTEMPTS"

    if [ -n "$flow_file" ] && [ -f "$flow_file" ]; then
        # 특정 flow 복구
        heal_flow "$flow_file" "$MAX_ATTEMPTS"
    else
        # 모든 실패 복구
        heal_all_failures
    fi
}

main "$@"
