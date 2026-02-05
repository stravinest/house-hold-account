-- 049_record_manual_schema_changes.sql
-- ========================================
-- 수동으로 추가된 스키마 변경 사항 기록
-- ========================================
-- 실제 DB에는 이미 존재하지만 마이그레이션 기록이 없던 항목들
-- 재현성과 버전 관리를 위해 추가
-- 모든 구문은 IF NOT EXISTS 또는 CREATE OR REPLACE를 사용하여 안전하게 실행

-- ============================================
-- 1. learned_push_formats 테이블
-- ============================================
-- Push 알림 기반 자동수집을 위한 학습된 포맷 저장
-- learned_sms_formats와 유사한 구조

CREATE TABLE IF NOT EXISTS house.learned_push_formats (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    payment_method_id UUID NOT NULL REFERENCES house.payment_methods(id) ON DELETE CASCADE,
    package_name TEXT NOT NULL,
    app_keywords TEXT[] DEFAULT '{}',
    amount_regex TEXT NOT NULL DEFAULT '([0-9,]+)\s*원',
    type_keywords JSONB DEFAULT '{"income": ["입금", "충전"], "expense": ["출금", "결제", "승인"]}',
    merchant_regex TEXT,
    date_regex TEXT,
    sample_notification TEXT,
    confidence NUMERIC(3,2) DEFAULT 0.8,
    match_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(payment_method_id, package_name)
);

CREATE INDEX IF NOT EXISTS idx_learned_push_formats_payment_method
  ON house.learned_push_formats(payment_method_id);

-- RLS 활성화 (이미 활성화되어 있으면 무시됨)
ALTER TABLE house.learned_push_formats ENABLE ROW LEVEL SECURITY;

-- RLS 정책 (이미 존재하면 무시)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'house'
      AND tablename = 'learned_push_formats'
      AND policyname = 'Users can view own ledger push formats'
  ) THEN
    CREATE POLICY "Users can view own ledger push formats" ON house.learned_push_formats
      FOR SELECT USING (
        payment_method_id IN (
          SELECT id FROM house.payment_methods
          WHERE ledger_id IN (
            SELECT ledger_id FROM house.ledger_members
            WHERE user_id = auth.uid()
          )
        )
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'house'
      AND tablename = 'learned_push_formats'
      AND policyname = 'Users can insert own ledger push formats'
  ) THEN
    CREATE POLICY "Users can insert own ledger push formats" ON house.learned_push_formats
      FOR INSERT WITH CHECK (
        payment_method_id IN (
          SELECT id FROM house.payment_methods
          WHERE ledger_id IN (
            SELECT ledger_id FROM house.ledger_members
            WHERE user_id = auth.uid()
          )
        )
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'house'
      AND tablename = 'learned_push_formats'
      AND policyname = 'Users can update own ledger push formats'
  ) THEN
    CREATE POLICY "Users can update own ledger push formats" ON house.learned_push_formats
      FOR UPDATE USING (
        payment_method_id IN (
          SELECT id FROM house.payment_methods
          WHERE ledger_id IN (
            SELECT ledger_id FROM house.ledger_members
            WHERE user_id = auth.uid()
          )
        )
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'house'
      AND tablename = 'learned_push_formats'
      AND policyname = 'Users can delete own ledger push formats'
  ) THEN
    CREATE POLICY "Users can delete own ledger push formats" ON house.learned_push_formats
      FOR DELETE USING (
        payment_method_id IN (
          SELECT id FROM house.payment_methods
          WHERE ledger_id IN (
            SELECT ledger_id FROM house.ledger_members
            WHERE user_id = auth.uid()
          )
        )
      );
  END IF;
END $$;

-- ============================================
-- 2. pending_transactions.is_viewed 컬럼
-- ============================================
-- 임시 거래 조회 여부 추적용 컬럼

ALTER TABLE house.pending_transactions
ADD COLUMN IF NOT EXISTS is_viewed BOOLEAN DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_pending_transactions_is_viewed
  ON house.pending_transactions(ledger_id, is_viewed)
  WHERE status = 'pending';

-- ============================================
-- 3. accept_ledger_invite RPC 함수
-- ============================================
-- 가계부 초대 수락 처리 (트랜잭션 보장)

