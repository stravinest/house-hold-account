#!/bin/bash

# 에뮬레이터에 한글 입력 설정 스크립트

EMULATOR_ID=$1

if [ -z "$EMULATOR_ID" ]; then
    echo "사용법: $0 <emulator-id>"
    echo "예시: $0 emulator-5554"
    exit 1
fi

ADB="/Users/eungyu/Library/Android/sdk/platform-tools/adb"

echo "=== 에뮬레이터 $EMULATOR_ID 한글 입력 설정 ==="

# 1. 물리적 키보드 사용 시 소프트 키보드 숨기기
echo "1. 소프트 키보드 비활성화..."
$ADB -s $EMULATOR_ID shell settings put secure show_ime_with_hard_keyboard 0

# 2. 한글 로케일 추가
echo "2. 한글 로케일 추가..."
$ADB -s $EMULATOR_ID shell "settings put system system_locales ko-KR,en-US"

# 3. 입력 방법 설정 열기
echo "3. 입력 방법 설정 열기..."
$ADB -s $EMULATOR_ID shell "am start -a android.settings.INPUT_METHOD_SETTINGS"

echo ""
echo "=========================================="
echo "수동 설정 방법 1: Gboard에 한글 추가"
echo "=========================================="
echo "1. 설정 화면에서 'Gboard' 또는 'Google Keyboard' 클릭"
echo "2. 'Languages' 또는 '언어' 탭 선택"
echo "3. 'Add keyboard' 또는 '키보드 추가' 클릭"
echo "4. 'Korean' 또는 '한국어' 검색"
echo "5. '한국어 - 2벌식' 또는 'Korean - 2 set' 선택"
echo ""
echo "=========================================="
echo "수동 설정 방법 2: 물리적 키보드 직접 사용"
echo "=========================================="
echo "1. 에뮬레이터에서 Settings 앱 열기"
echo "2. System > Languages & input > Physical keyboard"
echo "3. 'Show virtual keyboard' 끄기"
echo "4. 맥 시스템 한글 입력기 사용"
echo ""
echo "=========================================="
echo ""
echo "설정 완료 후:"
echo "- 텍스트 필드 클릭하면 물리적 키보드로 입력 가능"
echo "- 한글/영어 전환: Ctrl + Space (Mac: Caps Lock 또는 Command + Space)"
echo "=========================================="
