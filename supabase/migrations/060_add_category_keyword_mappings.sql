-- Category Keyword Mappings: 카테고리 자동연결 기능
CREATE TABLE IF NOT EXISTS house.category_keyword_mappings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_method_id UUID NOT NULL REFERENCES house.payment_methods(id) ON DELETE CASCADE,
  ledger_id UUID NOT NULL REFERENCES house.ledgers(id) ON DELETE CASCADE,
  keyword TEXT NOT NULL,
  category_id UUID NOT NULL REFERENCES house.categories(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL CHECK (source_type IN ('sms', 'push')),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Unique constraint: 같은 결제수단에서 같은 키워드+소스 중복 방지
ALTER TABLE house.category_keyword_mappings
  ADD CONSTRAINT uq_category_keyword_mapping UNIQUE (payment_method_id, keyword, source_type);

-- Indexes
CREATE INDEX idx_ckm_payment_method ON house.category_keyword_mappings(payment_method_id);
CREATE INDEX idx_ckm_ledger ON house.category_keyword_mappings(ledger_id);
CREATE INDEX idx_ckm_keyword_source ON house.category_keyword_mappings(keyword, source_type);

-- RLS
ALTER TABLE house.category_keyword_mappings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view mappings for their ledgers" ON house.category_keyword_mappings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM house.ledger_members lm
      WHERE lm.ledger_id = category_keyword_mappings.ledger_id
      AND lm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert mappings for their ledgers" ON house.category_keyword_mappings
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM house.ledger_members lm
      WHERE lm.ledger_id = category_keyword_mappings.ledger_id
      AND lm.user_id = auth.uid()
    )
    AND created_by = auth.uid()
  );

CREATE POLICY "Users can delete their own mappings" ON house.category_keyword_mappings
  FOR DELETE USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM house.ledger_members lm
      WHERE lm.ledger_id = category_keyword_mappings.ledger_id
      AND lm.user_id = auth.uid()
      AND lm.role IN ('owner', 'admin')
    )
  );
