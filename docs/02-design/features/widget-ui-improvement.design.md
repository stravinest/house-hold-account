# Design: 홈 화면 위젯 UI 개선 및 중복 저장 방지

**Feature ID**: `widget-ui-improvement`
**작성일**: 2026-02-02
**작성자**: AI Assistant
**PDCA Phase**: Design
**Plan 문서**: [widget-ui-improvement.plan.md](../../01-plan/features/widget-ui-improvement.plan.md)

---

## 1. 아키텍처 설계 (Architecture Design)

### 1.1 레이어 구조

```
┌─────────────────────────────────────────────────────┐
│ Android Widget Layer (Native)                       │
│  - widget_quick_add.xml (수정)                      │
│    - TextView 제거                                   │
│  - QuickAddWidget.kt (변경 없음)                    │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ Android Activity Layer (Native)                     │
│  - activity_quick_input.xml (수정)                  │
│    + ProgressBar 추가                                │
│  - QuickInputActivity.kt (수정)                     │
│    + 저장 버튼 비활성화 로직                         │
│    + ProgressBar 표시/숨김 로직                      │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ Backend (Supabase)                                  │
│  - createExpenseTransaction() (변경 없음)           │
└─────────────────────────────────────────────────────┘
```

### 1.2 데이터 흐름

```
1. 사용자가 홈 화면 위젯 클릭
   ↓
2. QuickInputActivity 실행 (금액 입력 다이얼로그)
   ↓
3. 사용자가 금액/제목 입력 후 '저장' 버튼 클릭
   ↓
4. [NEW] 저장 버튼 즉시 비활성화 (isEnabled = false)
   ↓
5. [NEW] ProgressBar 표시 (visibility = VISIBLE)
   ↓
6. Supabase API 호출 (createExpenseTransaction)
   ↓
7a. 성공 → Activity 종료
7b. 실패 → [NEW] 버튼 재활성화 + ProgressBar 숨김 + 에러 메시지
```

---

## 2. UI/레이아웃 설계 (UI/Layout Design)

### 2.1 위젯 레이아웃 수정

**파일**: `android/app/src/main/res/layout/widget_quick_add.xml`

#### 현재 구조 (Before)
```xml
<FrameLayout>
    <LinearLayout android:id="@+id/btn_add_expense">
        <ImageView /> <!-- 앱 아이콘 -->
        <ImageView /> <!-- 추가 버튼 아이콘 -->
        <TextView android:text="빠른 추가" /> <!-- 제거 대상 -->
    </LinearLayout>
</FrameLayout>
```

#### 수정 후 구조 (After)
```xml
<FrameLayout>
    <LinearLayout android:id="@+id/btn_add_expense">
        <ImageView /> <!-- 앱 아이콘 -->
        <ImageView /> <!-- 추가 버튼 아이콘 -->
        <!-- TextView 제거 완료 -->
    </LinearLayout>
</FrameLayout>
```

**변경 사항**:
- Line 39-45의 TextView 완전 제거
- 아이콘만으로 위젯 구성
- 레이아웃 패딩 유지 (기존 6dp)

### 2.2 입력 다이얼로그 레이아웃 수정

**파일**: `android/app/src/main/res/layout/activity_quick_input.xml`

#### 현재 구조 (Before)
```xml
<LinearLayout>
    <TextView /> <!-- 제목 -->
    <EditText android:id="@+id/amountInput" />
    <EditText android:id="@+id/titleInput" />

    <LinearLayout> <!-- 버튼 영역 -->
        <Button android:id="@+id/cancelButton" />
        <Button android:id="@+id/saveButton" />
    </LinearLayout>
</LinearLayout>
```

#### 수정 후 구조 (After)
```xml
<LinearLayout>
    <TextView /> <!-- 제목 -->
    <EditText android:id="@+id/amountInput" />
    <EditText android:id="@+id/titleInput" />

    <LinearLayout> <!-- 버튼 영역 -->
        <Button android:id="@+id/cancelButton" />

        <!-- 저장 버튼과 ProgressBar를 감싸는 컨테이너 -->
        <RelativeLayout
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginStart="12dp">

            <Button
                android:id="@+id/saveButton"
                android:layout_width="wrap_content"
                android:layout_height="44dp"
                android:minWidth="80dp"
                android:text="저장" />

            <ProgressBar
                android:id="@+id/progressBar"
                style="?android:attr/progressBarStyleSmall"
                android:layout_width="24dp"
                android:layout_height="24dp"
                android:layout_alignParentEnd="true"
                android:layout_centerVertical="true"
                android:layout_marginEnd="8dp"
                android:visibility="gone"
                android:indeterminateTint="#FFFFFF" />
        </RelativeLayout>
    </LinearLayout>
</LinearLayout>
```

