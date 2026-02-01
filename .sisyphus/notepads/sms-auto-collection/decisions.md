
## ContentObserver 백그라운드 동작 연구 결과 (2026-01-31)

### 연구 목적
SmsContentObserver가 다음 시나리오에서 작동하는지 확인:
1. 앱이 백그라운드에 있을 때
2. 앱 프로세스가 종료되었을 때
3. 기기 재부팅 후

### 연구 결과

**핵심 결론: ContentObserver는 앱 프로세스 종료 시 작동하지 않음**

#### 공식 문서 근거
- ContentObserver는 앱 프로세스 내 객체
- 프로세스 종료 시 메모리에서 제거됨
- 시스템 레벨 컴포넌트가 아님

#### 실제 사례 근거
- Stack Overflow 다수 사례 (2017-2019)
- Foreground Service만이 유일한 해결책
- START_STICKY Service도 앱 종료 시 함께 종료됨

### 아키텍처 결정

**현재 구현 (SmsContentObserver) 문제점:**
- ❌ 앱 종료 시 SMS 자동 수집 중단
- ❌ 사용자가 앱 스와이프하면 기능 중단
- ❌ 신뢰할 수 없는 백그라운드 동작

**권장 솔루션 (우선순위 순):**

1. **BroadcastReceiver (최우선 권장)**
   - ✅ 앱 종료 상태에서도 작동
   - ✅ 시스템이 앱 프로세스 자동 시작
   - ✅ 배터리 효율적
   - ✅ 알림 불필요
   - ✅ SMS 전용 최적화

2. **WorkManager ContentUriTriggers**
   - ✅ 앱 종료 후에도 작동
   - ✅ 배터리 최적화
   - ⚠️ 즉각 반응 보장 안 됨
   - ⚠️ API 24+ 필요

3. **Foreground Service + ContentObserver**
   - ✅ 가장 확실한 방법
   - ❌ 영구 알림 필수 (사용자 불만)
   - ❌ 배터리 소모 증가
   - ❌ Android 14+ 추가 권한 필요

### 다음 단계

**즉시 조치:**
1. BroadcastReceiver 구현 검토
2. 현재 ContentObserver 구현과 비교
3. 마이그레이션 계획 수립

**고려사항:**
- SMS_RECEIVED 권한 필요
- Android 버전별 동작 차이 확인
- 기존 사용자 데이터 마이그레이션

### 참고 자료
- 상세 연구 결과: `/tmp/contentobserver_research.md`
- 공식 문서: https://developer.android.com/reference/android/database/ContentObserver
- Stack Overflow 사례: https://stackoverflow.com/questions/41920447
