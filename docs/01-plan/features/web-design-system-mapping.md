# 웹 디자인 시스템 매핑 가이드

## Flutter → Web (Tailwind CSS) 변환

현재 Flutter 앱의 디자인 시스템을 웹(Tailwind CSS + shadcn/ui)으로 일관되게 변환하는 가이드입니다.

---

## 1. 색상 토큰 매핑

### 1.1 Tailwind Config (tailwind.config.ts)

```typescript
import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: ['class'],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // Primary Colors
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
          container: 'hsl(var(--primary-container))',
          'container-foreground': 'hsl(var(--primary-container-foreground))',
        },
        // Surface Colors
        surface: {
          DEFAULT: 'hsl(var(--surface))',
          foreground: 'hsl(var(--surface-foreground))',
          container: 'hsl(var(--surface-container))',
          'container-highest': 'hsl(var(--surface-container-highest))',
        },
        // Outline
        outline: {
          DEFAULT: 'hsl(var(--outline))',
          variant: 'hsl(var(--outline-variant))',
        },
        // Semantic Colors
        income: 'hsl(var(--income))',
        expense: 'hsl(var(--expense))',
        asset: 'hsl(var(--asset))',
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
      },
      spacing: {
        xs: '4px',
        sm: '8px',
        md: '16px',
        lg: '24px',
        xl: '32px',
        xxl: '48px',
      },
      borderRadius: {
        xs: '4px',
        sm: '8px',
        md: '12px',
        lg: '16px',
        xl: '20px',
        pill: '9999px',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
};

export default config;
```

### 1.2 CSS Variables (globals.css)

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    /* Primary */
    --primary: 142 45% 32%;              /* #2E7D32 */
    --primary-foreground: 0 0% 100%;     /* #FFFFFF */
    --primary-container: 138 42% 75%;    /* #A8DAB5 */
    --primary-container-foreground: 140 100% 7%; /* #00210B */

    /* Surface */
    --surface: 60 67% 98%;               /* #FDFDF5 */
    --surface-foreground: 120 7% 10%;    /* #1A1C19 */
    --surface-container: 60 20% 93%;     /* #EFEEE6 */
    --surface-container-highest: 60 14% 88%; /* #E3E3DB */

    /* Outline */
    --outline: 84 5% 44%;                /* #74796D */
    --outline-variant: 72 7% 75%;        /* #C4C8BB */

    /* Semantic */
    --income: 142 45% 32%;               /* #2E7D32 */
    --expense: 0 75% 42%;                /* #BA1A1A */
    --asset: 180 100% 21%;               /* #006A6A */

    /* Error/Destructive */
    --destructive: 0 75% 42%;            /* #BA1A1A */
    --destructive-foreground: 0 0% 100%; /* #FFFFFF */

    /* Background */
    --background: 60 67% 98%;            /* #FDFDF5 */
    --foreground: 120 7% 10%;            /* #1A1C19 */

    /* Card */
    --card: 0 0% 100%;
    --card-foreground: 120 7% 10%;

    /* Border */
    --border: 72 7% 75%;
    --input: 60 14% 88%;

    /* Ring (Focus) */
    --ring: 142 45% 32%;
  }

  .dark {
    /* Dark Mode 색상 (추후 추가) */
    --primary: 138 42% 75%;
    --primary-foreground: 140 100% 7%;
    /* ... */
  }
}
```

---

## 2. 컴포넌트 매핑

### 2.1 Button

#### Flutter (Elevated Button)
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BorderRadiusToken.md),
    ),
    minimumSize: Size(double.infinity, 52),
    padding: EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
  ),
  onPressed: onPressed,
  child: Text('버튼'),
)
```

#### Web (shadcn/ui Button)
```tsx
import { Button } from '@/components/ui/button';

<Button
  variant="default"
  size="lg"
  className="h-[52px] px-lg rounded-md"
>
  버튼
</Button>
```

#### shadcn/ui 설정 (components/ui/button.tsx)
```tsx
const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md text-base font-medium transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        outline: 'border border-outline bg-transparent hover:bg-primary/5',
        ghost: 'hover:bg-primary/10',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 px-3',
        lg: 'h-[52px] px-lg py-sm',
      },
    },
  }
);
```

---

### 2.2 TextField

#### Flutter
```dart
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(BorderRadiusToken.md),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(BorderRadiusToken.md),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
    contentPadding: EdgeInsets.all(Spacing.md),
  ),
)
```

#### Web (shadcn/ui Input)
```tsx
import { Input } from '@/components/ui/input';

<Input
  className="h-[52px] bg-surface-container-highest rounded-md"
  placeholder="입력하세요"
/>
```

#### shadcn/ui 설정 (components/ui/input.tsx)
```tsx
const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          'flex h-[52px] w-full rounded-md border-0',
          'bg-surface-container-highest px-md py-md',
          'text-base text-surface-foreground',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary',
          className
        )}
        ref={ref}
        {...props}
      />
    );
  }
);
```

---

### 2.3 Card