**변경 사항**:
- 저장 버튼과 ProgressBar를 RelativeLayout으로 그룹화
- ProgressBar는 버튼 오른쪽 끝에 위치 (alignParentEnd)
- ProgressBar 초기 상태: `visibility="gone"`
- ProgressBar 색상: 흰색 (#FFFFFF, 녹색 버튼 배경과 대비)

### 2.3 ProgressBar 스타일

**스펙**:
- 크기: 24dp × 24dp (작고 깔끔)
- 스타일: `progressBarStyleSmall` (작은 원형)
- 색상: 흰색 (버튼 배경색과 대비)
- 위치: 저장 버튼 오른쪽 끝

---

## 3. 로직 설계 (Logic Design)

### 3.1 저장 버튼 클릭 처리

**파일**: `android/app/src/main/kotlin/.../QuickInputActivity.kt`

#### 현재 코드 (Before) - Line 50-57
```kotlin
saveButton.setOnClickListener {
    saveExpense()
}
```

#### 수정 후 코드 (After)
```kotlin
private var isSaving = false  // 저장 중 플래그 추가

saveButton.setOnClickListener {
    if (!isSaving) {
        saveExpense()
    }
}
```

**변경 사항**:
- `isSaving` 플래그로 중복 클릭 방지 (Debounce)
- 이미 저장 중이면 클릭 무시

### 3.2 저장 로직 개선

**파일**: `android/app/src/main/kotlin/.../QuickInputActivity.kt`

#### 현재 코드 (Before) - Line 59-117
```kotlin
private fun saveExpense() {
    val amountText = amountInput.text?.toString()

    if (amountText.isNullOrBlank()) {
        Toast.makeText(this, "금액을 입력하세요", Toast.LENGTH_SHORT).show()
        return
    }

    val amount = amountText.toIntOrNull()
    if (amount == null || amount <= 0) {
        Toast.makeText(this, "유효한 금액을 입력하세요", Toast.LENGTH_SHORT).show()
        return
    }

    activityScope.launch {
        try {
            // ... Supabase API 호출
            val success = supabaseHelper.createExpenseTransaction(...)

            if (success) {
                updateWidgetData(ledgerId)
                Toast.makeText(this@QuickInputActivity, "저장 완료", Toast.LENGTH_SHORT).show()
                finish()
            } else {
                Toast.makeText(this@QuickInputActivity, "저장 실패. 네트워크를 확인해주세요", Toast.LENGTH_SHORT).show()
            }
        } catch (e: Exception) {
            Toast.makeText(this@QuickInputActivity, "오류: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }
}
```

#### 수정 후 코드 (After)
```kotlin
private var isSaving = false

private fun saveExpense() {
    val amountText = amountInput.text?.toString()

    // 유효성 검증 (변경 없음)
    if (amountText.isNullOrBlank()) {
        Toast.makeText(this, "금액을 입력하세요", Toast.LENGTH_SHORT).show()
        return
    }

    val amount = amountText.toIntOrNull()
    if (amount == null || amount <= 0) {
        Toast.makeText(this, "유효한 금액을 입력하세요", Toast.LENGTH_SHORT).show()
        return
    }

    // [NEW] 저장 시작 시 UI 상태 변경
    isSaving = true
    saveButton.isEnabled = false
    progressBar.visibility = View.VISIBLE

    activityScope.launch {
        try {
            val ledgerId = supabaseHelper.getCurrentLedgerId()
            if (ledgerId.isNullOrBlank()) {
                Toast.makeText(this@QuickInputActivity, "가계부를 찾을 수 없습니다", Toast.LENGTH_SHORT).show()
                resetSaveButton()
                return@launch
            }

            val token = supabaseHelper.getValidToken()
            if (token.isNullOrBlank()) {
                Toast.makeText(this@QuickInputActivity, "로그인이 만료되었습니다. 앱을 먼저 실행해주세요", Toast.LENGTH_LONG).show()
                finish()
                return@launch
            }

            val userId = supabaseHelper.getUserIdFromToken(token)
            if (userId.isNullOrBlank()) {
                Toast.makeText(this@QuickInputActivity, "사용자 정보를 찾을 수 없습니다", Toast.LENGTH_SHORT).show()
                resetSaveButton()
                return@launch
            }

            val title = titleInput.text?.toString()?.takeIf { it.isNotBlank() }
            val today = supabaseHelper.getTodayDate()

            val success = supabaseHelper.createExpenseTransaction(
                ledgerId = ledgerId,
                userId = userId,
                amount = amount,
                title = title,
                categoryId = null,
                date = today
            )

            if (success) {
                updateWidgetData(ledgerId)
                Toast.makeText(this@QuickInputActivity, "저장 완료", Toast.LENGTH_SHORT).show()
                finish()  // 성공 시 Activity 종료 (버튼 재활성화 불필요)
            } else {
                // [NEW] 실패 시 UI 복구
                Toast.makeText(this@QuickInputActivity, "저장 실패. 네트워크를 확인해주세요", Toast.LENGTH_SHORT).show()
                resetSaveButton()
            }
        } catch (e: Exception) {
            // [NEW] 예외 시 UI 복구
            Toast.makeText(this@QuickInputActivity, "오류: ${e.message}", Toast.LENGTH_SHORT).show()
            resetSaveButton()
        }
    }
}

// [NEW] 저장 버튼 상태 복구 함수
private fun resetSaveButton() {
    isSaving = false
    saveButton.isEnabled = true
    progressBar.visibility = View.GONE
}
```

**변경 사항**:
1. **저장 시작 시**:
   - `isSaving = true` 설정
   - `saveButton.isEnabled = false` (버튼 비활성화)
   - `progressBar.visibility = View.VISIBLE` (로딩 표시)

2. **저장 성공 시**:
   - Activity 종료 (`finish()`)
   - 버튼 재활성화 불필요 (Activity 종료되므로)

3. **저장 실패/에러 시**:
   - `resetSaveButton()` 호출로 UI 복구
   - 사용자가 다시 시도 가능

### 3.3 초기화 코드 수정

**파일**: `android/app/src/main/kotlin/.../QuickInputActivity.kt`

#### 수정 (onCreate 메서드)
```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_quick_input)

    // ... 기존 코드

    amountInput = findViewById(R.id.amountInput)
    titleInput = findViewById(R.id.titleInput)
    saveButton = findViewById(R.id.saveButton)
    cancelButton = findViewById(R.id.cancelButton)
    progressBar = findViewById(R.id.progressBar)  // [NEW] ProgressBar 초기화

    saveButton.setOnClickListener {
        if (!isSaving) {  // [NEW] 중복 클릭 방지
            saveExpense()
        }
    }

    cancelButton.setOnClickListener {
        finish()
    }
}
```

**변경 사항**:
- `progressBar` 뷰 바인딩 추가
- `setOnClickListener`에 중복 클릭 방지 로직 추가

---

## 4. 상태 다이어그램 (State Diagram)

### 4.1 저장 버튼 상태 흐름

```
┌─────────────┐
│   초기 상태  │
│  isEnabled   │
│  isSaving=F  │
└──────┬──────┘
       │ 사용자 클릭
       ↓
┌─────────────┐
│  저장 중     │
│ !isEnabled   │
│  isSaving=T  │
│  ProgressBar │
│  표시 중     │
└──────┬──────┘
       │
       ├─ 성공 → Activity 종료
       │
       └─ 실패/에러
           ↓
       ┌─────────────┐
       │  복구 상태   │
       │  isEnabled   │
       │  isSaving=F  │
       │  ProgressBar │
       │  숨김        │
       └─────────────┘
```

### 4.2 사용자 시나리오

#### 시나리오 1: 정상 저장
```
1. 사용자가 위젯 클릭
2. 금액 입력 다이얼로그 표시
3. 금액/제목 입력
4. '저장' 버튼 클릭
   → 버튼 즉시 비활성화
   → ProgressBar 표시
5. API 호출 (1-2초)
6. 저장 성공
   → '저장 완료' 토스트
   → Activity 종료
```

#### 시나리오 2: 중복 클릭 시도
```
1-4. (위와 동일)
5. 사용자가 '저장' 버튼 다시 클릭 시도
   → 버튼이 이미 비활성화되어 있어 클릭 불가
   → 또는 isSaving 플래그로 인해 무시됨
6. 첫 번째 요청만 처리
7. 저장 성공
   → 1회만 저장됨 (중복 방지 성공)
```

#### 시나리오 3: 네트워크 에러
```
1-5. (위와 동일)
6. API 호출 실패 (네트워크 에러)
   → catch 블록 실행
   → '오류: ...' 토스트
   → resetSaveButton() 호출
7. 버튼 재활성화
   → 사용자가 다시 시도 가능
```

---

## 5. 파일 변경 목록 (File Changes)

### 5.1 수정할 파일

| 파일 경로 | 변경 유형 | 변경 내용 |
|-----------|----------|----------|
| `android/app/src/main/res/layout/widget_quick_add.xml` | 수정 | TextView (Line 39-45) 제거 |
| `android/app/src/main/res/layout/activity_quick_input.xml` | 수정 | ProgressBar 추가 (버튼 영역) |
| `android/app/src/main/kotlin/.../QuickInputActivity.kt` | 수정 | - `isSaving` 플래그 추가<br>- `progressBar` 뷰 바인딩<br>- `saveExpense()` 로직 개선<br>- `resetSaveButton()` 함수 추가 |

### 5.2 변경하지 않을 파일

- `QuickAddWidget.kt`: 위젯 동작 로직 변경 없음
- `SupabaseHelper.kt`: API 호출 로직 변경 없음
- Flutter 레벨 코드: 변경 없음

---

## 6. 테스트 계획 (Test Plan)

### 6.1 단위 테스트 시나리오

#### Test 1: 위젯 레이아웃
```
Input: 위젯 추가 후 화면 확인
Expected:
- '빠른 추가' 텍스트 없음
- 아이콘만 표시
- 레이아웃 깨지지 않음
```

#### Test 2: 저장 버튼 비활성화
```
Input: 금액 입력 후 '저장' 클릭
Expected:
- 버튼 즉시 비활성화
- ProgressBar 표시
- 버튼 색상 변경 (비활성화 스타일)
```

#### Test 3: 중복 저장 방지
```
Input:
1. 금액 입력
2. '저장' 버튼 빠르게 2번 클릭
Expected:
- 첫 번째 클릭만 처리
- 두 번째 클릭 무시
- 거래가 1회만 저장됨
```

#### Test 4: 저장 실패 시 복구
```
Input:
1. 네트워크 연결 해제
2. 금액 입력 후 '저장' 클릭
Expected:
- 에러 토스트 표시
- 버튼 재활성화
- ProgressBar 숨김
- 사용자가 다시 시도 가능
```

### 6.2 통합 테스트 시나리오

#### Test 5: 전체 플로우
```
Steps:
1. 홈 화면에서 위젯 추가
2. 위젯 클릭
3. 금액 입력
4. '저장' 클릭
5. 저장 완료 대기
6. Activity 종료
7. 가계부 앱에서 거래 확인
Expected:
- 거래가 1회만 저장됨
- 올바른 금액/날짜로 저장됨
```

### 6.3 Edge Case 테스트

#### Test 6: 빠른 연속 저장
```
Input:
1. 거래 A 저장 (버튼 클릭)
2. 즉시 위젯 재클릭
3. 거래 B 저장 (버튼 클릭)
Expected:
- 거래 A, B 모두 정상 저장
- 각 거래가 1회씩만 저장됨
```

#### Test 7: Activity 종료 중 API 응답
```
Input:
1. '저장' 클릭
2. 사용자가 '뒤로가기' 버튼 클릭 (Activity 강제 종료)
Expected:
- API 요청은 계속 진행
- Activity 종료되어도 저장 완료
- 메모리 누수 없음
```

---

## 7. 에러 핸들링 (Error Handling)

### 7.1 에러 시나리오

| 에러 상황 | 에러 메시지 | UI 동작 |
|-----------|-------------|---------|
| 금액 미입력 | '금액을 입력하세요' | Toast 표시, 버튼 유지 |
| 금액 유효성 실패 | '유효한 금액을 입력하세요' | Toast 표시, 버튼 유지 |
| 가계부 없음 | '가계부를 찾을 수 없습니다' | Toast 표시, 버튼 재활성화 |
| 로그인 만료 | '로그인이 만료되었습니다...' | Toast 표시, Activity 종료 |
| 사용자 정보 없음 | '사용자 정보를 찾을 수 없습니다' | Toast 표시, 버튼 재활성화 |
| 네트워크 에러 | '저장 실패. 네트워크를 확인해주세요' | Toast 표시, 버튼 재활성화 |
| 예외 발생 | '오류: {메시지}' | Toast 표시, 버튼 재활성화 |

### 7.2 에러 복구 전략

```kotlin
// 에러 발생 시 공통 처리
private fun handleError(message: String, shouldFinish: Boolean = false) {
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show()

    if (shouldFinish) {
        finish()
    } else {
        resetSaveButton()
    }
}
```

---

## 8. 성능 고려사항 (Performance Considerations)

### 8.1 메모리 관리

- ProgressBar는 `visibility="gone"`으로 초기화하여 메모리 절약
- Activity 종료 시 Coroutine 자동 취소 (`activityScope` 사용)
- 불필요한 View 참조 제거

### 8.2 응답성

- 버튼 클릭 즉시 UI 상태 변경 (사용자 피드백 즉각 제공)
- ProgressBar는 작은 크기(24dp)로 오버헤드 최소화

---

## 9. 구현 순서 (Implementation Order)

### Phase 1: 위젯 레이아웃 수정
1. `widget_quick_add.xml` 파일 열기
2. Line 39-45의 TextView 요소 완전 제거
3. 레이아웃 미리보기 확인
4. 빌드 및 위젯 업데이트 테스트

### Phase 2: 입력 다이얼로그 레이아웃 수정
1. `activity_quick_input.xml` 파일 열기
2. 버튼 영역을 RelativeLayout으로 감싸기
3. ProgressBar 요소 추가 (Line 50-79 참고)
4. 레이아웃 미리보기 확인

### Phase 3: Activity 로직 수정
1. `QuickInputActivity.kt` 파일 열기
2. `isSaving` 플래그 추가 (클래스 레벨)
3. `progressBar` 뷰 바인딩 추가 (`onCreate`)
4. `saveExpense()` 메서드 수정:
   - 시작 부분에 UI 상태 변경 추가
   - 각 에러 핸들링 블록에 `resetSaveButton()` 호출 추가
5. `resetSaveButton()` 함수 추가
6. `setOnClickListener`에 중복 클릭 방지 로직 추가

### Phase 4: 테스트 및 검증
1. 위젯 레이아웃 테스트 (다양한 화면 크기)
2. 중복 저장 방지 테스트 (버튼 빠르게 2번 클릭)
3. 네트워크 에러 시나리오 테스트
4. 전체 플로우 테스트

---

## 10. 롤백 계획 (Rollback Plan)

### 10.1 문제 발생 시 대응

| 문제 상황 | 롤백 방법 | 예상 시간 |
|-----------|----------|----------|
| 위젯 레이아웃 깨짐 | `widget_quick_add.xml` Git revert | 5분 |
| 버튼 비활성화 후 복구 안됨 | `QuickInputActivity.kt` Git revert | 5분 |
| ProgressBar 표시 오류 | `activity_quick_input.xml` Git revert | 5분 |

### 10.2 Git 커밋 전략

```bash
# 각 Phase별로 별도 커밋
git commit -m "feat(widget): 홈 화면 위젯 '빠른 추가' 텍스트 제거"
git commit -m "feat(widget): 저장 버튼 중복 클릭 방지 및 로딩 표시 추가"
```

---

## 11. 문서 참조 (References)

### 11.1 관련 파일

- **Plan 문서**: `docs/01-plan/features/widget-ui-improvement.plan.md`
- **CLAUDE.md**: 프로젝트 개요 및 위젯 기능 설명
- **Android Widget 가이드**: https://developer.android.com/develop/ui/views/appwidgets

### 11.2 관련 이슈

- 위젯 텍스트 잘림 현상 (사용자 피드백)
- 중복 저장 문제 (사용자 피드백)

---

## 12. 체크리스트 (Checklist)

### 12.1 구현 전 확인사항

- [x] Plan 문서 검토 완료
- [x] 파일 경로 확인
- [x] 변경 범위 명확화
- [x] 테스트 계획 수립

### 12.2 구현 중 확인사항

- [ ] 위젯 레이아웃 수정 완료
- [ ] 입력 다이얼로그 레이아웃 수정 완료
- [ ] Activity 로직 수정 완료
- [ ] 코드 포맷팅 (dart format)

### 12.3 구현 후 확인사항

- [ ] 단위 테스트 통과 (Test 1-4)
- [ ] 통합 테스트 통과 (Test 5)
- [ ] Edge Case 테스트 통과 (Test 6-7)
- [ ] 코드 리뷰 완료

---

**Design 문서 작성 완료**
작성일: 2026-02-02

**다음 단계**: `/pdca do widget-ui-improvement` 명령으로 구현 시작
