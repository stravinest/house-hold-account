-- 앱 버전 관리 테이블
CREATE TABLE app_versions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
  version TEXT NOT NULL,
  build_number INTEGER NOT NULL,
  store_url TEXT,
  release_notes TEXT,
  is_force_update BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: 모든 인증 사용자 읽기 허용
ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_read" ON app_versions FOR SELECT TO authenticated USING (true);

-- 초기 데이터 (현재 최신 버전)
INSERT INTO app_versions (platform, version, build_number, store_url)
VALUES ('android', '1.0.10', 15, 'https://play.google.com/store/apps/details?id=com.household.shared.shared_household_account');
