const fs = require('fs');
const path = require('path');

// 파일 경로
const housePenPath = path.join(__dirname, 'house.pen');
const additionalPath = path.join(__dirname, 'web-design-additional.json');
const backupPath = path.join(__dirname, 'house.pen.backup2');

console.log('🎨 추가 웹 디자인을 house.pen에 추가합니다...\n');

try {
  // 1. house.pen 파일 읽기
  console.log('📖 house.pen 파일 읽는 중...');
  const housePenData = JSON.parse(fs.readFileSync(housePenPath, 'utf8'));

  // 2. 백업 생성
  console.log('💾 백업 파일 생성 중...');
  fs.copyFileSync(housePenPath, backupPath);
  console.log(`✅ 백업 완료: ${backupPath}\n`);

  // 3. 추가 웹 디자인 JSON 읽기
  console.log('📖 추가 웹 디자인 파일 읽는 중...');
  const additionalDesigns = JSON.parse(fs.readFileSync(additionalPath, 'utf8'));

  // 4. webDesignSection 찾기
  const webDesignIndex = housePenData.children.findIndex(
    child => child.id === 'webDesignSection'
  );

  if (webDesignIndex === -1) {
    console.error('❌ webDesignSection을 찾을 수 없습니다.');
    console.error('먼저 add-web-design.js를 실행하세요.');
    process.exit(1);
  }

  const webDesignSection = housePenData.children[webDesignIndex];

  // 5. 추가 페이지들을 webDesignSection의 children에 추가
  console.log('➕ 추가 페이지 추가 중...');

  // Statistics 페이지
  const statsPage = additionalDesigns[0];
  statsPage.x = 3080; // Dashboard 다음 위치
  statsPage.y = 0;

  const existingStatsIndex = webDesignSection.children.findIndex(
    child => child.id === 'webStatistics'
  );
  if (existingStatsIndex !== -1) {
    webDesignSection.children[existingStatsIndex] = statsPage;
  } else {
    webDesignSection.children.push(statsPage);
  }

  // Import/Export 페이지
  const importExportPage = additionalDesigns[1];
  importExportPage.x = 4620; // Statistics 다음 위치
  importExportPage.y = 0;

  const existingImportIndex = webDesignSection.children.findIndex(
    child => child.id === 'webImportExport'
  );
  if (existingImportIndex !== -1) {
    webDesignSection.children[existingImportIndex] = importExportPage;
  } else {
    webDesignSection.children.push(importExportPage);
  }

  // 6. 업데이트된 파일 저장
  console.log('💾 house.pen 파일 저장 중...');
  fs.writeFileSync(housePenPath, JSON.stringify(housePenData, null, 2), 'utf8');

  console.log('\n✨ 완료!\n');
  console.log('📍 웹 디자인 전체 위치 (x=15000 기준):');
  console.log('   1. Web Login:         x=15000 (기준점)');
  console.log('   2. Web Dashboard:     x=16540');
  console.log('   3. Web Statistics:    x=18080 ✨ NEW');
  console.log('   4. Web Import/Export: x=19620 ✨ NEW');
  console.log('   5. Web Settings:      x=21160 (예정)\n');
  console.log('🔧 pencil.dev에서 house.pen 파일을 열어 확인하세요!');
  console.log('💡 원본 복구: mv house.pen.backup2 house.pen');

} catch (error) {
  console.error('❌ 에러 발생:', error.message);
  console.error('\n복구 방법:');
  console.error('  mv house.pen.backup2 house.pen');
  process.exit(1);
}
