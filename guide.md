# 공유 가계부 앱 개발 가이드

이 문서는 Flutter + Supabase 기반 공유 가계부 앱의 코드 구조와 동작 방식을 설명합니다.

---

## 목차

1. [프로젝트 구조](#1-프로젝트-구조)
2. [앱 시작점과 초기화](#2-앱-시작점과-초기화)
3. [라우팅과 화면 전환](#3-라우팅과-화면-전환)
4. [상태 관리 (Riverpod)](#4-상태-관리-riverpod)
5. [테마와 스타일링](#5-테마와-스타일링)
6. [Feature별 코드 설명](#6-feature별-코드-설명)
7. [데이터 흐름](#7-데이터-흐름)
8. [자주 사용하는 패턴](#8-자주-사용하는-패턴)

---

## 1. 프로젝트 구조

```
lib/
├── main.dart              # 앱 진입점
├── config/                # 앱 설정
│   ├── router.dart        # 라우팅 설정
│   └── supabase_config.dart  # Supabase 연결 설정
├── core/                  # 공통 상수 및 유틸리티
│   └── constants/
├── shared/                # 공유 컴포넌트
│   └── themes/
│       └── app_theme.dart # 테마 정의
└── features/              # 기능별 모듈
    ├── auth/              # 인증
    ├── ledger/            # 가계부
    ├── transaction/       # 거래 기록
    ├── category/          # 카테고리
    ├── budget/            # 예산
    ├── statistics/        # 통계
    ├── share/             # 공유 관리
    ├── search/            # 검색
    └── settings/          # 설정
```

### Feature 내부 구조 (Clean Architecture)

각 Feature는 다음 3개의 레이어로 구성됩니다:

```
features/{feature_name}/
├── domain/           # 비즈니스 로직 레이어
│   └── entities/     # 데이터 모델 (순수 Dart 클래스)
├── data/             # 데이터 접근 레이어
│   ├── models/       # JSON 변환이 포함된 모델
│   └── repositories/ # Supabase와 통신하는 클래스
└── presentation/     # UI 레이어
    ├── pages/        # 전체 화면 위젯
    ├── widgets/      # 재사용 가능한 위젯
    └── providers/    # Riverpod 상태 관리
```

---

## 2. 앱 시작점과 초기화

### main.dart

```dart
// lib/main.dart - 앱의 시작점

void main() async {
  // Flutter 엔진 초기화 (네이티브 코드와 연결)
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화 (.env에서 설정 로드)
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase 초기화 실패: $e');
  }

  // 앱 실행 - ProviderScope로 감싸서 Riverpod 활성화
  runApp(
    const ProviderScope(
      child: SharedHouseholdAccountApp(),
    ),
  );
}
```

**핵심 포인트:**
- `WidgetsFlutterBinding.ensureInitialized()`: async main()을 사용할 때 필수
- `ProviderScope`: Riverpod 상태 관리를 사용하려면 앱 최상위에 필요
- `SupabaseConfig.initialize()`: 백엔드 연결 초기화

### SharedHouseholdAccountApp 위젯

```dart
class SharedHouseholdAccountApp extends ConsumerWidget {
  const SharedHouseholdAccountApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // routerProvider를 통해 GoRouter 인스턴스 가져옴
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '공유 가계부',
      debugShowCheckedModeBanner: false,  // 디버그 배너 숨김
      theme: AppTheme.lightTheme,         // 라이트 테마
      darkTheme: AppTheme.darkTheme,      // 다크 테마
      themeMode: ThemeMode.system,        // 시스템 설정 따름
      routerConfig: router,               // GoRouter 연결
    );
  }
}
```

**ConsumerWidget이란?**
- Riverpod의 `ref`를 사용할 수 있는 위젯
- `ref.watch()`: 상태 변화를 구독하고 변경 시 리빌드
- `ref.read()`: 상태를 한 번만 읽음 (구독 안 함)

---

## 3. 라우팅과 화면 전환

### 라우트 정의 (lib/config/router.dart)

```dart
// 라우트 경로 상수 정의
class Routes {
  Routes._();  // 인스턴스 생성 방지

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String settings = '/settings';
  // ... 기타 라우트
}
```

### 라우터 Provider

```dart
final routerProvider = Provider<GoRouter>((ref) {
  // 인증 상태 구독 - 로그인/로그아웃 시 자동으로 라우터가 반응
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.splash,  // 앱 시작 시 첫 화면
    debugLogDiagnostics: true,       // 디버그 로그 출력

    // 리다이렉트 로직 - 모든 화면 전환 시 실행됨
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.signup;

      // 로그인 안 됨 + 인증 페이지 아님 -> 로그인으로
      if (!isLoggedIn && !isAuthRoute) {
        return Routes.login;
      }

      // 로그인 됨 + 인증 페이지 -> 홈으로
      if (isLoggedIn && isAuthRoute) {
        return Routes.home;
      }

      return null;  // null이면 원래 목적지로 이동
    },

    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomePage(),
      ),
      // ... 기타 라우트
    ],
  );
});
```

### 화면 전환 방법

```dart
// 1. go() - 스택을 대체 (뒤로가기 불가)
context.go(Routes.home);

// 2. push() - 스택에 추가 (뒤로가기 가능)
context.push(Routes.settings);

// 3. pop() - 이전 화면으로
context.pop();
Navigator.pop(context);  // 기존 방식도 사용 가능
```

---

## 4. 상태 관리 (Riverpod)

### Provider 종류

```dart
// 1. Provider - 변하지 않는 값 (싱글톤)
final repositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository();
});

// 2. StateProvider - 단순한 상태 (원시값, 선택값 등)
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 3. FutureProvider - 비동기 데이터 로딩
final ledgersProvider = FutureProvider<List<Ledger>>((ref) async {
  final repository = ref.watch(ledgerRepositoryProvider);
  return repository.getLedgers();  // Supabase에서 데이터 가져옴
});

// 4. StreamProvider - 실시간 스트림 구독
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseConfig.auth.onAuthStateChange.map(
    (event) => event.session?.user
  );
});

// 5. StateNotifierProvider - 복잡한 상태 로직
final ledgerNotifierProvider = StateNotifierProvider<
  LedgerNotifier,
  AsyncValue<List<Ledger>>
>((ref) {
  return LedgerNotifier(ref.watch(repositoryProvider), ref);
});
```

### Provider 사용 방법

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. watch - 값이 변경되면 위젯 리빌드
    final ledgers = ref.watch(ledgersProvider);

    // 2. read - 값을 한 번만 읽음 (이벤트 핸들러에서 사용)
    // 버튼 클릭 등에서 사용
    onPressed: () {
      ref.read(selectedDateProvider.notifier).state = DateTime.now();
    }

    // 3. invalidate - 캐시 무효화 및 재로딩
    ref.invalidate(ledgersProvider);

    // FutureProvider의 상태 처리
    return ledgers.when(
      data: (data) => ListView(...),      // 성공
      loading: () => CircularProgressIndicator(),  // 로딩 중
      error: (e, st) => Text('오류: $e'),  // 에러
    );
  }
}
```

### StateNotifier 패턴

```dart
// StateNotifier: 상태 변경 로직을 캡슐화
class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;
  final Ref _ref;

  TransactionNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  // 데이터 로드
  Future<void> loadTransactions() async {
    state = const AsyncValue.loading();  // 로딩 상태로 변경
    try {
      final data = await _repository.getTransactions();
      state = AsyncValue.data(data);     // 성공 상태로 변경
    } catch (e, st) {
      state = AsyncValue.error(e, st);   // 에러 상태로 변경
    }
  }

  // 데이터 생성
  Future<void> createTransaction({...}) async {
    await _repository.createTransaction(...);

    // 관련 Provider들의 캐시 무효화 -> 자동 재로딩
    _ref.invalidate(dailyTransactionsProvider);
    _ref.invalidate(monthlyTotalProvider);
  }
}
```

---

## 5. 테마와 스타일링

### 테마 정의 (lib/shared/themes/app_theme.dart)

```dart
class AppTheme {
  AppTheme._();  // 인스턴스 생성 방지

  // 앱의 기본 색상 (Material 3 시드 컬러)
  static const Color seedColor = Color(0xFF2E7D32);  // 녹색 계열

  static ThemeData get lightTheme {
    // Material 3의 ColorScheme 자동 생성
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // AppBar 스타일
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),

      // Card 스타일
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      // Input 스타일
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(128),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // focused, error 상태별 스타일...
      ),

      // Button 스타일
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),  // 전체 너비, 높이 52
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // ... 기타 컴포넌트 스타일
    );
  }
}
```

### 테마 사용 방법

```dart
@override
Widget build(BuildContext context) {
  // Theme.of(context)로 현재 테마 접근
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return Column(
    children: [
      // 색상 사용
      Container(
        color: colorScheme.primary,        // 주 색상
        child: Text(
          '제목',
          style: TextStyle(
            color: colorScheme.onPrimary,  // 주 색상 위의 텍스트 색상
          ),
        ),
      ),

      // 텍스트 스타일 사용
      Text(
        '본문',
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,  // 보조 텍스트 색상
        ),
      ),

      // 테마에 정의된 버튼 스타일 자동 적용
      ElevatedButton(
        onPressed: () {},
        child: const Text('저장'),  // 자동으로 전체 너비, 둥근 모서리
      ),
    ],
  );
}
```

### 자주 사용하는 색상

```dart
// Material 3 ColorScheme 주요 색상
colorScheme.primary           // 주 색상 (버튼, 강조)
colorScheme.onPrimary         // primary 위의 텍스트/아이콘
colorScheme.primaryContainer  // 주 색상의 연한 버전 (배경)
colorScheme.onPrimaryContainer

