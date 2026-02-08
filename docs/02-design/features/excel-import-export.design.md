# 웹 거래 페이지 기능 Design Document

> **Summary**: 웹 거래 페이지에 엑셀 내보내기/가져오기, 검색/필터, 거래 추가 기능의 상세 설계
>
> **Project**: shared_household_account
> **Version**: 1.0.0+1
> **Author**: eungyu
> **Date**: 2026-02-08
> **Status**: Draft
> **Planning Doc**: [excel-import-export.plan.md](../../01-plan/features/excel-import-export.plan.md)

---

## 1. Overview

### 1.1 Design Goals

- 기존 웹 거래 페이지(`ledger-client.tsx`)에 내보내기/가져오기/거래추가 기능을 통합
- house.pen 디자인 노드(J8rAe, 5K1SN, 8545T, 8dQwI, SoCvj)와 정확히 일치하는 UI
- 기존 코드 패턴(Next.js 15 + Supabase + TailwindCSS + useState) 준수
- Flutter 앱의 엑셀 내보내기/가져오기 서비스를 독립적으로 구현

### 1.2 Design Principles

- 기존 `LedgerClient` 컴포넌트를 확장하여 기능 추가 (새 페이지 생성 최소화)
- Server Action과 Client Component의 역할 분리 유지
- Supabase 클라이언트 직접 사용 패턴 유지 (기존 `fetchData` 함수 패턴)
- 다이얼로그 기반 UX (기존 `Dialog` 컴포넌트 활용)

---

## 2. Architecture

### 2.1 Component Diagram

```
┌──────────────────────────────────────────────────────────────┐
│  LedgerClient (기존, 확장)                                    │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Header: "거래 내역" + btnGroup(SoCvj)                   │ │
│  │  ┌─────────┐ ┌─────────┐ ┌──────────────┐              │ │
│  │  │내보내기  │ │가져오기  │ │ + 거래 추가   │              │ │
│  │  └────┬────┘ └────┬────┘ └──────┬───────┘              │ │
│  │       │           │             │                       │ │
│  │  ┌────▼────┐ ┌────▼────┐ ┌─────▼──────┐               │ │
│  │  │Export   │ │Import   │ │AddTx       │               │ │
│  │  │Panel   │ │Panel   │ │Dialog      │               │ │
│  │  │(J8rAe) │ │(5K1SN) │ │(8545T)     │               │ │
│  │  └────────┘ └────────┘ └────────────┘               │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │  Summary Cards (수입/지출/잔액)                           │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │  Transaction List Card                                  │ │
│  │  ┌───────────────────────────────────────────────────┐ │ │
│  │  │  거래 아이템 목록                                   │ │ │
│  │  ├───────────────────────────────────────────────────┤ │ │
│  │  │  filterRow (8dQwI): 날짜 필터 + 유형 탭             │ │ │
│  │  └───────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

```
[내보내기]
사용자 옵션 선택 → Supabase 거래 조회 → 데이터 변환 → xlsx/csv 생성 → 다운로드

[가져오기]
파일 선택 → 파싱(xlsx/csv) → 컬럼 매핑 → 중복 감지 → 미리보기 → Supabase 일괄 저장

[거래 추가]
폼 입력 → 유효성 검증 → Server Action(addTransaction) → revalidatePath → 목록 갱신

[검색/필터]
월 변경/유형 선택 → fetchData(year, month) → 클라이언트 필터링 → 목록 갱신
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| ExportPanel | `supabase/client`, `xlsx` (npm) | 거래 조회 + 엑셀 생성 |
| ImportPanel | `xlsx` (npm) | 파일 파싱 + 컬럼 매핑 |
| AddTransactionDialog | `addTransaction` Server Action, `getCategories`, `getPaymentMethods` | 거래 생성 |
| TransactionFilter | `LedgerClient` state | 필터 상태 관리 |

---

## 3. Data Model

### 3.1 기존 타입 (재사용)

