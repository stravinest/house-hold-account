#!/bin/bash
set +e

# 병렬 Phase 실행 스크립트
# 에뮬레이터 2대에서 각각의 테스트 목록을 동시에 순차 실행

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAESTRO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SUITES_DIR="$MAESTRO_DIR/suites"
REPORTS_DIR="$MAESTRO_DIR/reports"

DEVICE_1="emulator-5554"
DEVICE_2="emulator-5556"

USER1_EMAIL="user1@test.com"
USER1_PASSWORD="testpass123"
USER2_EMAIL="user2@test.com"
USER2_PASSWORD="testpass123"

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PHASE_NAME="$1"
EMU1_TESTS="$2"
EMU2_TESTS="$3"

if [ -z "$PHASE_NAME" ] || [ -z "$EMU1_TESTS" ] || [ -z "$EMU2_TESTS" ]; then
    echo -e "${RED}[ERROR]${NC} 사용법: $0 <phase_name> <emu1_tests> <emu2_tests>"
    echo "  예: $0 phase1 'c01,c03,c05' 'c02,c04,c06'"
    exit 1
fi

mkdir -p "$REPORTS_DIR"

# 테스트 ID로 YAML 파일 경로 찾기
find_test_file() {
    local test_id="$1"
    for dir in critical high medium low; do
        local file="$SUITES_DIR/$dir/${test_id}.yaml"
        if [ -f "$file" ]; then
            echo "$file"
            return 0
        fi
    done
    echo ""
    return 1
}

# 단일 에뮬레이터에서 테스트 목록을 순차 실행
run_tests_on_device() {
    local device="$1"
    local email="$2"
    local password="$3"
    local tests="$4"
    local device_label="$5"

    IFS=',' read -ra TEST_ARRAY <<< "$tests"
    for test_id in "${TEST_ARRAY[@]}"; do
        local test_file
        test_file=$(find_test_file "$test_id")

        if [ -z "$test_file" ]; then
            echo -e "${YELLOW}[WARN]${NC} [$device_label] 테스트 파일 없음: $test_id"
            # 실패로 기록
            cat > "$REPORTS_DIR/${test_id}.json" <<EOF
{
  "test_id": "$test_id",
  "phase": "$PHASE_NAME",
  "device": "$device",
  "status": "fail",
  "error": "테스트 파일을 찾을 수 없음",
  "duration_seconds": 0,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
            continue
        fi

        echo -e "${GREEN}[START]${NC} [$device_label] $test_id 실행 중..."
        local start_time
        start_time=$(date +%s)

        local status="pass"
        local error_msg=""
        if ! ANDROID_SERIAL="$device" maestro test \
            -e EMAIL="$email" \
            -e PASSWORD="$password" \
            "$test_file" 2>&1; then
            status="fail"
            error_msg="Maestro 테스트 실패. 스크린샷: ~/.maestro/tests/"
            echo -e "${RED}[FAIL]${NC} [$device_label] $test_id 실패"
        else
            echo -e "${GREEN}[PASS]${NC} [$device_label] $test_id 통과"
        fi

        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # 결과 JSON 기록
        cat > "$REPORTS_DIR/${test_id}.json" <<EOF
{
  "test_id": "$test_id",
  "phase": "$PHASE_NAME",
  "device": "$device",
  "status": "$status",
  "error": "$error_msg",
  "duration_seconds": $duration,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    done
}

# 에뮬레이터 2대에서 병렬 실행
run_tests_on_device "$DEVICE_1" "$USER1_EMAIL" "$USER1_PASSWORD" "$EMU1_TESTS" "EMU#1" &
PID_1=$!

run_tests_on_device "$DEVICE_2" "$USER2_EMAIL" "$USER2_PASSWORD" "$EMU2_TESTS" "EMU#2" &
PID_2=$!

# 두 프로세스 모두 완료 대기
FAIL=0
wait $PID_1 || FAIL=1
wait $PID_2 || FAIL=1

if [ $FAIL -ne 0 ]; then
    echo -e "${YELLOW}[WARN]${NC} $PHASE_NAME: 일부 테스트에서 실패가 발생했습니다"
fi

echo -e "${GREEN}[DONE]${NC} $PHASE_NAME 완료"
