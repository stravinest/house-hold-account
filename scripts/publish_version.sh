#!/bin/bash
# publish_version.sh - pubspec.yaml 버전을 Supabase app_versions 테이블에 등록
#
# 사용법:
#   ./scripts/publish_version.sh                    # pubspec.yaml에서 버전 읽어서 등록
#   ./scripts/publish_version.sh --store-url "URL"  # 스토어 URL 포함
#   ./scripts/publish_version.sh --force            # 강제 업데이트로 등록
#   ./scripts/publish_version.sh --notes "내용"      # 릴리즈 노트 포함
#
# 필요 조건: .env 파일에 SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY 설정

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"
PUBSPEC_FILE="$PROJECT_DIR/pubspec.yaml"

# .env 파일 로드
if [ ! -f "$ENV_FILE" ]; then
  echo "오류: .env 파일을 찾을 수 없습니다: $ENV_FILE"
  exit 1
fi

source_env() {
  while IFS='=' read -r key value; do
    # 주석과 빈 줄 건너뛰기
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue
    # 따옴표 제거
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"
    export "$key=$value"
  done < "$ENV_FILE"
}

source_env

# Supabase 설정 확인
if [ -z "$SUPABASE_URL" ]; then
  echo "오류: SUPABASE_URL이 설정되지 않았습니다."
  exit 1
fi

# Service Role Key 또는 Anon Key 사용
API_KEY="${SUPABASE_SERVICE_ROLE_KEY:-$SUPABASE_ANON_KEY}"
if [ -z "$API_KEY" ]; then
  echo "오류: SUPABASE_SERVICE_ROLE_KEY 또는 SUPABASE_ANON_KEY가 필요합니다."
  exit 1
fi

# pubspec.yaml에서 버전 파싱
VERSION_LINE=$(grep '^version:' "$PUBSPEC_FILE")
FULL_VERSION=$(echo "$VERSION_LINE" | sed 's/version: *//')
VERSION=$(echo "$FULL_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$FULL_VERSION" | cut -d'+' -f2)

if [ -z "$VERSION" ] || [ -z "$BUILD_NUMBER" ]; then
  echo "오류: pubspec.yaml에서 버전을 파싱할 수 없습니다."
  echo "  형식: version: x.y.z+buildNumber"
  exit 1
fi

# 인자 파싱
STORE_URL="null"
IS_FORCE="false"
RELEASE_NOTES="null"
PLATFORM="android"

while [[ $# -gt 0 ]]; do
  case $1 in
    --store-url)
      STORE_URL="\"$2\""
      shift 2
      ;;
    --force)
      IS_FORCE="true"
      shift
      ;;
    --notes)
      RELEASE_NOTES="\"$2\""
      shift 2
      ;;
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --both)
      PLATFORM="both"
      shift
      ;;
    *)
      echo "알 수 없는 옵션: $1"
      exit 1
      ;;
  esac
done

echo "=== 앱 버전 등록 ==="
echo "  버전: $VERSION"
echo "  빌드: $BUILD_NUMBER"
echo "  플랫폼: $PLATFORM"
echo "  강제 업데이트: $IS_FORCE"
echo ""

# Supabase REST API로 INSERT
insert_version() {
  local platform=$1
  local payload="{\"platform\":\"$platform\",\"version\":\"$VERSION\",\"build_number\":$BUILD_NUMBER,\"is_force_update\":$IS_FORCE"

  if [ "$STORE_URL" != "null" ]; then
    payload="$payload,\"store_url\":${STORE_URL}"
  fi
  if [ "$RELEASE_NOTES" != "null" ]; then
    payload="$payload,\"release_notes\":${RELEASE_NOTES}"
  fi
  payload="$payload}"

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "${SUPABASE_URL}/rest/v1/app_versions" \
    -H "apikey: ${API_KEY}" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -H "Accept-Profile: house" \
    -H "Content-Profile: house" \
    -H "Prefer: return=minimal" \
    -d "$payload")

  if [ "$http_code" = "201" ]; then
    echo "  [$platform] 등록 완료"
  else
    echo "  [$platform] 등록 실패 (HTTP $http_code)"
    return 1
  fi
}

if [ "$PLATFORM" = "both" ]; then
  insert_version "android"
  insert_version "ios"
else
  insert_version "$PLATFORM"
fi

echo ""
echo "완료! 앱에서 업데이트 알림이 표시됩니다."
echo ""
echo "참고: 앱의 캐시(24시간)가 만료된 후 또는 강제 새로고침 시 반영됩니다."
