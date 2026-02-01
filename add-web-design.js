const fs = require('fs');
const path = require('path');

// 파일 경로
const housePenPath = path.join(__dirname, 'house.pen');
const webDesignPath = path.join(__dirname, 'web-design-addon.json');
const backupPath = path.join(__dirname, 'house.pen.backup');

console.log('🎨 웹 디자인을 house.pen에 추가합니다...\n');

try {
  // 1. house.pen 파일 읽기
  console.log('📖 house.pen 파일 읽는 중...');
  const housePenData = JSON.parse(fs.readFileSync(housePenPath, 'utf8'));

  // 2. 백업 생성
  console.log('💾 백업 파일 생성 중...');
  fs.copyFileSync(housePenPath, backupPath);
  console.log(`✅ 백업 완료: ${backupPath}\n`);

  // 3. 웹 디자인 JSON 읽기
  console.log('📖 웹 디자인 파일 읽는 중...');
  const webDesign = JSON.parse(fs.readFileSync(webDesignPath, 'utf8'));

  // 4. 웹 디자인이 이미 추가되었는지 확인
  const existingIndex = housePenData.children.findIndex(
    child => child.id === 'webDesignSection'
  );

  if (existingIndex !== -1) {
    console.log('⚠️  이미 웹 디자인이 존재합니다. 덮어쓰기합니다...');
    housePenData.children[existingIndex] = webDesign;
  } else {
    console.log('➕ 웹 디자인 추가 중...');
    housePenData.children.push(webDesign);
  }

  // 5. 업데이트된 파일 저장
  console.log('💾 house.pen 파일 저장 중...');
  fs.writeFileSync(housePenPath, JSON.stringify(housePenData, null, 2), 'utf8');

  console.log('\n✨ 완료!\n');
  console.log('📍 웹 디자인 위치:');
  console.log('   - Web Login: x=15000');
  console.log('   - Web Dashboard: x=16540');
  console.log('   - Web Statistics: x=18080 (예정)');
  console.log('   - Web Import/Export: x=19620 (예정)');
  console.log('   - Web Settings: x=21160 (예정)\n');
  console.log('🔧 pencil.dev에서 확인하세요!');
  console.log('💡 원본 복구: mv house.pen.backup house.pen');

} catch (error) {
  console.error('❌ 에러 발생:', error.message);
  console.error('\n복구 방법:');
  console.error('  mv house.pen.backup house.pen');
  process.exit(1);
}
