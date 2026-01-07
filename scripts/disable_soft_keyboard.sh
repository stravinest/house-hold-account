#!/bin/bash

# 에뮬레이터에서 소프트 키보드 완전히 비활성화

EMULATOR_ID=$1

if [ -z "$EMULATOR_ID" ]; then
    echo "사용법: $0 <emulator-id>"
    echo "예시: $0 emulator-5554"
    exit 1
fi

ADB="/Users/eungyu/Library/Android/sdk/platform-tools/adb"

echo "=== 에뮬레이터 $EMULATOR_ID 소프트 키보드 비활성화 ==="

# 1. show_ime_with_hard_keyboard 설정
echo "1. 하드웨어 키보드 사용 시 IME 숨기기 설정..."
$ADB -s $EMULATOR_ID shell settings put secure show_ime_with_hard_keyboard 0

# 2. Physical keyboard 설정 화면 열기
echo "2. Physical keyboard 설정 화면 열기..."
$ADB -s $EMULATOR_ID shell "am start -a android.settings.HARD_KEYBOARD_SETTINGS"

echo ""
echo "=========================================="
echo "마지막 단계: 수동 설정 필요"
echo "=========================================="
echo ""
echo "에뮬레이터 화면에서:"
echo "  'Show virtual keyboard' 스위치를 OFF로 변경"
echo ""
echo "이 설정을 끄면 텍스트 필드를 클릭해도"
echo "소프트 키보드가 나타나지 않습니다."
echo ""
echo "=========================================="