CREATE OR REPLACE FUNCTION house.accept_ledger_invite(target_invite_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'house', 'public', 'auth'
AS $$
DECLARE
  current_uid UUID;
  invite_record RECORD;
  member_count INT;
BEGIN
  current_uid := auth.uid();
  IF current_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'UNAUTHORIZED');
  END IF;

  -- 초대 조회
  SELECT * INTO invite_record FROM house.ledger_invites WHERE id = target_invite_id;

  IF invite_record IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'NOT_FOUND');
  END IF;

  -- [중복 클릭 방지] 이미 수락된 경우 에러를 내지 않고 성공 반환
  IF invite_record.status = 'accepted' THEN
    RETURN jsonb_build_object('success', true, 'message', 'ALREADY_ACCEPTED');
  END IF;

  IF invite_record.status != 'pending' THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'INVALID_STATUS');
  END IF;

  -- 멤버 수 제한 확인
  SELECT COUNT(*) INTO member_count FROM house.ledger_members WHERE ledger_id = invite_record.ledger_id;
  IF member_count >= 10 THEN -- AppConstants.maxMembersPerLedger
    RETURN jsonb_build_object('success', false, 'error_code', 'MEMBER_LIMIT_REACHED');
  END IF;

  -- 트랜잭션 처리
  INSERT INTO house.ledger_members (ledger_id, user_id, role)
  VALUES (invite_record.ledger_id, current_uid, invite_record.role);

  UPDATE house.ledger_invites SET status = 'accepted' WHERE id = target_invite_id;
  UPDATE house.ledgers SET is_shared = true WHERE id = invite_record.ledger_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

COMMENT ON FUNCTION house.accept_ledger_invite IS '가계부 초대 수락 (트랜잭션 보장, 중복 방지)';
GRANT EXECUTE ON FUNCTION house.accept_ledger_invite(UUID) TO authenticated;

-- ============================================
-- 4. batch_reorder_categories RPC 함수
-- ============================================
-- 카테고리 순서 일괄 변경

CREATE OR REPLACE FUNCTION house.batch_reorder_categories(p_category_ids uuid[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'house'
AS $$
DECLARE
  v_id uuid;
  v_index int := 0;
BEGIN
  FOREACH v_id IN ARRAY p_category_ids
  LOOP
    UPDATE house.categories
    SET sort_order = v_index
    WHERE id = v_id;
    v_index := v_index + 1;
  END LOOP;
END;
$$;

COMMENT ON FUNCTION house.batch_reorder_categories IS '카테고리 순서 일괄 변경';
GRANT EXECUTE ON FUNCTION house.batch_reorder_categories(UUID[]) TO authenticated;

-- ============================================
-- 5. batch_reorder_payment_methods RPC 함수
-- ============================================
-- 결제수단 순서 일괄 변경

CREATE OR REPLACE FUNCTION house.batch_reorder_payment_methods(p_payment_method_ids uuid[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'house'
AS $$
DECLARE
  v_id uuid;
  v_index int := 0;
BEGIN
  FOREACH v_id IN ARRAY p_payment_method_ids
  LOOP
    UPDATE house.payment_methods
    SET sort_order = v_index
    WHERE id = v_id;
    v_index := v_index + 1;
  END LOOP;
END;
$$;

COMMENT ON FUNCTION house.batch_reorder_payment_methods IS '결제수단 순서 일괄 변경';
GRANT EXECUTE ON FUNCTION house.batch_reorder_payment_methods(UUID[]) TO authenticated;

-- ============================================
-- 6. delete_user_account RPC 함수
-- ============================================
-- 사용자 계정 완전 삭제 (GDPR 준수)

CREATE OR REPLACE FUNCTION house.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'house', 'public'
AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- 현재 로그인한 사용자 ID 확인
    current_user_id := auth.uid();

    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 1. house 스키마의 관련 데이터 삭제 (CASCADE가 있지만 명시적으로 삭제)
    -- 가계부 소유자인 경우 가계부 삭제 (CASCADE로 멤버, 카테고리, 거래 등 삭제)
    DELETE FROM house.ledgers WHERE owner_id = current_user_id;

    -- 2. 다른 가계부의 멤버십 삭제
    DELETE FROM house.ledger_members WHERE user_id = current_user_id;

    -- 3. FCM 토큰 삭제
    DELETE FROM house.fcm_tokens WHERE user_id = current_user_id;

    -- 4. 알림 설정 삭제
    DELETE FROM house.notification_settings WHERE user_id = current_user_id;

    -- 5. 푸시 알림 기록 삭제
    DELETE FROM house.push_notifications WHERE user_id = current_user_id;

    -- 6. 프로필 삭제
    DELETE FROM house.profiles WHERE id = current_user_id;

    -- 7. auth.users에서 사용자 삭제 (이것이 실제 계정 삭제)
    DELETE FROM auth.users WHERE id = current_user_id;
END;
$$;

COMMENT ON FUNCTION house.delete_user_account IS '사용자 계정 완전 삭제 (GDPR 준수)';
GRANT EXECUTE ON FUNCTION house.delete_user_account() TO authenticated;
