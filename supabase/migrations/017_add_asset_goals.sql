-- 자산 목표 테이블 생성
-- 사용자가 자산 목표를 설정하고 추적할 수 있도록 함

CREATE TABLE asset_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ledger_id UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
  
  -- 목표 기본 정보
  title TEXT NOT NULL,                    -- 목표 제목 (예: '1억 모으기', '주식 투자 목표')
  target_amount BIGINT NOT NULL CHECK (target_amount > 0),  -- 목표 금액
  target_date DATE NOT NULL,              -- 목표 달성 날짜
  
  -- 필터 조건 (선택적)
  asset_type TEXT CHECK (asset_type IN ('saving', 'investment', 'real_estate')),  -- 자산 유형 필터
  category_ids UUID[],                    -- 특정 카테고리만 포함
  
  -- 메타 정보
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- 제약조건
  CONSTRAINT valid_target_date CHECK (target_date > CURRENT_DATE)
);

-- 인덱스
CREATE INDEX idx_asset_goals_ledger ON asset_goals(ledger_id);
CREATE INDEX idx_asset_goals_target_date ON asset_goals(target_date);
CREATE INDEX idx_asset_goals_created_by ON asset_goals(created_by);

-- RLS 정책
ALTER TABLE asset_goals ENABLE ROW LEVEL SECURITY;

-- 조회: 가계부 멤버만 가능
CREATE POLICY "Members can view goals" ON asset_goals
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM ledger_members
      WHERE ledger_members.ledger_id = asset_goals.ledger_id
      AND ledger_members.user_id = auth.uid()
    )
  );

-- 생성: 가계부 멤버만 가능
CREATE POLICY "Members can create goals" ON asset_goals
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM ledger_members
      WHERE ledger_members.ledger_id = asset_goals.ledger_id
      AND ledger_members.user_id = auth.uid()
    )
  );

-- 수정: 가계부 멤버만 가능
CREATE POLICY "Members can update goals" ON asset_goals
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM ledger_members
      WHERE ledger_members.ledger_id = asset_goals.ledger_id
      AND ledger_members.user_id = auth.uid()
    )
  );

-- 삭제: 가계부 멤버만 가능
CREATE POLICY "Members can delete goals" ON asset_goals
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM ledger_members
      WHERE ledger_members.ledger_id = asset_goals.ledger_id
      AND ledger_members.user_id = auth.uid()
    )
  );
