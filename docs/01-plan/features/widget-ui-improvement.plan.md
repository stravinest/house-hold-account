# Plan: 홈 화면 위젯 UI 개선 및 중복 저장 방지

**Feature ID**: `widget-ui-improvement`
**작성일**: 2026-02-02
**작성자**: AI Assistant
**PDCA Phase**: Plan

---

## 1. 문제 정의 (Problem Statement)

### 1.1 현상 분석

현재 프로젝트의 홈 화면 위젯에서 다음과 같은 문제가 발견되었습니다:

1. **'빠른 추가' 문구 잘림 현상**
   - `widget_quick_add.xml`의 TextView에서 '빠른 추가' 텍스트가 화면에 잘리는 현상 발생
   - 위젯 크기에 따라 텍스트가 불완전하게 표시됨
   - 사용자가 위젯의 용도를 명확히 파악하기 어려움

2. **중복 저장 문제**
   - 위젯 클릭 → 금액 입력 창 표시 → 저장 버튼 클릭
   - 저장 처리 시간이 약 1-2초 소요되지만 UI 피드백 없음
   - 사용자가 저장 중인지 알 수 없어 버튼을 다시 클릭
   - 결과적으로 동일한 거래가 2번 저장됨

### 1.2 코드 분석

**위젯 레이아웃 (`widget_quick_add.xml`)**:
```xml
<TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="빠른 추가"
    android:textSize="10sp"
    android:textStyle="bold"
    android:textColor="#212121" />
```

**문제점**:
- 텍스트가 위젯 하단에 위치하여 화면 잘림 가능성 높음
- 텍스트 크기 10sp로 작아서 가독성도 낮음

**저장 처리 코드 (`QuickInputActivity.kt:50-57, 59-117`)**:
```kotlin
saveButton.setOnClickListener {
    saveExpense()
}

private fun saveExpense() {
    // ... 유효성 검증
    activityScope.launch {
        // Supabase API 호출 (1-2초 소요)
        val success = supabaseHelper.createExpenseTransaction(...)
        if (success) {
            Toast.makeText(this@QuickInputActivity, "저장 완료", Toast.LENGTH_SHORT).show()
            finish()
        }
    }
}
```

**문제점**:
- 저장 버튼 클릭 후 즉시 비활성화되지 않음
- 로딩 인디케이터가 표시되지 않아 진행 상태를 알 수 없음
- 사용자가 중복 클릭할 가능성 높음

---

## 2. 목표 (Objectives)

### 2.1 기능 목표

1. **위젯 UI 개선**
   - '빠른 추가' 문구 제거 (아이콘만으로 용도 전달)
   - 시각적으로 간결하고 명확한 위젯 디자인

2. **중복 저장 방지**
   - 저장 버튼 클릭 시 즉시 비활성화
   - 로딩 인디케이터 표시 (ProgressBar)
   - 저장 완료/실패 시 버튼 재활성화

3. **사용자 경험 개선**
   - 저장 진행 상태를 명확히 파악 가능
   - 예상치 못한 중복 저장 방지

### 2.2 성공 기준

- [ ] 위젯에서 '빠른 추가' 텍스트 제거 완료
- [ ] 저장 버튼 클릭 시 버튼 즉시 비활성화
- [ ] 저장 중 로딩 인디케이터 표시
- [ ] 저장 완료/실패 시 정상적으로 Activity 종료 또는 버튼 재활성화
- [ ] 중복 저장 시나리오에서 1회만 저장됨 확인

---

## 3. 범위 (Scope)

### 3.1 포함 사항 (In Scope)

1. **위젯 레이아웃 수정**
   - `widget_quick_add.xml`에서 TextView 제거
   - 아이콘과 버튼만으로 구성
   - 레이아웃 최적화

2. **저장 처리 로직 개선**
   - `QuickInputActivity.kt`에서 저장 버튼 비활성화 로직 추가
   - `activity_quick_input.xml`에 ProgressBar 추가
   - 저장 중 ProgressBar 표시, 버튼 비활성화
   - 저장 완료/실패 시 Activity 종료 또는 버튼 재활성화

3. **UI/UX 개선**
   - 저장 버튼 텍스트 변경: '저장' → '저장 중...' (선택사항)
   - 버튼 색상 변경으로 비활성화 상태 시각화

### 3.2 제외 사항 (Out of Scope)

1. **Flutter 레벨 개선**
   - Native Android만 수정, Flutter 코드는 변경하지 않음

2. **위젯 기능 확장**
   - 수입 추가 버튼 등 새로운 기능은 추가하지 않음

3. **디자인 시스템 전면 개편**
   - 현재 디자인 스타일 유지, 최소한의 수정만 진행

---

## 4. 기술 조사 결과 (Technical Investigation)

### 4.1 현재 위젯 구조

**widget_quick_add.xml**:
```
FrameLayout (배경)
└── LinearLayout (버튼 영역)
    ├── ImageView (앱 아이콘)
    ├── ImageView (추가 버튼 아이콘)
    └── TextView ('빠른 추가' 텍스트) <- 제거 대상
```

**해결 방안**:
- TextView 제거
- 아이콘만으로도 '거래 추가' 의도가 충분히 전달됨