#### Flutter
```dart
Card(
  elevation: Elevation.medium,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(BorderRadiusToken.lg),
  ),
  child: Padding(
    padding: EdgeInsets.all(Spacing.md),
    child: child,
  ),
)
```

#### Web (shadcn/ui Card)
```tsx
import { Card, CardContent } from '@/components/ui/card';

<Card className="rounded-lg">
  <CardContent className="p-md">
    {children}
  </CardContent>
</Card>
```

---

### 2.4 Dialog

#### Flutter
```dart
AlertDialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(BorderRadiusToken.xl),
  ),
  title: Text('제목'),
  content: Text('내용'),
  actions: [
    TextButton(onPressed: onCancel, child: Text('취소')),
    ElevatedButton(onPressed: onConfirm, child: Text('확인')),
  ],
)
```

#### Web (shadcn/ui Dialog)
```tsx
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';

<Dialog>
  <DialogContent className="rounded-xl">
    <DialogHeader>
      <DialogTitle>제목</DialogTitle>
    </DialogHeader>
    <div>내용</div>
    <DialogFooter>
      <Button variant="outline" onClick={onCancel}>취소</Button>
      <Button onClick={onConfirm}>확인</Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

---

### 2.5 Toast/SnackBar

#### Flutter (SnackBarUtils)
```dart
SnackBarUtils.showSuccess(context, '저장되었습니다');
```

#### Web (shadcn/ui Sonner)
```tsx
import { toast } from 'sonner';

toast.success('저장되었습니다', {
  duration: 2000,
  className: 'rounded-sm',
});
```

#### Toast 설정
```tsx
// app/layout.tsx
import { Toaster } from 'sonner';

<Toaster
  position="bottom-center"
  toastOptions={{
    classNames: {
      success: 'bg-income text-white',
      error: 'bg-expense text-white',
    },
  }}
/>
```

---

## 3. 타이포그래피 매핑

### 3.1 Flutter TextTheme
```dart
textTheme: TextTheme(
  displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
  displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
  displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
  headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
  headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
  headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
  titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
  titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
  bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
)
```

### 3.2 Tailwind Typography
```typescript
// tailwind.config.ts
theme: {
  extend: {
    fontSize: {
      'display-large': ['57px', { lineHeight: '64px', fontWeight: '400' }],
      'display-medium': ['45px', { lineHeight: '52px', fontWeight: '400' }],
      'display-small': ['36px', { lineHeight: '44px', fontWeight: '400' }],
      'headline-large': ['32px', { lineHeight: '40px', fontWeight: '400' }],
      'headline-medium': ['28px', { lineHeight: '36px', fontWeight: '400' }],
      'headline-small': ['24px', { lineHeight: '32px', fontWeight: '400' }],
      'title-large': ['22px', { lineHeight: '28px', fontWeight: '400' }],
      'title-medium': ['16px', { lineHeight: '24px', fontWeight: '500' }],
      'title-small': ['14px', { lineHeight: '20px', fontWeight: '500' }],
      'body-large': ['16px', { lineHeight: '24px', fontWeight: '400' }],
      'body-medium': ['14px', { lineHeight: '20px', fontWeight: '400' }],
      'body-small': ['12px', { lineHeight: '16px', fontWeight: '400' }],
      'label-large': ['14px', { lineHeight: '20px', fontWeight: '500' }],
      'label-medium': ['12px', { lineHeight: '16px', fontWeight: '500' }],
      'label-small': ['11px', { lineHeight: '16px', fontWeight: '500' }],
    },
  },
}
```

### 3.3 사용 예시
```tsx
<h1 className="text-headline-large">제목</h1>
<p className="text-body-medium">본문</p>
<span className="text-label-small">라벨</span>
```

---

## 4. 아이콘 매핑

### 4.1 Flutter (Material Icons)
```dart
Icon(Icons.add, size: IconSize.md)
Icon(Icons.home, color: colorScheme.primary)
```

### 4.2 Web (Lucide React)
```tsx
import { Plus, Home } from 'lucide-react';

<Plus className="w-6 h-6" />
<Home className="text-primary" />
```

### 4.3 아이콘 크기 매핑
```typescript
// Flutter IconSize → Web className
IconSize.xs (16px)  → w-4 h-4
IconSize.sm (20px)  → w-5 h-5
IconSize.md (24px)  → w-6 h-6
IconSize.lg (32px)  → w-8 h-8
IconSize.xl (48px)  → w-12 h-12
IconSize.xxl (64px) → w-16 h-16
```

---

## 5. 애니메이션 매핑

### 5.1 Flutter Duration
```dart
AnimationDuration.duration100  // 100ms
AnimationDuration.duration200  // 200ms
AnimationDuration.duration300  // 300ms
```

### 5.2 Tailwind Transition
```css
/* tailwind.config.ts */
theme: {
  extend: {
    transitionDuration: {
      '100': '100ms',
      '200': '200ms',
      '300': '300ms',
      '500': '500ms',
    },
  },
}
```

### 5.3 사용 예시
```tsx
<Button className="transition-all duration-200 hover:scale-95">
  버튼