```typescript
// web/lib/types/database.ts (기존)
type Transaction = Database['house']['Tables']['transactions']['Row'];
type TransactionInsert = Database['house']['Tables']['transactions']['Insert'];
type Category = Database['house']['Tables']['categories']['Row'];
type PaymentMethod = Database['house']['Tables']['payment_methods']['Row'];
```

### 3.2 신규 타입 정의

```typescript
// web/lib/types/excel.ts (신규)

// 내보내기 옵션
interface ExportOptions {
  startDate: string;          // YYYY-MM-DD
  endDate: string;            // YYYY-MM-DD
  transactionType: 'all' | 'income' | 'expense' | 'asset';
  includeCategory: boolean;
  includePaymentMethod: boolean;
  includeMemo: boolean;
  includeAuthor: boolean;
  includeFixedExpense: boolean;
  fileFormat: 'xlsx' | 'csv';
}

// 가져오기 매핑 결과
interface ColumnMapping {
  date: number | null;        // 엑셀 컬럼 인덱스
  type: number | null;
  amount: number | null;
  description: number | null;
  category: number | null;
  paymentMethod: number | null;
  memo: number | null;
}

// 가져오기 미리보기 행
interface ImportPreviewRow {
  rowIndex: number;
  date: string;
  type: 'income' | 'expense' | 'asset';
  amount: number;
  description: string;
  category?: string;
  paymentMethod?: string;
  memo?: string;
  isDuplicate: boolean;
  error?: string;
}

// 가져오기 옵션
interface ImportOptions {
  createMissingCategories: boolean;
  matchPaymentMethods: boolean;
  previewBeforeImport: boolean;
}

// 가져오기 결과
interface ImportResult {
  total: number;
  success: number;
  skipped: number;      // 중복
  failed: number;
  errors: { row: number; message: string }[];
}

// 거래 추가 폼 데이터
interface AddTransactionFormData {
  type: 'income' | 'expense' | 'asset';
  amount: number;
  description: string;
  date: string;
  categoryId: string | null;
  paymentMethodId: string | null;
  isRecurring: boolean;
  isFixedExpense: boolean;
  memo: string;
}
```

---

## 4. API Specification

### 4.1 기존 API 활용

| 용도 | 파일 | 함수 |
|------|------|------|
| 거래 조회 (내보내기) | `lib/queries/transaction.ts` | `getTransactions(ledgerId, { year, month, type })` |
| 거래 생성 (추가/가져오기) | `lib/actions/transaction.ts` | `addTransaction(formData)` |
| 카테고리 조회 | `lib/queries/category.ts` | `getCategories(ledgerId, type?)` |
| 결제수단 조회 | `lib/queries/payment-method.ts` | `getPaymentMethods(ledgerId)` |

### 4.2 신규 Server Action

```typescript
// web/lib/actions/excel.ts (신규)

// 일괄 가져오기 (배치 insert, 이름 기반 카테고리/결제수단 매핑)
export async function importTransactions(
  ledgerId: string,
  transactions: {
    type: 'income' | 'expense' | 'asset';
    amount: number;
    description: string;
    date: string;
    categoryName?: string;
    paymentMethodName?: string;
    memo?: string;
  }[],
  options: {
    createMissingCategories: boolean;
    matchPaymentMethods: boolean;
  }
): Promise<ImportResult>

// 내보내기는 ExportPanel에서 Supabase 클라이언트 직접 조회로 처리
// (별도 Server Action 불필요 - 조회 전용이므로 클라이언트 직접 접근이 효율적)
```

### 4.3 기존 addTransaction Server Action 확장 필요 없음

기존 `addTransaction`은 FormData 기반이므로, 거래 추가 다이얼로그에서 그대로 활용 가능.

가져오기의 일괄 저장은 별도 `importTransactions` Server Action으로 처리 (배치 insert 성능 최적화).

---

## 5. UI/UX Design

### 5.1 Screen Layout (기존 LedgerClient 확장)

