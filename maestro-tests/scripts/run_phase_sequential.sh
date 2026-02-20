#!/bin/bash
set +e

# 순차 Phase 실행 스크립트
# EMU#1에서 첫 번째 테스트 완료 후 EMU#2에서 두 번째 테스트 실행
# 공유 기능 테스트(초대 보내기 -> 수락) 등에 사용

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
EMU1_TEST="$2"
EMU2_TEST="$3"

if [ -z "$PHASE_NAME" ] || [ -z "$EMU1_TEST" ] || [ -z "$EMU2_TEST" ]; then
    echo -e "${RED}[ERROR]${NC} 사용법: $0 <phase_name> <emu1_test> <emu2_test>"
    echo "  예: $0 phase2_share c07 c08"
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

# 단일 테스트 실행 및 결과 기록
run_single_test() {
    local device="$1"
    local email="$2"
    local password="$3"
    local test_id="$4"
    local device_label="$5"

    local test_file
    test_file=$(find_test_file "$test_id")

    if [ -z "$test_file" ]; then
        echo -e "${YELLOW}[WARN]${NC} [$device_label] 테스트 파일 없음: $test_id"
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
        return 1
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

    [ "$status" = "pass" ]
}

# 순차 실행: EMU#1 먼저, 그 다음 EMU#2
echo -e "${GREEN}[SEQ]${NC} 순차 실행: $EMU1_TEST -> $EMU2_TEST"

run_single_test "$DEVICE_1" "$USER1_EMAIL" "$USER1_PASSWORD" "$EMU1_TEST" "EMU#1"
EMU1_RESULT=$?

if [ $EMU1_RESULT -ne 0 ]; then
    echo -e "${YELLOW}[WARN]${NC} EMU#1 테스트($EMU1_TEST) 실패 - EMU#2 테스트($EMU2_TEST) 계속 실행"
fi

run_single_test "$DEVICE_2" "$USER2_EMAIL" "$USER2_PASSWORD" "$EMU2_TEST" "EMU#2"

echo -e "${GREEN}[DONE]${NC} $PHASE_NAME 완료"
