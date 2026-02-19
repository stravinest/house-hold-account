#!/bin/bash
# deploy.sh - 앱 번들 빌드만 수행 (버전 등록은 별도)
#
# 사용법:
#   ./scripts/deploy.sh          # Android 앱번들 빌드
#   ./scripts/deploy.sh --apk    # APK로 빌드
#
# 배포 흐름:
#   1. ./scripts/deploy.sh                    → 앱번들 빌드
#   2. Google Play Console에 .aab 업로드      → 스토어 심사/출시
#   3. ./scripts/publish_version.sh           → 출시 확인 후 버전 등록

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# pubspec.yaml에서 버전 파싱
VERSION_LINE=$(grep '^version:' pubspec.yaml)
FULL_VERSION=$(echo "$VERSION_LINE" | sed 's/version: *//')
VERSION=$(echo "$FULL_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$FULL_VERSION" | cut -d'+' -f2)

echo "========================================="
echo "  앱 빌드"
echo "========================================="
echo "  버전: $VERSION (빌드 $BUILD_NUMBER)"
echo "========================================="
echo ""

# 인자 파싱
BUILD_TYPE="appbundle"

while [[ $# -gt 0 ]]; do
  case $1 in
    --apk)
      BUILD_TYPE="apk"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# 빌드
echo "[1/2] 앱 빌드 중... (flutter build $BUILD_TYPE)"
flutter build $BUILD_TYPE --release

if [ "$BUILD_TYPE" = "appbundle" ]; then
  echo ""
  echo "  빌드 완료: build/app/outputs/bundle/release/app-release.aab"
else
  echo ""
  echo "  빌드 완료: build/app/outputs/flutter-apk/app-release.apk"
fi

echo ""
echo "[2/2] 다음 단계"
echo ""
echo "  1. Google Play Console에 .aab 업로드 후 출시"
echo "  2. 스토어에 반영된 것을 확인한 후 아래 명령어 실행:"
echo ""
echo "     ./scripts/publish_version.sh"
echo ""
echo "  그러면 앱 사용자에게 업데이트 알림이 표시됩니다."