### 4.2 저장 버튼 비활성화 패턴

**Android Best Practice**:
```kotlin
saveButton.setOnClickListener {
    // 1. 버튼 즉시 비활성화
    saveButton.isEnabled = false

    // 2. 로딩 표시
    progressBar.visibility = View.VISIBLE

    // 3. 비동기 작업
    activityScope.launch {
        try {
            val success = supabaseHelper.createExpenseTransaction(...)
            if (success) {
                // 4. 성공 시 Activity 종료
                finish()
            } else {
                // 5. 실패 시 버튼 재활성화
                saveButton.isEnabled = true
                progressBar.visibility = View.GONE
            }
        } catch (e: Exception) {
            // 6. 에러 시 버튼 재활성화
            saveButton.isEnabled = true
            progressBar.visibility = View.GONE
        }
    }
}
```

### 4.3 ProgressBar 추가 위치

**activity_quick_input.xml 수정안**:
```xml
<LinearLayout>
    <!-- 기존 제목, 입력 필드 -->

    <LinearLayout>
        <Button android:id="@+id/cancelButton" />
        <Button android:id="@+id/saveButton" />

        <!-- 새로 추가 -->
        <ProgressBar
            android:id="@+id/progressBar"
            android:layout_width="24dp"
            android:layout_height="24dp"
            android:layout_marginStart="8dp"
            android:visibility="gone" />
    </LinearLayout>
</LinearLayout>
```

### 4.4 기술 스택

- **Kotlin**: Android 네이티브 코드
- **Coroutines**: 비동기 처리
- **Android XML**: 레이아웃 정의

---

## 5. 구현 전략 (Implementation Strategy)

### 5.1 단계별 접근

#### Phase 1: 위젯 레이아웃 수정
1. `widget_quick_add.xml`에서 '빠른 추가' TextView 제거
2. 레이아웃 패딩 및 간격 최적화
3. 위젯 업데이트 확인

#### Phase 2: 저장 로직 개선
1. `activity_quick_input.xml`에 ProgressBar 추가
2. `QuickInputActivity.kt`에서 저장 버튼 비활성화 로직 추가
3. 저장 중 ProgressBar 표시
4. 저장 완료/실패 시 처리 개선

#### Phase 3: 테스트 및 검증
1. 위젯 레이아웃 테스트 (다양한 화면 크기)
2. 중복 저장 방지 시나리오 테스트
   - 저장 버튼 빠르게 2번 클릭 → 1회만 저장되어야 함
3. 네트워크 에러 시나리오 테스트
   - 저장 실패 시 버튼 재활성화 확인

### 5.2 리스크 및 대응 방안

| 리스크 | 영향도 | 대응 방안 |
|--------|--------|-----------|
| 위젯 레이아웃 깨짐 | 하 | 여러 화면 크기에서 테스트 |
| 버튼 비활성화 후 Activity 종료 실패 | 중 | try-catch로 에러 핸들링, finally 블록에서 버튼 재활성화 |
| ProgressBar 표시 위치 부적절 | 하 | 버튼 옆에 작은 크기로 표시 |

---

## 6. 의존성 및 제약사항 (Dependencies & Constraints)

### 6.1 의존성

1. **Android SDK**
   - ProgressBar 위젯 사용

2. **Kotlin Coroutines**
   - 비동기 작업 처리

### 6.2 제약사항

1. **Android 전용**
   - iOS 위젯은 별도 작업 필요 (현재 범위 외)

2. **기존 API 호환성**
   - Supabase API 호출 로직은 변경하지 않음

---

## 7. 타임라인 (Timeline)

| 단계 | 예상 작업량 | 순서 |
|------|-------------|------|
| Phase 1: 위젯 레이아웃 수정 | 0.5 | 1 |
| Phase 2: 저장 로직 개선 | 1 | 2 |
| Phase 3: 테스트 및 검증 | 0.5 | 3 |

---

## 8. 성과 측정 (Success Metrics)

### 8.1 정량적 지표

- [ ] 중복 저장 발생률 0% (테스트 100회 중 0회)
- [ ] 위젯 레이아웃 잘림 현상 0건

### 8.2 정성적 지표

- [ ] 사용자가 저장 진행 상태를 명확히 파악 가능
- [ ] 위젯 UI가 간결하고 직관적

---

## 9. 후속 작업 (Follow-up Tasks)

### 9.1 향후 개선 사항

1. **iOS 위젯 개선**
   - iOS 위젯에도 동일한 UI/UX 개선 적용

2. **위젯 기능 확장**
   - 수입 추가 버튼 추가
   - 월간 요약 위젯 클릭 시 통계 화면 이동

3. **저장 성공 시 애니메이션**
   - 저장 완료 시 체크 아이콘 애니메이션 표시 (선택사항)

---

## 10. 승인 및 검토 (Approval)

### 10.1 검토 항목

- [x] 문제 정의 명확성
- [x] 기술 조사 완료
- [x] 구현 전략 타당성
- [x] 리스크 대응 방안 수립

### 10.2 다음 단계

- **Design 단계**: 상세 설계 문서 작성 (`/pdca design widget-ui-improvement`)

---

**Plan 문서 작성 완료**
작성일: 2026-02-02