colorScheme.secondary         // 보조 색상
colorScheme.surface           // 카드, 시트 배경
colorScheme.onSurface         // surface 위의 텍스트
colorScheme.onSurfaceVariant  // 보조 텍스트 색상

colorScheme.error             // 에러 색상 (빨간색)
colorScheme.onError           // error 위의 텍스트

colorScheme.outline           // 테두리, 구분선
colorScheme.outlineVariant    // 연한 테두리
```

---

## 6. Feature별 코드 설명

### 6.1 인증 (Auth)

#### 로그인 화면 (lib/features/auth/presentation/pages/login_page.dart)

```dart
class LoginPage extends ConsumerStatefulWidget {
  // ConsumerStatefulWidget: Riverpod + StatefulWidget
  // 상태(state)가 필요하고 ref도 사용해야 할 때
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // 폼 검증을 위한 GlobalKey
  final _formKey = GlobalKey<FormState>();

  // 텍스트 입력 컨트롤러 - dispose에서 반드시 해제해야 함
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 로컬 UI 상태
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 이메일 로그인 처리
  Future<void> _handleEmailLogin() async {
    // 폼 검증
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);  // 로딩 시작

    try {
      // Riverpod을 통해 인증 서비스 호출
      await ref.read(authNotifierProvider.notifier).signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // mounted: 위젯이 아직 화면에 있는지 확인 (async 후 필수)
      if (mounted) {
        context.go(Routes.home);  // 홈으로 이동
      }
    } catch (e) {
      if (mounted) {
        // 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);  // 로딩 종료
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(  // 노치, 홈 인디케이터 영역 피함
        child: SingleChildScrollView(  // 키보드가 올라와도 스크롤 가능
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,  // 폼 검증용 키
            child: Column(
              children: [
                // 이메일 입력
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  // 검증 함수
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!value.contains('@')) {
                      return '올바른 이메일 형식이 아닙니다';
                    }
                    return null;  // null이면 검증 통과
                  },
                ),

                // 로그인 버튼
                ElevatedButton(
                  // 로딩 중이면 비활성화
                  onPressed: _isLoading ? null : _handleEmailLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('로그인'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### 인증 Provider (lib/features/auth/presentation/providers/auth_provider.dart)

```dart
// 인증 상태 스트림 - Supabase의 인증 상태 변화를 실시간으로 구독
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseConfig.auth.onAuthStateChange.map(
    (event) => event.session?.user
  );
});

// 인증 서비스 - Supabase Auth API 래핑
class AuthService {
  final _auth = SupabaseConfig.auth;

  // 이메일 로그인
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
```

### 6.2 홈 화면 (Ledger)

#### 홈 페이지 구조 (lib/features/ledger/presentation/pages/home_page.dart)

```dart
class HomePage extends ConsumerStatefulWidget {
  // StatefulWidget을 사용하는 이유: 탭 인덱스 상태 관리
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;  // 현재 선택된 탭

  @override
  void initState() {
    super.initState();
    // 위젯 빌드 후 가계부 초기화 (첫 빌드 사이클 이후 실행)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLedger();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Provider로부터 상태 가져오기
    final selectedDate = ref.watch(selectedDateProvider);
    final currentLedgerAsync = ref.watch(currentLedgerProvider);

    return Scaffold(
      appBar: AppBar(
        // AsyncValue의 when으로 상태별 UI 표시
        title: currentLedgerAsync.when(
          data: (ledger) => Text(ledger?.name ?? '공유 가계부'),
          loading: () => const Text('공유 가계부'),
          error: (e, st) => const Text('공유 가계부'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(Routes.search),
          ),
        ],
      ),

      // IndexedStack: 탭 내용을 미리 빌드하고 유지
      // 탭 전환 시 상태가 유지됨 (vs PageView는 매번 리빌드)
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CalendarTabView(...),      // 캘린더 탭
          const StatisticsTabView(), // 통계 탭
          const BudgetTabView(),     // 예산 탭
          const MoreTabView(),       // 더보기 탭
        ],
      ),

      // FAB (Floating Action Button)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionSheet(context, selectedDate),
        icon: const Icon(Icons.add),
        label: const Text('기록하기'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 하단 네비게이션
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
          // ... 기타 탭
        ],
      ),
    );
  }

  // 바텀시트로 거래 추가 화면 표시
  void _showAddTransactionSheet(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,  // 전체 높이 사용 가능
      useSafeArea: true,         // SafeArea 적용
      builder: (context) => AddTransactionSheet(initialDate: date),
    );
  }
}
```

### 6.3 거래 추가 (Transaction)

#### 바텀시트 위젯 (lib/features/transaction/presentation/widgets/add_transaction_sheet.dart)

```dart
class AddTransactionSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const AddTransactionSheet({super.key, this.initialDate});
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  String _type = 'expense';       // 수입/지출 타입
  Category? _selectedCategory;    // 선택된 카테고리

  @override
  Widget build(BuildContext context) {
    // 타입에 따라 다른 카테고리 목록 구독
    final categoriesAsync = _type == 'expense'
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    // DraggableScrollableSheet: 드래그로 높이 조절 가능한 시트
    return DraggableScrollableSheet(
      initialChildSize: 0.9,   // 초기 높이 90%
      minChildSize: 0.5,       // 최소 높이 50%
      maxChildSize: 0.95,      // 최대 높이 95%
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 드래그 핸들 바
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withAlpha(76),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 수입/지출 선택 (SegmentedButton)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('지출')),
                  ButtonSegment(value: 'income', label: Text('수입')),
                ],
                selected: {_type},
                onSelectionChanged: (selected) {
                  setState(() {
                    _type = selected.first;
                    _selectedCategory = null;  // 타입 변경 시 카테고리 초기화
                  });
                },
              ),

              // 카테고리 그리드
              categoriesAsync.when(
                data: (categories) => _buildCategoryGrid(categories),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('오류: $e'),
              ),
            ],
          ),
        );
      },
    );
  }

  // 카테고리 선택 UI
  Widget _buildCategoryGrid(List<Category> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = _selectedCategory?.id == category.id;
        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(category.icon),
              const SizedBox(width: 4),
              Text(category.name),
            ],
          ),
          onSelected: (_) {
            setState(() => _selectedCategory = category);
          },
        );
      }).toList(),
    );
  }
}
```

### 6.4 거래 목록 (TransactionList)

```dart
// lib/features/ledger/presentation/widgets/transaction_list.dart

class TransactionList extends ConsumerWidget {
  final DateTime date;

  const TransactionList({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 선택된 날짜의 거래 목록 구독
    final transactionsAsync = ref.watch(dailyTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _EmptyState(date: date);  // 빈 상태 표시
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _TransactionCard(
              transaction: transaction,
              onDelete: () async {
                await ref
                    .read(transactionNotifierProvider.notifier)
                    .deleteTransaction(transaction.id);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            Text('오류가 발생했습니다: $e'),
            FilledButton.tonal(
              // 재시도: Provider 무효화로 재로딩
              onPressed: () => ref.refresh(dailyTransactionsProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Slidable 카드 (스와이프 액션)

```dart
// flutter_slidable 패키지 사용

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      // 오른쪽에서 왼쪽으로 스와이프했을 때 나오는 액션
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) { /* 수정 로직 */ },
            backgroundColor: colorScheme.primary,
            icon: Icons.edit,
            label: '수정',
          ),
          SlidableAction(
            onPressed: (_) async {
              // 삭제 확인 다이얼로그
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('거래 삭제'),
                  content: const Text('이 거래를 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                onDelete();
              }
            },
            backgroundColor: colorScheme.error,
            icon: Icons.delete,
            label: '삭제',
          ),
        ],
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 카테고리 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _parseColor(transaction.categoryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(transaction.categoryIcon ?? '', style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),

              // 카테고리명, 메모
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.categoryName ?? '미분류'),
                    if (transaction.memo != null)
                      Text(transaction.memo!, style: textTheme.bodySmall),
                  ],
                ),
              ),

              // 금액
              Text(
                '${transaction.isIncome ? '+' : '-'}${formatter.format(transaction.amount)}원',
                style: TextStyle(
                  color: transaction.isIncome ? Colors.blue : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 7. 데이터 흐름

### Repository 패턴

```
[UI Widget] ---(watch)---> [Provider]
                               |
                               | (async call)
                               v
                         [Repository]
                               |
                               | (HTTP/WebSocket)
                               v
                         [Supabase DB]
```

### Repository 예시 (lib/features/ledger/data/repositories/ledger_repository.dart)

```dart
class LedgerRepository {
  final _client = SupabaseConfig.client;

  // 데이터 조회
  Future<List<LedgerModel>> getLedgers() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    // Supabase 쿼리 빌더
    final response = await _client
        .from('ledgers')           // 테이블 선택
        .select()                  // 모든 컬럼 선택
        .order('created_at', ascending: false);  // 정렬

    // JSON -> Model 변환
    return (response as List)
        .map((json) => LedgerModel.fromJson(json))
        .toList();
  }

  // 데이터 생성
  Future<LedgerModel> createLedger({
    required String name,
    required String currency,
  }) async {
    final data = {
      'name': name,
      'currency': currency,
      'owner_id': _client.auth.currentUser!.id,
    };

    final response = await _client
        .from('ledgers')
        .insert(data)              // INSERT
        .select()                  // 생성된 데이터 반환
        .single();                 // 단일 레코드

    return LedgerModel.fromJson(response);
  }

  // 데이터 수정
  Future<LedgerModel> updateLedger({
    required String id,
    String? name,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;

    final response = await _client
        .from('ledgers')
        .update(updates)           // UPDATE
        .eq('id', id)              // WHERE id = ?
        .select()
        .single();

    return LedgerModel.fromJson(response);
  }

  // 데이터 삭제
  Future<void> deleteLedger(String id) async {
    await _client
        .from('ledgers')
        .delete()                  // DELETE
        .eq('id', id);             // WHERE id = ?
  }
}
```

### Entity vs Model

```dart
// Entity (domain/entities/) - 순수 비즈니스 로직
class Ledger extends Equatable {
  final String id;
  final String name;
  // ... 필드들

  // Equatable: 값 비교를 위한 props
  @override
  List<Object?> get props => [id, name, ...];
}

// Model (data/models/) - JSON 변환 포함
class LedgerModel extends Ledger {
  const LedgerModel({...}) : super(...);

  // JSON -> Model
  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    return LedgerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      // snake_case -> camelCase 변환
      ownerId: json['owner_id'] as String,
      isShared: json['is_shared'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Model -> JSON (생성/수정용)
  static Map<String, dynamic> toCreateJson({
    required String name,
    required String currency,
    required String ownerId,
  }) {
    return {
      'name': name,
      'currency': currency,
      'owner_id': ownerId,
    };
  }
}
```

---

## 8. 자주 사용하는 패턴

### 8.1 폼 검증

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '필수 입력 항목입니다';  // 에러 메시지 반환
          }
          return null;  // null이면 검증 통과
        },
      ),
      ElevatedButton(
        onPressed: () {
          // validate()가 모든 validator를 실행
          if (_formKey.currentState!.validate()) {
            // 폼 검증 통과 - 제출 로직
          }
        },
        child: const Text('제출'),
      ),
    ],
  ),
)
```

### 8.2 비동기 처리와 mounted 체크

```dart
Future<void> _handleSubmit() async {
  setState(() => _isLoading = true);

  try {
    await someAsyncOperation();

    // async 작업 후 위젯이 아직 화면에 있는지 확인
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### 8.3 날짜/숫자 포맷팅

```dart
import 'package:intl/intl.dart';

// 날짜 포맷
final dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');
dateFormat.format(DateTime.now());  // "2024년 1월 15일 (월)"

// 숫자 포맷 (천 단위 구분)
final numberFormat = NumberFormat('#,###', 'ko_KR');
numberFormat.format(50000);  // "50,000"
```

### 8.4 색상 파싱 (HEX -> Color)

```dart
Color? _parseColor(String? colorStr) {
  if (colorStr == null) return null;
  try {
    final hex = colorStr.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));  // FF = 불투명도
  } catch (_) {
    return null;
  }
}
```

### 8.5 확인 다이얼로그

```dart
Future<void> _showDeleteConfirmation() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('삭제'),
      content: const Text('정말 삭제하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('삭제'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    // 삭제 실행
  }
}
```

### 8.6 Controller dispose 패턴

```dart
class _MyPageState extends State<MyPage> {
  // 컨트롤러들은 dispose에서 해제해야 메모리 누수 방지
  final _controller1 = TextEditingController();
  final _controller2 = ScrollController();

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();  // 부모 dispose는 마지막에 호출
  }
}
```

---

## 부록: 유용한 팁

### 디버깅

```dart
// 콘솔 출력 (릴리즈에서도 출력됨 - 비권장)
print('디버그 메시지');

// 디버그 모드에서만 출력 (권장)
debugPrint('디버그 메시지');

// Flutter Inspector에서 확인 가능한 로그
import 'dart:developer';
log('디버그 메시지');
```

### 자주 쓰는 위젯

```dart
// 키보드에 가려지지 않게 스크롤
SingleChildScrollView(child: ...)

// 노치/홈바 영역 피하기
SafeArea(child: ...)

// 리스트 아이템 사이 구분선
ListView.separated(
  separatorBuilder: (context, index) => const Divider(),
)

// 가로 전체 너비
SizedBox(width: double.infinity, child: ...)

// 남은 공간 채우기
Expanded(child: ...)
Spacer()  // 빈 공간으로 채우기
```
