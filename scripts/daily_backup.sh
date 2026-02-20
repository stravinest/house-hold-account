#!/bin/bash
# Supabase DB 일일 백업 스크립트
# 사용법: ./scripts/daily_backup.sh
# cron으로 매일 자동 실행 권장

set -euo pipefail

# === 설정 ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

# .env에서 환경변수 로드
if [ ! -f "$ENV_FILE" ]; then
  echo "[ERROR] .env 파일을 찾을 수 없습니다: $ENV_FILE"
  exit 1
fi

SUPABASE_URL=$(grep '^SUPABASE_URL=' "$ENV_FILE" | cut -d'=' -f2-)
SUPABASE_ANON_KEY=$(grep '^SUPABASE_ANON_KEY=' "$ENV_FILE" | cut -d'=' -f2-)

# DB 접속 정보 (.env에 추가 필요)
DB_HOST=$(grep '^DB_HOST=' "$ENV_FILE" | cut -d'=' -f2-)
DB_PASSWORD=$(grep '^DB_PASSWORD=' "$ENV_FILE" | cut -d'=' -f2-)
DB_PORT=$(grep '^DB_PORT=' "$ENV_FILE" | cut -d'=' -f2- 2>/dev/null || echo "5432")

# Service Role Key (Storage 업로드용, .env에 추가 필요)
SUPABASE_SERVICE_KEY=$(grep '^SUPABASE_SERVICE_ROLE_KEY=' "$ENV_FILE" | cut -d'=' -f2-)

if [ -z "$DB_HOST" ] || [ -z "$DB_PASSWORD" ] || [ -z "$SUPABASE_SERVICE_KEY" ]; then
  echo "[ERROR] .env에 다음 항목이 필요합니다:"
  echo "  DB_HOST=db.xxxx.supabase.co"
  echo "  DB_PASSWORD=your_db_password"
  echo "  SUPABASE_SERVICE_ROLE_KEY=your_service_role_key"
  exit 1
fi

# === 백업 실행 ===
BACKUP_DIR="/tmp/supabase-backups"
DATE=$(date +%Y%m%d_%H%M%S)
DAY_KEY=$(date +%Y%m%d)
BACKUP_FILE="$BACKUP_DIR/house_${DATE}.dump"
STORAGE_BUCKET="db-backups"
STORAGE_PATH="house_${DAY_KEY}.dump"

mkdir -p "$BACKUP_DIR"

echo "[$(date)] 백업 시작..."

# pg_dump 실행
PGPASSWORD="$DB_PASSWORD" pg_dump \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U postgres \
  -d postgres \
  -n house \
  --no-owner \
  --no-privileges \
  -F c \
  -f "$BACKUP_FILE"

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "[$(date)] dump 완료: $BACKUP_FILE ($BACKUP_SIZE)"

# === Supabase Storage 업로드 ===
# 같은 날짜 파일이 있으면 덮어쓰기 (하루 1개 유지)
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/octet-stream" \
  -H "x-upsert: true" \
  --data-binary @"$BACKUP_FILE" \
  "${SUPABASE_URL}/storage/v1/object/${STORAGE_BUCKET}/${STORAGE_PATH}")

if [ "$HTTP_STATUS" = "200" ]; then
  echo "[$(date)] Storage 업로드 성공: ${STORAGE_BUCKET}/${STORAGE_PATH}"
else
  echo "[ERROR] Storage 업로드 실패 (HTTP $HTTP_STATUS)"
  echo "  버킷 '$STORAGE_BUCKET'이 존재하는지 확인하세요."
  # 로컬 파일은 보관
  echo "  로컬 백업 보관: $BACKUP_FILE"
  exit 1
fi

# === 오래된 Storage 백업 정리 (30일 이상) ===
CUTOFF_DATE=$(date -v-30d +%Y%m%d 2>/dev/null || date -d '30 days ago' +%Y%m%d 2>/dev/null)

if [ -n "$CUTOFF_DATE" ]; then
  # Storage 파일 목록 조회
  FILES=$(curl -s \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    "${SUPABASE_URL}/storage/v1/object/list/${STORAGE_BUCKET}" \
    -H "Content-Type: application/json" \
    -d '{"prefix":"house_","limit":100}')

  # 30일 이전 파일 삭제
  echo "$FILES" | python3 -c "
import sys, json
try:
    files = json.load(sys.stdin)
    cutoff = '$CUTOFF_DATE'
    for f in files:
        name = f.get('name', '')
        # house_YYYYMMDD.dump 형식에서 날짜 추출
        if name.startswith('house_') and name.endswith('.dump'):
            file_date = name[6:14]
            if file_date < cutoff:
                print(name)
except:
    pass
" 2>/dev/null | while read -r OLD_FILE; do
    curl -s -o /dev/null \
      -X DELETE \
      -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
      "${SUPABASE_URL}/storage/v1/object/${STORAGE_BUCKET}/${OLD_FILE}"
    echo "[$(date)] 오래된 백업 삭제: $OLD_FILE"
  done
fi

# 로컬 임시 파일 정리
rm -f "$BACKUP_FILE"

echo "[$(date)] 백업 완료"