</Button>
```

---

## 6. 반응형 디자인 매핑

### 6.1 Flutter (LayoutBuilder)
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 768) {
      return MobileLayout();
    } else if (constraints.maxWidth < 1024) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  },
)
```

### 6.2 Tailwind Breakpoints
```tsx
<div className="
  flex flex-col       /* Mobile */
  md:flex-row        /* Tablet */
  lg:grid lg:grid-cols-3  /* Desktop */
">
  {children}
</div>
```

---

## 7. 다크모드 매핑

### 7.1 Flutter (ThemeMode)
```dart
MaterialApp(
  themeMode: ThemeMode.system,
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
)
```

### 7.2 Next.js (next-themes)
```tsx
// app/layout.tsx
import { ThemeProvider } from '@/components/theme-provider';

<ThemeProvider attribute="class" defaultTheme="system">
  {children}
</ThemeProvider>

// 사용
<Button className="bg-primary dark:bg-primary-container">
  버튼
</Button>
```

---

## 8. 그림자 (Elevation) 매핑

### 8.1 Flutter Elevation
```dart
Card(elevation: Elevation.medium) // 2.0
```

### 8.2 Tailwind Shadow
```css
/* tailwind.config.ts */
theme: {
  extend: {
    boxShadow: {
      'elevation-low': '0 1px 2px rgba(0,0,0,0.05)',
      'elevation-medium': '0 2px 4px rgba(0,0,0,0.1)',
      'elevation-high': '0 4px 8px rgba(0,0,0,0.15)',
    },
  },
}
```

```tsx
<Card className="shadow-elevation-medium">
  {children}
</Card>
```

---

## 9. 컴포넌트 비교표

| Flutter | Web (shadcn/ui) | 설명 |
|---------|-----------------|------|
| ElevatedButton | Button variant="default" | Primary 버튼 |
| OutlinedButton | Button variant="outline" | Secondary 버튼 |
| TextButton | Button variant="ghost" | Text 버튼 |
| TextField | Input | 입력 필드 |
| Card | Card | 카드 컴포넌트 |
| AlertDialog | Dialog | 다이얼로그 |
| SnackBar | Sonner (toast) | 토스트 알림 |
| FloatingActionButton | Button size="lg" + rounded-lg | FAB |
| Chip | Badge | 배지/태그 |
| Switch | Switch | 스위치 |
| Checkbox | Checkbox | 체크박스 |
| RadioButton | RadioGroup | 라디오 버튼 |
| DropdownButton | Select | 셀렉트 |
| DatePicker | DatePicker | 날짜 선택 |
| BottomSheet | Sheet | 바텀시트 |

---

## 10. 유틸리티 함수 매핑

### 10.1 Flutter NumberFormat
```dart
NumberFormatUtils.currency.format(15000) // ₩15,000
```

### 10.2 Web (Intl)
```typescript
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('ko-KR', {
    style: 'currency',
    currency: 'KRW',
  }).format(amount);
}
```

### 10.3 날짜 포맷
```typescript
export function formatDate(date: Date, format: 'short' | 'long' = 'short'): string {
  return new Intl.DateTimeFormat('ko-KR', {
    year: 'numeric',
    month: format === 'short' ? 'numeric' : 'long',
    day: 'numeric',
  }).format(date);
}
```

---

## 11. 체크리스트

### 디자인 일관성
- [ ] 색상 팔레트 일치
- [ ] 간격 (Spacing) 토큰 일치
- [ ] 모서리 반경 (Border Radius) 일치
- [ ] 타이포그래피 일치
- [ ] 아이콘 크기 일치
- [ ] 애니메이션 duration 일치
- [ ] 그림자 (Elevation) 일치

### 컴포넌트
- [ ] 버튼 스타일 일치
- [ ] 입력 필드 스타일 일치
- [ ] 카드 스타일 일치
- [ ] 다이얼로그 스타일 일치
- [ ] 토스트 스타일 일치

### 반응형
- [ ] 모바일 레이아웃
- [ ] 태블릿 레이아웃
- [ ] 데스크톱 레이아웃
- [ ] 브레이크포인트 일치

### 접근성
- [ ] 색상 대비 (WCAG AA)
- [ ] 키보드 네비게이션
- [ ] ARIA 라벨
- [ ] 포커스 인디케이터

---

## 12. 참고 파일

### Flutter 프로젝트
- `DESIGN_SYSTEM.md`: 디자인 시스템 가이드
- `lib/shared/themes/design_tokens.dart`: 디자인 토큰
- `lib/shared/themes/app_theme.dart`: 테마 정의
- `household.pen`: pencil.dev 디자인 파일

### Web 프로젝트 (생성 예정)
- `web/styles/design-tokens.css`: CSS 변수
- `web/tailwind.config.ts`: Tailwind 설정
- `web/components/ui/`: shadcn/ui 컴포넌트
- `web/lib/utils.ts`: 유틸리티 함수
