#!/bin/bash

# 푸시 알림 패키지명 확인을 위한 전체 설정 가이드
# 사용법: ./scripts/setup_notification_monitoring.sh [기기ID]

DEVICE_ID=${1:-'R3CT90TAG8Z'}

echo '================================================'
echo '푸시 알림 패키지명 확인 설정 가이드'
echo '================================================'
echo "대상 기기: $DEVICE_ID"
echo ''

# 기기 연결 확인
if ! adb devices | grep -q "$DEVICE_ID"; then
    echo "❌ 에러: $DEVICE_ID 기기를 찾을 수 없습니다."
    echo ''
    echo '연결된 기기 목록:'
    adb devices -l
    echo ''
    echo '실물 핸드폰 연결 방법:'
    echo '1. 핸드폰 설정 -> 개발자 옵션 활성화'
    echo '2. USB 디버깅 활성화'
    echo '3. USB 케이블로 노트북에 연결'
    echo '4. 핸드폰에서 USB 디버깅 허용'
    exit 1
fi

echo "✅ 기기 연결 확인: $DEVICE_ID"
echo ''

# 1단계: 앱 설치 확인
echo '================================================'
echo '1단계: 앱 설치 확인'
echo '================================================'
APP_PACKAGE='com.household.shared.shared_household_account'

if adb -s "$DEVICE_ID" shell pm list packages | grep -q "$APP_PACKAGE"; then
    echo "✅ 앱이 설치되어 있습니다: $APP_PACKAGE"
else
    echo "❌ 앱이 설치되어 있지 않습니다."
    echo ''
    echo '앱 설치 방법:'
    echo '  flutter run -d $DEVICE_ID'
    exit 1
fi
echo ''

# 2단계: 금융 앱 검색
echo '================================================'
echo '2단계: 금융 앱 패키지 검색'
echo '================================================'
echo '설치된 금융 앱을 검색합니다...'
echo ''

./scripts/find_financial_packages.sh "$DEVICE_ID"

echo ''
echo '위 목록에서 KB Pay, 경기지역화폐 앱을 찾았나요?'
echo ''
read -p '계속하려면 Enter를 누르세요...'
echo ''

# 3단계: 알림 리스너 권한 확인
echo '================================================'
echo '3단계: 알림 리스너 권한 확인'
echo '================================================'
echo '앱에서 알림 액세스 권한을 허용해야 합니다.'
echo ''
echo '핸드폰에서 다음을 확인하세요:'
echo '  설정 -> 알림 -> 알림 액세스 -> [앱 이름] -> 허용'
echo ''
read -p '권한을 허용했으면 Enter를 누르세요...'
echo ''

# 4단계: 로그 모니터링 시작
echo '================================================'
echo '4단계: 실시간 로그 모니터링'
echo '================================================'
echo ''
echo '이제 다음 작업을 진행하세요:'
echo ''
echo '📱 핸드폰 작업:'
echo '  1. KB Pay 또는 경기지역화폐 앱 실행'
echo '  2. 소액 결제 진행 (1,000원 정도)'
echo '  3. 결제 완료 후 푸시 알림 확인'
echo ''
echo '💻 로그 모니터링:'
echo '  알림이 오면 아래에 패키지명이 출력됩니다.'
echo '  출력 예시:'
echo '    ========================================'
echo '    [NotificationListener] 알림 수신:'
echo '    - 패키지명: com.kbpay.android'
echo '    - 제목: KB Pay'
echo '    ========================================'
echo ''
echo '🔍 패키지명 확인 후:'
echo '  1. Ctrl+C로 모니터링 중단'
echo '  2. notification_listener_wrapper.dart 파일 수정'
echo '  3. _financialAppPackagesLower에 패키지명 추가'
echo '  4. 앱 재빌드: flutter run'
echo ''
echo '================================================'
echo '모니터링을 시작합니다. (중단: Ctrl+C)'
echo '================================================'
echo ''

sleep 2

# 로그 모니터링 실행
./scripts/monitor_notifications.sh "$DEVICE_ID"
