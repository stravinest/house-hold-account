-- 회원가입 시 기본 가계부 자동 생성
-- 기존 handle_new_user() 함수를 수정하여 profiles + 기본 가계부를 함께 생성

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_ledger_id UUID;
BEGIN
    -- 1. profiles 테이블에 사용자 정보 생성
    INSERT INTO profiles (id, email, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    );

    -- 2. 기본 가계부 생성 (실패 시 전체 트랜잭션 롤백)
    BEGIN
        INSERT INTO ledgers (name, currency, owner_id, is_shared)
        VALUES ('내 가계부', 'KRW', NEW.id, FALSE)
        RETURNING id INTO new_ledger_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to create default ledger for user %: %', NEW.id, SQLERRM;
    END;

    -- 트리거 체이닝으로 ledger_members, categories 자동 생성됨
    -- 실행 순서:
    --   1. on_ledger_created: owner를 ledger_members에 추가
    --   2. on_ledger_created_categories: 기본 카테고리 생성

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 트리거는 이미 존재하므로 재생성 불필요
-- (001_initial_schema.sql의 on_auth_user_created 트리거가 handle_new_user 함수를 호출)
