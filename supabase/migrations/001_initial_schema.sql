-- 공유 가계부 초기 스키마
-- Supabase SQL Editor에서 실행

-- 확장 기능 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- profiles 테이블 (Supabase Auth 확장)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ledgers 테이블 (가계부)
CREATE TABLE IF NOT EXISTS ledgers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    currency TEXT NOT NULL DEFAULT 'KRW',
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    is_shared BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ledger_members 테이블 (가계부 멤버)
CREATE TABLE IF NOT EXISTS ledger_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ledger_id UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ledger_id, user_id)
);

-- categories 테이블 (카테고리)
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ledger_id UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT '',
    color TEXT NOT NULL DEFAULT '#6750A4',
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- transactions 테이블 (거래)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ledger_id UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE SET NULL,
    amount INT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    date DATE NOT NULL,
    memo TEXT,
    image_url TEXT,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    recurring_type TEXT CHECK (recurring_type IN ('daily', 'weekly', 'monthly')),
    recurring_end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- budgets 테이블 (예산)
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ledger_id UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    amount INT NOT NULL,
    year INT NOT NULL,
    month INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ledger_id, category_id, year, month)
);

-- ledger_invites 테이블 (초대)
CREATE TABLE IF NOT EXISTS ledger_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ledger_id UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    inviter_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    invitee_email TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'member')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_ledger_members_user_id ON ledger_members(user_id);
CREATE INDEX IF NOT EXISTS idx_ledger_members_ledger_id ON ledger_members(ledger_id);
CREATE INDEX IF NOT EXISTS idx_transactions_ledger_id ON transactions(ledger_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_category_id ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_categories_ledger_id ON categories(ledger_id);
CREATE INDEX IF NOT EXISTS idx_budgets_ledger_id ON budgets(ledger_id);
CREATE INDEX IF NOT EXISTS idx_ledger_invites_invitee_email ON ledger_invites(invitee_email);

-- RLS (Row Level Security) 활성화
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledgers ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_invites ENABLE ROW LEVEL SECURITY;

-- profiles 정책
CREATE POLICY "사용자는 모든 프로필을 조회할 수 있음"
    ON profiles FOR SELECT
    USING (true);

CREATE POLICY "사용자는 자신의 프로필을 수정할 수 있음"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "사용자는 자신의 프로필을 생성할 수 있음"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ledgers 정책
CREATE POLICY "사용자는 자신이 멤버인 가계부를 조회할 수 있음"
    ON ledgers FOR SELECT
    USING (
        id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "사용자는 가계부를 생성할 수 있음"
    ON ledgers FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "소유자는 가계부를 수정할 수 있음"
    ON ledgers FOR UPDATE
    USING (owner_id = auth.uid());

CREATE POLICY "소유자는 가계부를 삭제할 수 있음"
    ON ledgers FOR DELETE
    USING (owner_id = auth.uid());

-- ledger_members 정책
CREATE POLICY "멤버는 같은 가계부의 멤버 목록을 조회할 수 있음"
    ON ledger_members FOR SELECT
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "소유자/관리자는 멤버를 추가할 수 있음"
    ON ledger_members FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "소유자는 멤버를 삭제할 수 있음"
    ON ledger_members FOR DELETE
    USING (
        ledger_id IN (
            SELECT id FROM ledgers WHERE owner_id = auth.uid()
        )
        OR user_id = auth.uid()
    );

CREATE POLICY "소유자는 멤버 역할을 변경할 수 있음"
    ON ledger_members FOR UPDATE
    USING (
        ledger_id IN (
            SELECT id FROM ledgers WHERE owner_id = auth.uid()
        )
    );

-- categories 정책
CREATE POLICY "멤버는 가계부의 카테고리를 조회할 수 있음"
    ON categories FOR SELECT
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "소유자/관리자는 카테고리를 생성할 수 있음"
    ON categories FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "소유자/관리자는 카테고리를 수정할 수 있음"
    ON categories FOR UPDATE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "소유자/관리자는 카테고리를 삭제할 수 있음"
    ON categories FOR DELETE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
        AND is_default = FALSE
    );

-- transactions 정책
CREATE POLICY "멤버는 거래를 조회할 수 있음"
    ON transactions FOR SELECT
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "멤버는 거래를 생성할 수 있음"
    ON transactions FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "멤버는 거래를 수정할 수 있음"
    ON transactions FOR UPDATE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "멤버는 거래를 삭제할 수 있음"
    ON transactions FOR DELETE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

-- budgets 정책
CREATE POLICY "멤버는 예산을 조회할 수 있음"
    ON budgets FOR SELECT
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "소유자/관리자는 예산을 생성할 수 있음"
    ON budgets FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "소유자/관리자는 예산을 수정할 수 있음"
    ON budgets FOR UPDATE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "소유자/관리자는 예산을 삭제할 수 있음"
    ON budgets FOR DELETE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ledger_invites 정책
CREATE POLICY "초대받은 사용자는 자신의 초대를 조회할 수 있음"
    ON ledger_invites FOR SELECT
    USING (
        invitee_email = (SELECT email FROM profiles WHERE id = auth.uid())
        OR inviter_user_id = auth.uid()
        OR ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "소유자/관리자는 초대를 생성할 수 있음"
    ON ledger_invites FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "초대 상태 업데이트 가능"
    ON ledger_invites FOR UPDATE
    USING (
        invitee_email = (SELECT email FROM profiles WHERE id = auth.uid())
        OR inviter_user_id = auth.uid()
    );

CREATE POLICY "소유자/관리자/초대자는 초대를 삭제할 수 있음"
    ON ledger_invites FOR DELETE
    USING (
        inviter_user_id = auth.uid()
        OR ledger_id IN (
            SELECT id FROM ledgers WHERE owner_id = auth.uid()
        )
    );

-- 트리거: 회원가입 시 자동으로 프로필 생성
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, email, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 트리거: 가계부 생성 시 자동으로 멤버로 등록
CREATE OR REPLACE FUNCTION handle_new_ledger()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO ledger_members (ledger_id, user_id, role)
    VALUES (NEW.id, NEW.owner_id, 'owner');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_ledger_created ON ledgers;
CREATE TRIGGER on_ledger_created
    AFTER INSERT ON ledgers
    FOR EACH ROW EXECUTE FUNCTION handle_new_ledger();

-- 트리거: 가계부 생성 시 기본 카테고리 추가
CREATE OR REPLACE FUNCTION handle_new_ledger_categories()
RETURNS TRIGGER AS $$
BEGIN
    -- 지출 카테고리
    INSERT INTO categories (ledger_id, name, icon, color, type, is_default, sort_order) VALUES
        (NEW.id, '식비', '', '#FF6B6B', 'expense', TRUE, 1),
        (NEW.id, '교통', '', '#4ECDC4', 'expense', TRUE, 2),
        (NEW.id, '쇼핑', '', '#FFE66D', 'expense', TRUE, 3),
        (NEW.id, '생활', '', '#95E1D3', 'expense', TRUE, 4),
        (NEW.id, '통신', '', '#A8DADC', 'expense', TRUE, 5),
        (NEW.id, '의료', '', '#F4A261', 'expense', TRUE, 6),
        (NEW.id, '문화', '', '#E76F51', 'expense', TRUE, 7),
        (NEW.id, '교육', '', '#2A9D8F', 'expense', TRUE, 8),
        (NEW.id, '기타 지출', '', '#6C757D', 'expense', TRUE, 9);

    -- 수입 카테고리
    INSERT INTO categories (ledger_id, name, icon, color, type, is_default, sort_order) VALUES
        (NEW.id, '급여', '', '#4CAF50', 'income', TRUE, 1),
        (NEW.id, '부업', '', '#8BC34A', 'income', TRUE, 2),
        (NEW.id, '용돈', '', '#CDDC39', 'income', TRUE, 3),
        (NEW.id, '이자', '', '#00BCD4', 'income', TRUE, 4),
        (NEW.id, '기타 수입', '', '#9E9E9E', 'income', TRUE, 5);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_ledger_created_categories ON ledgers;
CREATE TRIGGER on_ledger_created_categories
    AFTER INSERT ON ledgers
    FOR EACH ROW EXECUTE FUNCTION handle_new_ledger_categories();

-- Realtime 활성화
ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE categories;
ALTER PUBLICATION supabase_realtime ADD TABLE ledger_members;