```
┌────────────────────────────────────────────────────────────┐
│  Header                                                     │
│  "거래 내역"          [내보내기] [가져오기] [+ 거래 추가]     │
├────────────────────────────────────────────────────────────┤
│  Summary Cards                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                   │
│  │ 수입     │ │ 지출     │ │ 합계     │                   │
│  └──────────┘ └──────────┘ └──────────┘                   │
├────────────────────────────────────────────────────────────┤
│  Transaction List Card (rounded-[16px] border bg-white)    │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ 거래 아이템 1 (icon | title/date/category | amount)  │ │
│  │ 거래 아이템 2                                         │ │
│  │ ...                                                   │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │ [<] 2026년 2월 [>]           [전체] [수입] [지출]     │ │
│  └──────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

### 5.2 User Flow

```
[내보내기 플로우]
헤더 '내보내기' 클릭
→ ExportPanel 다이얼로그 오픈
→ 기간/유형/포함항목/형식 설정
→ '내보내기' 버튼 클릭
→ 파일 생성 + 브라우저 다운로드
→ 성공 토스트 표시

[가져오기 플로우]
헤더 '가져오기' 클릭
→ ImportPanel 다이얼로그 오픈
→ 파일 드래그 또는 선택
→ 자동 컬럼 매핑 표시
→ 옵션 설정 (미분류 카테고리 생성 등)
→ '가져오기' 버튼 클릭
→ 결과 요약 표시
→ 거래 목록 갱신

