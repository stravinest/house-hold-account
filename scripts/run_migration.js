#!/usr/bin/env node

/**
 * Supabase 마이그레이션 실행 스크립트
 * 006_add_profile_color.sql 마이그레이션을 실행합니다.
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function runMigration() {
  console.log('🚀 Supabase 마이그레이션 시작...\n');

  // 환경 변수 확인
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseServiceKey) {
    console.error('❌ 환경 변수 오류:');
    console.error('   SUPABASE_URL과 SUPABASE_SERVICE_ROLE_KEY (또는 SUPABASE_ANON_KEY)가 필요합니다.');
    console.error('   .env 파일을 확인해주세요.\n');
    process.exit(1);
  }

  console.log('✓ Supabase URL:', supabaseUrl);
  console.log('✓ 인증 키 확인 완료\n');

  // Supabase 클라이언트 생성
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  // 마이그레이션 SQL 파일 읽기
  const migrationPath = path.join(__dirname, '../supabase/migrations/006_add_profile_color.sql');

  if (!fs.existsSync(migrationPath)) {
    console.error('❌ 마이그레이션 파일을 찾을 수 없습니다:', migrationPath);
    process.exit(1);
  }

  const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
  console.log('✓ 마이그레이션 파일 로드 완료\n');
  console.log('📄 실행할 SQL:');
  console.log('─'.repeat(60));
  console.log(migrationSQL);
  console.log('─'.repeat(60));
  console.log('');

  try {
    // 1. profiles 테이블 존재 확인
    console.log('1️⃣  profiles 테이블 확인 중...');
    const { data: tables, error: tableError } = await supabase
      .from('profiles')
      .select('id')
      .limit(1);

    if (tableError && tableError.code !== 'PGRST116') {
      console.error('❌ profiles 테이블 확인 실패:', tableError.message);
      process.exit(1);
    }
    console.log('✓ profiles 테이블 존재 확인\n');

    // 2. color 컬럼이 이미 존재하는지 확인
    console.log('2️⃣  기존 color 컬럼 확인 중...');
    const { data: existingData } = await supabase
      .from('profiles')
      .select('color')
      .limit(1);

    if (existingData && existingData.length > 0 && 'color' in existingData[0]) {
      console.log('⚠️  color 컬럼이 이미 존재합니다.');
      console.log('   마이그레이션이 이미 실행되었을 수 있습니다.\n');

      const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
      });

      const answer = await new Promise(resolve => {
        readline.question('계속 진행하시겠습니까? (y/N): ', resolve);
      });
      readline.close();

      if (answer.toLowerCase() !== 'y') {
        console.log('\n❌ 마이그레이션 취소됨');
        process.exit(0);
      }
    } else {
      console.log('✓ color 컬럼 없음 (마이그레이션 필요)\n');
    }

    // 3. SQL 실행
    console.log('3️⃣  마이그레이션 실행 중...');
    console.log('   (이 작업은 Supabase 대시보드의 SQL Editor에서 수동으로 실행해야 합니다)\n');

    console.log('📋 다음 단계:');
    console.log('   1. Supabase 대시보드 (https://app.supabase.com) 접속');
    console.log('   2. 프로젝트 선택');
    console.log('   3. 왼쪽 메뉴에서 "SQL Editor" 클릭');
    console.log('   4. "+ New query" 클릭');
    console.log('   5. 위의 SQL을 복사하여 붙여넣기');
    console.log('   6. "Run" 버튼 클릭\n');

    console.log('또는 다음 명령어로 마이그레이션 SQL을 복사할 수 있습니다:');
    console.log('   cat supabase/migrations/006_add_profile_color.sql | pbcopy\n');

    console.log('✅ 안내 완료!');

  } catch (error) {
    console.error('\n❌ 오류 발생:', error.message);
    if (error.stack) {
      console.error('스택 트레이스:', error.stack);
    }
    process.exit(1);
  }
}

runMigration().catch(console.error);
