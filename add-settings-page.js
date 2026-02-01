const fs = require('fs');
const path = require('path');

const housePenPath = path.join(__dirname, 'house.pen');
const settingsPath = path.join(__dirname, 'web-design-settings.json');
const backupPath = path.join(__dirname, 'house.pen.backup3');

console.log('🎨 Settings 페이지를 house.pen에 추가합니다...\n');

try {
  console.log('📖 house.pen 파일 읽는 중...');
  const housePenData = JSON.parse(fs.readFileSync(housePenPath, 'utf8'));

  console.log('💾 백업 파일 생성 중...');
  fs.copyFileSync(housePenPath, backupPath);
  console.log(`✅ 백업 완료: ${backupPath}\n`);

  console.log('📖 Settings 페이지 파일 읽는 중...');
  const settingsPage = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));

  const webDesignIndex = housePenData.children.findIndex(
    child => child.id === 'webDesignSection'
  );

  if (webDesignIndex === -1) {
    console.error('❌ webDesignSection을 찾을 수 없습니다.');
    process.exit(1);
  }

  const webDesignSection = housePenData.children[webDesignIndex];

  console.log('➕ Settings 페이지 추가 중...');
  settingsPage.x = 6160;
  settingsPage.y = 0;

  const existingIndex = webDesignSection.children.findIndex(
    child => child.id === 'webSettings'
  );
  if (existingIndex !== -1) {
    webDesignSection.children[existingIndex] = settingsPage;
  } else {
    webDesignSection.children.push(settingsPage);
  }

  console.log('💾 house.pen 파일 저장 중...');
  fs.writeFileSync(housePenPath, JSON.stringify(housePenData, null, 2), 'utf8');

  console.log('\n✨ 모든 웹 디자인 추가 완료!\n');
  console.log('📍 웹 디자인 최종 위치:');
  console.log('   ┌─────────────────────────────────────────┐');
  console.log('   │  Web Statistics Platform (x=15000)      │');
  console.log('   ├─────────────────────────────────────────┤');
  console.log('   │  1. Login         → x=15000 (기준점)    │');
  console.log('   │  2. Dashboard     → x=16540             │');
  console.log('   │  3. Statistics    → x=18080             │');
  console.log('   │  4. Import/Export → x=19620             │');
  console.log('   │  5. Settings      → x=21160 ✨ NEW      │');
  console.log('   └─────────────────────────────────────────┘\n');
  console.log('🎨 pencil.dev에서 house.pen을 열어 확인하세요!');
  console.log('📐 총 너비: 약 7200px (5개 페이지 + 간격)');

} catch (error) {
  console.error('❌ 에러 발생:', error.message);
  console.error('복구: mv house.pen.backup3 house.pen');
  process.exit(1);
}