[거래 추가 플로우]
헤더 '+ 거래 추가' 클릭
→ AddTransactionDialog 다이얼로그 오픈
→ 유형 탭 선택 (지출/수입/자산)
→ 금액, 제목, 날짜, 카테고리, 결제수단 입력
→ 옵션 설정 (할부/반복/고정비)
→ 메모 입력 (선택)
→ '저장' 클릭
→ Server Action 호출
→ 성공 토스트 + 거래 목록 갱신
```

### 5.3 Component List

| Component | Location | Responsibility | Design Node |
|-----------|----------|----------------|-------------|
| `ExportPanel` | `web/components/transaction/ExportPanel.tsx` | 내보내기 다이얼로그 | J8rAe |
| `ImportPanel` | `web/components/transaction/ImportPanel.tsx` | 가져오기 다이얼로그 | 5K1SN |
| `AddTransactionDialog` | `web/components/transaction/AddTransactionDialog.tsx` | 거래 추가 다이얼로그 | 8545T |

---

## 6. Component Detailed Design

### 6.1 ExportPanel (J8rAe)

**Props:**
```typescript
interface ExportPanelProps {
  open: boolean;
  onClose: () => void;
  ledgerId: string;
}
```

**내부 상태:**
```typescript
const [startDate, setStartDate] = useState<string>('');    // YYYY-MM-DD
const [endDate, setEndDate] = useState<string>('');
const [txType, setTxType] = useState<'all' | 'income' | 'expense' | 'asset'>('all');
const [includeFields, setIncludeFields] = useState({
  category: true, paymentMethod: true, memo: true, author: false, fixedExpense: true,
});
const [fileFormat, setFileFormat] = useState<'xlsx' | 'csv'>('xlsx');
const [exporting, setExporting] = useState(false);
```

**빠른 기간 선택 버튼:**
- 이번 달: 현재 월 1일 ~ 마지막일
- 지난 달: 이전 월 1일 ~ 마지막일
- 최근 3개월: 3개월 전 1일 ~ 오늘
- 올해 전체: 1월 1일 ~ 12월 31일

**내보내기 로직:**
```typescript
const handleExport = async () => {
  setExporting(true);
  try {
    // 1. Supabase에서 거래 데이터 조회
    const supabase = createClient();
    const { data } = await supabase
      .from('transactions')
      .select('*, categories(name), payment_methods(name), profiles(display_name)')
      .eq('ledger_id', ledgerId)
      .gte('date', startDate)
      .lte('date', endDate)
      .order('date', { ascending: true });

    // 2. 유형 필터링
    const filtered = txType === 'all'
      ? data
      : data?.filter(t => t.type === txType);

    // 3. xlsx 또는 csv 생성 (xlsx 라이브러리 사용)
    if (fileFormat === 'xlsx') {
      exportToXlsx(filtered, includeFields);
    } else {
      exportToCsv(filtered, includeFields);
    }
  } finally {
    setExporting(false);
  }
};
```

**스타일 매핑 (house.pen J8rAe -> TailwindCSS):**
```
exportPanel: w-[480px] rounded-[20px] bg-white
exportHeader: px-6 py-[18px] border-b border-card-border
  제목: text-lg font-semibold
  닫기: w-8 h-8 bg-[#F5F5F5] rounded-full
exportBody: p-6 flex flex-col gap-5
  섹션 라벨: text-sm font-semibold text-on-surface
  날짜 입력: rounded-[10px] border border-outline px-3.5 py-3
  빠른 선택: rounded-lg px-3 py-1.5 text-xs
    선택됨: bg-primary text-white
    비선택: bg-tab-bg text-on-surface-variant
  유형 칩: rounded-full px-3.5 py-2 text-[13px]
    선택됨: bg-primary text-white
    비선택: border border-outline
  체크박스: w-5 h-5 rounded bg-primary (체크 시)
  파일형식: rounded-[10px] border p-3 flex-col items-center
    선택됨: bg-primary/5 border-primary border-[1.5px]
    비선택: border border-outline
exportFooter: px-6 py-4 border-t border-card-border gap-3
  취소: border border-outline rounded-xl py-3.5
  내보내기: bg-primary rounded-xl py-3.5 text-white font-semibold
```

### 6.2 ImportPanel (5K1SN)

**Props:**
```typescript
interface ImportPanelProps {
  open: boolean;
  onClose: () => void;
  ledgerId: string;
  onSuccess: () => void;  // 가져오기 성공 시 거래 목록 갱신 콜백
}
```

**내부 상태:**
```typescript
const [file, setFile] = useState<File | null>(null);
const [preview, setPreview] = useState<ImportPreviewRow[]>([]);
const [columnMapping, setColumnMapping] = useState<ColumnMapping | null>(null);
const [importOptions, setImportOptions] = useState<ImportOptions>({
  createMissingCategories: true,
  matchPaymentMethods: true,
  previewBeforeImport: true,
});
const [importing, setImporting] = useState(false);
const [result, setResult] = useState<ImportResult | null>(null);
```

**드래그 앤 드롭 영역:**
```
dropZone: h-40 rounded-xl bg-[#F8FAF8] border-[1.5px] border-dashed border-primary
  flex flex-col items-center justify-center gap-3
  아이콘: cloud-upload (40x40, primary)
  텍스트: "파일을 여기에 드래그하거나"
  링크: "파일 선택하기" (primary, font-semibold)
  서브: ".xlsx, .csv 파일 지원 (최대 10MB)" (text-xs, text-on-surface-variant)
```

**컬럼 매핑 UI:**
```
mappingSection: gap-2.5
  "데이터 매핑 설정" 라벨
  "파일을 업로드하면 자동으로 열을 매핑합니다." 설명
  매핑 항목: [날짜 →] [A열: date]
             [금액 →] [C열: amount]
```

**경고 섹션:**
```
warnSection: rounded-[10px] bg-[#FFF8E1] p-3 gap-2.5
  아이콘: triangle-alert (#F9A825)
  제목: "가져오기 전 확인사항" (text-[#E65100] font-semibold)
  - 중복 거래는 자동으로 건너뜁니다
  - 가져오기 후 거래 내역에서 확인할 수 있습니다
```

### 6.3 AddTransactionDialog (8545T)

**Props:**
```typescript
interface AddTransactionDialogProps {
  open: boolean;
  onClose: () => void;
  ledgerId: string;
  onSuccess: () => void;
  // categories/paymentMethods는 컴포넌트 내부에서 useEffect로 로드
}
```

**내부 상태 (useState 직접 관리):**
```typescript
const [type, setType] = useState<TransactionType>('expense');
const [amount, setAmount] = useState('');
const [description, setDescription] = useState('');
const [date, setDate] = useState(todayString);
const [categoryId, setCategoryId] = useState<string | null>(null);
const [paymentMethodId, setPaymentMethodId] = useState<string | null>(null);
const [memo, setMemo] = useState('');
const [isRecurring, setIsRecurring] = useState(false);
const [isFixedExpense, setIsFixedExpense] = useState(false);
const [saving, setSaving] = useState(false);
```

**스타일 매핑 (house.pen 8545T -> TailwindCSS):**
```
dialogPanel: w-[580px] max-h-[860px] rounded-[20px] bg-white overflow-hidden
dialogHeader: px-6 py-[18px] border-b border-card-border flex justify-between
  "거래 추가": text-lg font-semibold
  closeBtn: w-8 h-8 rounded-full bg-[#F5F5F5]
dialogBody: p-6 flex flex-col gap-5 overflow-y-auto
  typeSelector: rounded-xl bg-tab-bg p-1 gap-1 flex
    선택 탭: rounded-[10px] bg-primary text-white py-2.5 font-semibold flex-1
    비선택 탭: rounded-[10px] text-on-surface-variant py-2.5 font-medium flex-1
  amountSection: rounded-[14px] bg-surface p-5/6 flex flex-col gap-1.5
    "금액" 라벨: text-xs font-medium text-on-surface-variant
    금액 값: text-[32px] font-bold
      지출: text-expense (#BA1A1A)
      수입: text-income (#2E7D32)
    "원" 단위: text-lg font-medium text-on-surface-variant
  titleField / dateField:
    라벨: text-[13px] font-medium text-on-surface-variant
    입력: rounded-[10px] border border-outline px-3.5 py-3 text-sm
  categorySection / paymentSection:
    칩: rounded-full px-3.5 py-2 text-[13px] gap-1.5
      선택됨: bg-primary text-white (아이콘 포함)
      비선택: border border-outline
    "더보기" 칩: border border-outline text-on-surface-variant
  optionsRow: gap-3
    토글 카드: rounded-[10px] border border-outline px-3.5 py-3 flex justify-between
      off: bg-transparent
      on (고정비): bg-[#E8F5E9] border-primary
    토글 스위치: w-10 h-[22px] rounded-full
      off: bg-[#E0E0E0] knob-left
      on: bg-primary knob-right
  memoSection:
    텍스트 영역: h-[72px] rounded-[10px] border border-outline px-3.5 py-3
dialogFooter: px-6 py-4 border-t border-card-border gap-3 flex
  취소: flex-1 border border-outline rounded-xl py-3.5 text-on-surface-variant
  저장: flex-1 bg-primary rounded-xl py-3.5 text-white font-semibold
```

**카테고리/결제수단 로딩:**
```typescript
// LedgerClient에서 props로 전달하거나, 다이얼로그 오픈 시 클라이언트에서 조회
useEffect(() => {
  if (open) {
    const supabase = createClient();
    // 카테고리 조회
    supabase.from('categories').select('*').eq('ledger_id', ledgerId)
      .eq('type', form.watch('type')).then(({ data }) => setCategories(data));
    // 결제수단 조회
    supabase.from('payment_methods').select('*').eq('ledger_id', ledgerId)
      .then(({ data }) => setPaymentMethods(data));
  }
}, [open, form.watch('type')]);
```

**저장 로직:**
```typescript
const handleSubmit = async (data: AddTransactionForm) => {
  const formData = new FormData();
  formData.set('ledger_id', ledgerId);
  formData.set('type', data.type);
  formData.set('amount', String(data.amount));
  formData.set('description', data.description);
  formData.set('date', data.date);
  if (data.categoryId) formData.set('category_id', data.categoryId);
  if (data.paymentMethodId) formData.set('payment_method_id', data.paymentMethodId);
  if (data.memo) formData.set('memo', data.memo);

  const result = await addTransaction(formData);
  if (result.success) {
    onSuccess();
    onClose();
  }
};
```

---

## 7. Error Handling

### 7.1 Error Scenarios

| Scenario | Handling | UI Feedback |
|----------|----------|-------------|
| 내보내기 - 거래 0건 | 경고 표시 | "선택한 기간에 거래가 없습니다" 토스트 |
| 내보내기 - 네트워크 오류 | catch + 재시도 | "내보내기에 실패했습니다. 다시 시도해주세요" 토스트 |
| 가져오기 - 파일 형식 오류 | 파일 검증 | "지원하지 않는 파일 형식입니다" 토스트 |
| 가져오기 - 파일 크기 초과 | 10MB 제한 | "파일 크기가 10MB를 초과합니다" 토스트 |
| 가져오기 - 필수 컬럼 매핑 실패 | 매핑 검증 | 매핑 UI에서 빨간색 표시 |
| 가져오기 - 부분 실패 | 결과 요약 | ImportResult로 성공/실패/건너뜀 건수 표시 |
| 거래 추가 - 필수값 누락 | react-hook-form 검증 | 필드별 에러 메시지 |
| 거래 추가 - 저장 실패 | Server Action error | "저장에 실패했습니다" 토스트 |

---

## 8. Security Considerations

- [x] 입력 유효성 검증: 금액은 양의 정수, 날짜는 유효한 날짜 형식
- [x] Supabase RLS: 기존 RLS 정책으로 본인 가계부 거래만 접근 가능
- [x] 파일 업로드 검증: 확장자(.xlsx, .csv), 크기(10MB), MIME 타입 체크
- [x] XSS 방지: React의 기본 이스케이핑 활용, 가져오기 데이터 sanitize
- [x] HTTPS: Next.js 배포 환경에서 기본 적용

---

## 9. Clean Architecture

### 9.1 Layer Structure (웹 버전)

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Presentation** | UI 컴포넌트, 사용자 상호작용 | `web/components/transaction/`, `web/app/(main)/ledger/` |
| **Application** | 비즈니스 로직, 상태 관리 | `web/lib/actions/`, `web/lib/hooks/` |
| **Domain** | 타입 정의, 엔티티 | `web/lib/types/` |
| **Infrastructure** | Supabase 클라이언트, 외부 라이브러리 | `web/lib/supabase/`, `web/lib/utils/` |

### 9.2 This Feature's Layer Assignment

| Component | Layer | Location |
|-----------|-------|----------|
| `ExportPanel` | Presentation | `web/components/transaction/ExportPanel.tsx` |
| `ImportPanel` | Presentation | `web/components/transaction/ImportPanel.tsx` |
| `AddTransactionDialog` | Presentation | `web/components/transaction/AddTransactionDialog.tsx` |
| `importTransactions` | Application | `web/lib/actions/excel.ts` |
| 내보내기 조회 | Presentation (클라이언트 직접) | `ExportPanel.tsx` 내부 |
| `ExportOptions`, `ImportResult` 등 | Domain | `web/lib/types/excel.ts` |
| `excelExport`, `excelImport` utils | Infrastructure | `web/lib/utils/excel.ts` |

---

## 10. Coding Convention

### 10.1 기존 프로젝트 컨벤션 준수

| Item | Convention |
|------|-----------|
| Component naming | PascalCase (`ExportPanel`, `AddTransactionDialog`) |
| File naming | PascalCase.tsx (컴포넌트), camelCase.ts (유틸) |
| 문자열 | 작은따옴표 (`'`) |
| CSS | TailwindCSS + `cn()` 유틸리티 |
| 상태관리 | useState (클라이언트/폼 모두) |
| API 호출 | Server Action (mutation), Supabase client (query) |
| 에러 처리 | throw + catch, 토스트로 사용자 피드백 |
| Import order | 외부 -> @/ -> 상대 -> 타입 |

### 10.2 신규 npm 패키지

```bash
cd web && npm install xlsx
```

> `xlsx` (SheetJS): 브라우저에서 엑셀 파일 생성/파싱. 번들 크기 최적화를 위해 동적 import 사용.

---

## 11. Implementation Guide

### 11.1 File Structure (신규 파일만)

```
web/
├── components/
│   └── transaction/
│       ├── ExportPanel.tsx            # 내보내기 다이얼로그 (J8rAe)
│       ├── ImportPanel.tsx            # 가져오기 다이얼로그 (5K1SN)
│       └── AddTransactionDialog.tsx   # 거래 추가 다이얼로그 (8545T)
├── lib/
│   ├── types/
│   │   └── excel.ts                  # 내보내기/가져오기 관련 타입
│   ├── actions/
│   │   └── excel.ts                  # 일괄 가져오기 Server Action
│   └── utils/
│       └── excel.ts                  # xlsx 생성/파싱 유틸리티
└── app/
    └── (main)/
        └── ledger/
            └── ledger-client.tsx      # 기존 파일 수정 (버튼 연동)
```

### 11.2 Implementation Order

1. [ ] **타입 정의**: `web/lib/types/excel.ts` - ExportOptions, ImportResult, AddTransactionForm 등
2. [ ] **엑셀 유틸리티**: `web/lib/utils/excel.ts` - xlsx 생성/파싱 순수 함수
3. [ ] **Server Action**: `web/lib/actions/excel.ts` - importTransactions 배치 저장
4. [ ] **AddTransactionDialog**: `web/components/transaction/AddTransactionDialog.tsx` - 거래 추가 UI
5. [ ] **ExportPanel**: `web/components/transaction/ExportPanel.tsx` - 내보내기 UI
6. [ ] **ImportPanel**: `web/components/transaction/ImportPanel.tsx` - 가져오기 UI
7. [ ] **LedgerClient 수정**: `web/app/(main)/ledger/ledger-client.tsx` - 버튼 연동, 다이얼로그 통합
8. [ ] **테스트**: 단위 테스트 + 수동 테스트

### 11.3 LedgerClient 수정 범위

기존 `ledger-client.tsx`에서 변경할 부분:

```typescript
// 1. Import 추가
import { ExportPanel } from '@/components/transaction/ExportPanel';
import { ImportPanel } from '@/components/transaction/ImportPanel';
import { AddTransactionDialog } from '@/components/transaction/AddTransactionDialog';
import { Download, Upload } from 'lucide-react';

// 2. 다이얼로그 상태 추가
const [exportOpen, setExportOpen] = useState(false);
const [importOpen, setImportOpen] = useState(false);
const [addTxOpen, setAddTxOpen] = useState(false);

// 3. Header 버튼 그룹 변경 (내보내기/가져오기는 아이콘 버튼, 거래추가는 텍스트 포함)
<div className='flex items-center gap-2'>
  <button onClick={() => setExportOpen(true)}
    className='flex h-9 w-9 items-center justify-center rounded-[8px] bg-tab-bg text-on-surface-variant'
    title='내보내기'>
    <Download size={16} />
  </button>
  <button onClick={() => setImportOpen(true)}
    className='flex h-9 w-9 items-center justify-center rounded-[8px] bg-tab-bg text-on-surface-variant'
    title='가져오기'>
    <Upload size={16} />
  </button>
  <button onClick={() => setAddTxOpen(true)}
    className='flex items-center gap-2 rounded-[10px] bg-primary px-4 py-2 text-sm font-semibold text-white'>
    <Plus size={16} /> 거래 추가
  </button>
</div>

// 4. 다이얼로그 컴포넌트 렌더링
<ExportPanel open={exportOpen} onClose={() => setExportOpen(false)} ledgerId={ledgerId} />
<ImportPanel open={importOpen} onClose={() => setImportOpen(false)} ledgerId={ledgerId}
  onSuccess={() => fetchData(year, month)} />
<AddTransactionDialog open={addDialogOpen} onClose={() => setAddDialogOpen(false)} ledgerId={ledgerId}
  onSuccess={() => fetchData(year, month)} />
```

---

## 12. Excel Export/Import Logic (Flutter 앱)

### 12.1 Flutter ExcelExportService

```dart
// lib/features/transaction/data/services/excel_export_service.dart

class ExcelExportService {
  final TransactionRepository _transactionRepository;

  Future<String> exportToXlsx({
    required String ledgerId,
    required ExportOptions options,
  }) async {
    // 1. 기간별 거래 조회
    final transactions = await _transactionRepository
        .getTransactionsByDateRange(
          ledgerId: ledgerId,
          startDate: options.startDate,
          endDate: options.endDate,
        );

    // 2. 유형 필터링
    final filtered = options.type == 'all'
        ? transactions
        : transactions.where((t) => t.type == options.type).toList();

    // 3. Excel 생성 (excel 패키지)
    final excel = Excel.createExcel();
    final sheet = excel['거래내역'];

    // 헤더 행
    final headers = ['날짜', '유형', '금액', '제목'];
    if (options.includeCategory) headers.add('카테고리');
    if (options.includePaymentMethod) headers.add('결제수단');
    if (options.includeMemo) headers.add('메모');
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // 데이터 행
    for (final tx in filtered) {
      final row = [
        TextCellValue(tx.date.toIso8601String().split('T').first),
        TextCellValue(tx.type == 'income' ? '수입' : tx.type == 'expense' ? '지출' : '자산'),
        IntCellValue(tx.amount),
        TextCellValue(tx.title ?? ''),
      ];
      if (options.includeCategory) row.add(TextCellValue(tx.categoryName ?? ''));
      if (options.includePaymentMethod) row.add(TextCellValue(tx.paymentMethodName ?? ''));
      if (options.includeMemo) row.add(TextCellValue(tx.memo ?? ''));
      sheet.appendRow(row);
    }

    // 4. 파일 저장
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/거래내역_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
    return filePath;
  }
}
```

### 12.2 Flutter ExcelImportService

```dart
// lib/features/transaction/data/services/excel_import_service.dart

class ExcelImportService {
  Future<List<Map<String, dynamic>>> parseXlsx(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;

    // 헤더 감지 및 자동 매핑
    final headers = sheet.rows.first.map((c) => c?.value?.toString() ?? '').toList();
    final mapping = _autoMapColumns(headers);

    // 데이터 파싱
    final results = <Map<String, dynamic>>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      results.add(_parseRow(row, mapping));
    }
    return results;
  }

  ColumnMapping _autoMapColumns(List<String> headers) {
    // 한국어/영어 컬럼명 자동 매핑
    final datePatterns = ['날짜', 'date', '일자'];
    final amountPatterns = ['금액', 'amount', '가격'];
    // ... 각 필드별 패턴 매칭
  }
}
```

---

## 13. Test Plan

### 13.1 Test Scope

| Type | Target | Tool |
|------|--------|------|
| Unit Test | excel.ts 유틸리티 (생성/파싱) | Vitest |
| Unit Test | importTransactions Server Action | Vitest |
| Unit Test | ExcelExportService (Flutter) | flutter_test |
| Unit Test | ExcelImportService (Flutter) | flutter_test |
| Component Test | AddTransactionDialog 렌더링/폼 검증 | @testing-library/react |
| E2E Test | 내보내기/가져오기 전체 플로우 | 수동 테스트 |

### 13.2 Test Cases

- [ ] Happy path: 이번 달 전체 거래를 .xlsx로 내보내고, 파일이 정상 다운로드됨
- [ ] Happy path: .xlsx 파일을 가져와서 10건 중 8건 성공, 2건 중복 건너뜀
- [ ] Happy path: 지출 45,000원 거래를 추가하고, 목록에 즉시 반영됨
- [ ] Error: 빈 기간 내보내기 시 "거래가 없습니다" 표시
- [ ] Error: 10MB 초과 파일 가져오기 시 에러 메시지
- [ ] Error: 필수 필드(금액, 제목) 미입력 시 폼 검증 에러
- [ ] Edge case: CSV 파일에 콤마가 포함된 제목 정상 처리
- [ ] Edge case: 날짜 형식 다양한 케이스 (YYYY-MM-DD, YYYY/MM/DD, MM/DD/YYYY)
- [ ] Edge case: 금액에 콤마, "원", "-" 기호 포함 시 정상 파싱

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-08 | 초안 작성 | eungyu |
| 0.2 | 2026-02-08 | Gap 분석 기반 동기화: AddTransactionForm->FormData, onImportComplete->onSuccess, react-hook-form->useState, getTransactionsForExport 제거, 헤더 버튼 스타일 업데이트 | Claude Code |
