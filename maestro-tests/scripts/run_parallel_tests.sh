#!/bin/bash
set -e

# 메인 오케스트레이터 - 4단계 병렬/순차 테스트 실행
# 에뮬레이터 2대를 사용하여 Maestro E2E 테스트를 효율적으로 실행

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
MAESTRO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTS_DIR="$MAESTRO_DIR/reports"

ADB="/Users/eungyu/Library/Android/sdk/platform-tools/adb"
EMULATOR="/Users/eungyu/Library/Android/sdk/emulator/emulator"
APP_PACKAGE="com.household.shared.shared_household_account"

AVD_1="Test_Share_1"
AVD_2="Test_Share_2"
PORT_1=5554
PORT_2=5556
DEVICE_1="emulator-$PORT_1"
DEVICE_2="emulator-$PORT_2"

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

cleanup() {
    log_info "에뮬레이터 종료 중..."
    $ADB -s $DEVICE_1 emu kill 2>/dev/null || true
    $ADB -s $DEVICE_2 emu kill 2>/dev/null || true
    log_success "정리 완료"
}

trap cleanup EXIT

# 리포트 디렉토리 초기화
rm -rf "$REPORTS_DIR"
mkdir -p "$REPORTS_DIR"

# 1. 에뮬레이터 시작
log_info "에뮬레이터 시작: $AVD_1 (port $PORT_1)"
$EMULATOR -avd "$AVD_1" -port $PORT_1 -no-snapshot-load -no-audio -no-window &

log_info "에뮬레이터 시작: $AVD_2 (port $PORT_2)"
$EMULATOR -avd "$AVD_2" -port $PORT_2 -no-snapshot-load -no-audio -no-window &

# 2. 부팅 대기
log_info "에뮬레이터 부팅 대기 중..."
for DEVICE in $DEVICE_1 $DEVICE_2; do
    TIMEOUT=120
    ELAPSED=0
    while [ "$($ADB -s $DEVICE shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
        if [ $ELAPSED -ge $TIMEOUT ]; then
            log_error "에뮬레이터 $DEVICE 부팅 시간 초과 (${TIMEOUT}초)"
            exit 1
        fi
        sleep 2
        ELAPSED=$((ELAPSED + 2))
    done
    log_success "에뮬레이터 $DEVICE 부팅 완료 (${ELAPSED}초)"
done

# 3. 앱 빌드
log_info "앱 빌드 중 (flutter build apk --debug)..."
cd "$PROJECT_DIR"
flutter build apk --debug
APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"

if [ ! -f "$APK_PATH" ]; then
    log_error "APK 파일을 찾을 수 없습니다: $APK_PATH"
    exit 1
fi
log_success "앱 빌드 완료"

# 4. 앱 설치
log_info "앱 설치 중..."
$ADB -s $DEVICE_1 install -r "$APK_PATH"
log_success "앱 설치 완료: $DEVICE_1"
$ADB -s $DEVICE_2 install -r "$APK_PATH"
log_success "앱 설치 완료: $DEVICE_2"

# 5. Phase 1 - 독립 테스트 (병렬)
log_info "========== Phase 1: 독립 테스트 (병렬) =========="
"$SCRIPT_DIR/run_phase_parallel.sh" \
    "phase1_independent" \
    "c01,c03,c05,h01,h03,h05,h07" \
    "c02,c04,c06,h02,h04,h06,h08"

# 6. Phase 2 - 공유 테스트 (순차)
log_info "========== Phase 2: 공유 테스트 (순차) =========="
"$SCRIPT_DIR/run_phase_sequential.sh" \
    "phase2_share" \
    "c07" \
    "c08"

# 7. Phase 3 - 엣지케이스 (병렬)
log_info "========== Phase 3: 엣지케이스 (병렬) =========="
"$SCRIPT_DIR/run_phase_parallel.sh" \
    "phase3_edge" \
    "e01,e03,e05,e07,e09,e11" \
    "e02,e04,e06,e08,e10,e12"

# 8. Phase 4 - UI/UX (병렬)
log_info "========== Phase 4: UI/UX (병렬) =========="
"$SCRIPT_DIR/run_phase_parallel.sh" \
    "phase4_uiux" \
    "l01,l03" \
    "l02,l04"

# 9. 리포트 생성
log_info "리포트 생성 중..."
"$SCRIPT_DIR/generate_report.sh"

# 10. 커버리지 확인
log_info "커버리지 확인 중..."
"$SCRIPT_DIR/verify_coverage.sh"

log_success "전체 테스트 완료! 리포트: $REPORTS_DIR/summary.md"
