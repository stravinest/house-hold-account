# 결제수단 멤버별 관리 - 기술 구현 가이드

## 🔧 단계별 구현 계획

### Phase 1: 데이터베이스 및 모델 (1주)
### Phase 2: 백엔드 로직 (1주)
### Phase 3: UI/UX 구현 (2주)
### Phase 4: 테스트 및 배포 (1주)

---

## Phase 1: 데이터베이스 및 모델 변경

### 1.1 데이터베이스 마이그레이션

```sql
-- 파일: supabase/migrations/XXX_add_user_id_to_payment_methods.sql

-- 1. payment_methods 테이블에 user_id 컬럼 추가
ALTER TABLE house.payment_methods
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 2. 인덱스 추가 (조회 성능 최적화)
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id 
  ON house.payment_methods(user_id);

CREATE INDEX IF NOT EXISTS idx_payment_methods_ledger_user_id 
  ON house.payment_methods(ledger_id, user_id);

-- 3. 주석 추가
COMMENT ON COLUMN house.payment_methods.user_id 
  IS '결제수단 소유자 (NULL = 공유 결제수단, 구 데이터 호환)';

-- 4. 기존 데이터 마이그레이션 (선택사항)
-- 개인 가계부는 user_id 자동 설정, 공유 가계부는 NULL 유지
-- UPDATE house.payment_methods
-- SET user_id = (SELECT user_id FROM house.ledger_members 
--                WHERE ledger_id = payment_methods.ledger_id LIMIT 1)
-- WHERE ledger_type = 'personal';

-- 5. RLS 정책 업데이트
DROP POLICY IF EXISTS "결제수단_select_policy" ON house.payment_methods;
DROP POLICY IF EXISTS "결제수단_insert_policy" ON house.payment_methods;
DROP POLICY IF EXISTS "결제수단_update_policy" ON house.payment_methods;
DROP POLICY IF EXISTS "결제수단_delete_policy" ON house.payment_methods;

CREATE POLICY "payment_methods_select_policy"
    ON house.payment_methods FOR SELECT
    USING (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members 
            WHERE user_id = auth.uid()
        )
        AND (
            -- 자신의 결제수단 또는 NULL(공유) 결제수단만 보기
            user_id = auth.uid() 
            OR user_id IS NULL 
            OR (
                -- 다른 멤버의 결제수단도 볼 수 있음 (공유 가계부에서)
                ledger_id IN (
                    SELECT ledger_id FROM house.ledger_members 
                    WHERE user_id = auth.uid()
                )
            )
        )
    );

CREATE POLICY "payment_methods_insert_policy"
    ON house.payment_methods FOR INSERT
    WITH CHECK (
        -- 자신의 가계부에만 추가 가능
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members 
            WHERE user_id = auth.uid()
        )
        -- user_id는 현재 사용자로 자동 설정됨
    );

CREATE POLICY "payment_methods_update_policy"
    ON house.payment_methods FOR UPDATE
    USING (
        -- 자신의 결제수단만 수정 가능
        user_id = auth.uid()
        AND ledger_id IN (
            SELECT ledger_id FROM house.ledger_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "payment_methods_delete_policy"
    ON house.payment_methods FOR DELETE
    USING (
        -- 자신의 결제수단만 삭제 가능
        user_id = auth.uid()
        AND ledger_id IN (
            SELECT ledger_id FROM house.ledger_members 
            WHERE user_id = auth.uid()
        )
    );
```

### 1.2 PaymentMethod 엔티티 수정

```dart
// lib/features/payment_method/domain/entities/payment_method.dart

class PaymentMethod extends Equatable {
  final String id;
  final String ledgerId;
  final String name;
  final String icon;
  final String color;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;
  final AutoSaveMode autoSaveMode;
  final String? defaultCategoryId;
  final bool canAutoSave;
  final String? userId;  // ← 새로 추가: 결제수단 소유자

  const PaymentMethod({
    required this.id,
    required this.ledgerId,
    required this.name,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
    this.autoSaveMode = AutoSaveMode.manual,
    this.defaultCategoryId,
    this.canAutoSave = true,
    this.userId,  // ← 새로 추가
  });

  // 나의 결제수단인지 확인 (공유 가계부에서)
  bool isOwned(String currentUserId) => userId == currentUserId;

  // 공유 결제수단인지 확인 (구 데이터)
  bool isShared() => userId == null;

  PaymentMethod copyWith({
    String? id,
    String? ledgerId,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
    AutoSaveMode? autoSaveMode,
    String? defaultCategoryId,
    bool? canAutoSave,
    String? userId,  // ← 새로 추가
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      autoSaveMode: autoSaveMode ?? this.autoSaveMode,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      canAutoSave: canAutoSave ?? this.canAutoSave,
      userId: userId ?? this.userId,  // ← 새로 추가
    );
  }

  @override
  List<Object?> get props => [
    id,
    ledgerId,
    name,
    icon,
    color,
    isDefault,
    sortOrder,
    createdAt,
    autoSaveMode,
    defaultCategoryId,
    canAutoSave,
    userId,  // ← 새로 추가
  ];
}
```

### 1.3 PaymentMethodModel 수정

```dart
// lib/features/payment_method/data/models/payment_method_model.dart

factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
  return PaymentMethodModel(
    id: json['id'] as String,
    ledgerId: json['ledger_id'] as String,
    name: json['name'] as String,
    icon: (json['icon'] as String?) ?? '',
    color: (json['color'] as String?) ?? '#6750A4',
    isDefault: json['is_default'] as bool,
    sortOrder: json['sort_order'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    autoSaveMode: AutoSaveMode.fromString(
      (json['auto_save_mode'] as String?) ?? 'manual',
    ),
    defaultCategoryId: json['default_category_id'] as String?,
    canAutoSave: (json['can_auto_save'] as bool?) ?? true,
    userId: json['user_id'] as String?,  // ← 새로 추가
  );
}

Map<String, dynamic> toJson() {
  return {
    'id': id,
    'ledger_id': ledgerId,
    'name': name,
    'icon': icon,
    'color': color,
    'is_default': isDefault,
    'sort_order': sortOrder,
    'created_at': createdAt.toIso8601String(),
    'auto_save_mode': autoSaveMode.toJson(),
    'default_category_id': defaultCategoryId,
    'can_auto_save': canAutoSave,
    'user_id': userId,  // ← 새로 추가
  };
}

static Map<String, dynamic> toCreateJson({
  required String ledgerId,
  required String name,
  String icon = '',
  String color = '#6750A4',
  int sortOrder = 0,
  bool canAutoSave = true,
  String? userId,  // ← 새로 추가
}) {
  return {
    'ledger_id': ledgerId,
    'name': name,
    'icon': icon,
    'color': color,
    'is_default': false,
    'sort_order': sortOrder,
    'can_auto_save': canAutoSave,
    'user_id': userId,  // ← 새로 추가
  };
}
```

---

## Phase 2: 백엔드 로직 변경

### 2.1 PaymentMethodRepository 수정

```dart
// lib/features/payment_method/data/repositories/payment_method_repository.dart

class PaymentMethodRepository {
  // ... 기존 코드 ...

  // 특정 멤버의 결제수단 조회 (공유 가계부에서)
  Future<List<PaymentMethodModel>> getPaymentMethodsByUser({
    required String ledgerId,
    required String userId,
  }) async {
    final response = await _client
        .from('payment_methods')
        .select()
        .eq('ledger_id', ledgerId)
        .eq('user_id', userId)
        .order('sort_order');

    return (response as List)
        .map((json) => PaymentMethodModel.fromJson(json))
        .toList();
  }

  // 모든 멤버의 결제수단 조회 (공유 가계부에서)
  Future<List<PaymentMethodModel>> getPaymentMethodsGroupedByUser({
    required String ledgerId,
  }) async {
    final response = await _client
        .from('payment_methods')
        .select()
        .eq('ledger_id', ledgerId)
        .order('user_id')
        .order('sort_order');

    return (response as List)
        .map((json) => PaymentMethodModel.fromJson(json))
        .toList();
  }

  // 결제수단 생성 (user_id 자동 설정)
  Future<PaymentMethodModel> createPaymentMethod({
    required String ledgerId,
    required String name,
    String icon = '',
    String color = '#6750A4',
    bool canAutoSave = true,
    String? userId,  // null이면 현재 사용자로 설정
  }) async {
    try {
      final currentUserId = userId ?? _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 현재 최대 sort_order 조회
      final maxOrderResponse = await _client
          .from('payment_methods')
          .select('sort_order')
          .eq('ledger_id', ledgerId)
          .eq('user_id', currentUserId)
          .order('sort_order', ascending: false)
          .limit(1)
          .maybeSingle();

      final maxOrder = maxOrderResponse?['sort_order'] as int? ?? 0;

      final data = PaymentMethodModel.toCreateJson(
        ledgerId: ledgerId,
        name: name,
        icon: icon,
        color: color,
        sortOrder: maxOrder + 1,
        canAutoSave: canAutoSave,
        userId: currentUserId,  // ← user_id 설정
      );

      final response = await _client
          .from('payment_methods')
          .insert(data)
          .select()
          .single();

      return PaymentMethodModel.fromJson(response);
    } catch (e) {
      if (SupabaseErrorHandler.isDuplicateError(e)) {
        throw DuplicateItemException(itemType: '결제수단', itemName: name);
      }
      rethrow;
    }
  }

  // 결제수단 수정 (user_id는 수정 불가)
  Future<PaymentMethodModel> updatePaymentMethod({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    int? sortOrder,
    AutoSaveMode? autoSaveMode,
    String? defaultCategoryId,
    bool? canAutoSave,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (name != null) updates['name'] = name;
      if (icon != null) updates['icon'] = icon;
      if (color != null) updates['color'] = color;
      if (isDefault != null) updates['is_default'] = isDefault;
      if (sortOrder != null) updates['sort_order'] = sortOrder;
      if (autoSaveMode != null) updates['auto_save_mode'] = autoSaveMode.toJson();
      if (defaultCategoryId != null) updates['default_category_id'] = defaultCategoryId;
      if (canAutoSave != null) updates['can_auto_save'] = canAutoSave;

      final response = await _client
          .from('payment_methods')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return PaymentMethodModel.fromJson(response);
    } catch (e) {
      debugPrint('Payment method update failed: $e');
      rethrow;
    }
  }
}
```

### 2.2 Provider 추가

```dart
// lib/features/payment_method/presentation/providers/payment_method_provider.dart

// 특정 멤버의 결제수단 조회
final paymentMethodsByUserProvider = FutureProvider.family<
  List<PaymentMethod>,
  ({String ledgerId, String userId})
>((ref, params) async {
  final repository = ref.watch(paymentMethodRepositoryProvider);
  final methods = await repository.getPaymentMethodsByUser(
    ledgerId: params.ledgerId,
    userId: params.userId,
  );
  return methods.map((m) => m as PaymentMethod).toList();
});

// 멤버별로 그룹화된 결제수단
final paymentMethodsGroupedByUserProvider = FutureProvider.family<
  List<({String userId, String userName, List<PaymentMethod> methods})>,
  String  // ledgerId
>((ref, ledgerId) async {
  final repository = ref.watch(paymentMethodRepositoryProvider);
  final ledgerRepository = ref.watch(ledgerRepositoryProvider);
  
  // 모든 멤버 조회
  final members = await ledgerRepository.getLedgerMembers(ledgerId);
  
  // 모든 결제수단 조회
  final allMethods = await repository.getPaymentMethodsGroupedByUser(
    ledgerId: ledgerId,
  );
  
  // 멤버별로 그룹화
  final grouped = <String, List<PaymentMethod>>{};
  for (final method in allMethods) {
    final userId = method.userId ?? 'shared';
    grouped.putIfAbsent(userId, () => []).add(method);
  }
  
  // 정렬된 결과 반환
  return members
      .where((m) => grouped.containsKey(m.userId))
      .map((m) => (
        userId: m.userId,
        userName: m.displayName,
        methods: grouped[m.userId]!,
      ))
      .toList();
});

// 현재 사용자의 결제수단 (간편한 접근)
final myPaymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  final userId = ref.watch(currentUserIdProvider); // 현재 사용자 ID
  
  if (ledgerId == null || userId == null) return [];
  
  return ref.watch(paymentMethodsByUserProvider(
    (ledgerId: ledgerId, userId: userId),
  )).whenData((methods) => methods);
});
```

---

## Phase 3: UI/UX 구현

### 3.1 결제수단 관리 페이지 (탭 방식)

```dart
// lib/features/payment_method/presentation/pages/payment_method_management_page.dart

class PaymentMethodManagementPage extends ConsumerStatefulWidget {
  const PaymentMethodManagementPage({super.key});

  @override
  ConsumerState<PaymentMethodManagementPage> createState() =>
      _PaymentMethodManagementPageState();
}

class _PaymentMethodManagementPageState
    extends ConsumerState<PaymentMethodManagementPage> {
  late String _selectedMemberId;
  
  @override
  void initState() {
    super.initState();
    // 초기: 현재 사용자의 결제수단
    final currentUser = ref.read(currentUserProvider);
    _selectedMemberId = currentUser?.id ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final ledgerId = ref.watch(selectedLedgerIdProvider);
    final isSharedLedger = ref.watch(isSharedLedgerProvider);
    
    if (ledgerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('결제수단 관리')),
        body: const Center(child: Text('가계부를 선택해주세요')),
      );
    }

    // 공유 가계부가 아니면 기존 UI 유지
    if (!isSharedLedger) {
      return _buildSingleUserPage(context, ledgerId);
    }

    // 공유 가계부: 탭 방식
    return _buildSharedLedgerPage(context, ledgerId);
  }

  // 개인 가계부 UI (기존)
  Widget _buildSingleUserPage(BuildContext context, String ledgerId) {
    final paymentMethods = ref.watch(
      paymentMethodsProvider
    );

    return Scaffold(
      appBar: AppBar(title: const Text('결제수단 관리')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PaymentMethodWizardPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: paymentMethods.when(
        data: (methods) {
          if (methods.isEmpty) {
            return EmptyState(
              icon: Icons.credit_card_outlined,
              message: '등록된 결제수단이 없습니다',
              action: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentMethodWizardPage(),
                    ),
                  );
                },
                child: const Text('결제수단 추가'),
              ),
            );
          }

          return ListView.builder(
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              return PaymentMethodListTile(
                paymentMethod: method,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentMethodWizardPage(
                        paymentMethod: method,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('오류: $error')),
      ),
    );
  }

  // 공유 가계부 UI (탭 방식)
  Widget _buildSharedLedgerPage(BuildContext context, String ledgerId) {
    final groupedMethods = ref.watch(
      paymentMethodsGroupedByUserProvider(ledgerId)
    );
    
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('결제수단 관리')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PaymentMethodWizardPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: groupedMethods.when(
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyState(
              icon: Icons.credit_card_outlined,
              message: '등록된 결제수단이 없습니다',
              action: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentMethodWizardPage(),
                    ),
                  );
                },
                child: const Text('결제수단 추가'),
              ),
            );
          }

          // 초기 선택 멤버 설정 (현재 사용자)
          if (_selectedMemberId.isEmpty && currentUser != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _selectedMemberId = currentUser.id);
            });
          }

          return Column(
            children: [
              // 멤버 탭
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(Spacing.md),
                child: Wrap(
                  spacing: Spacing.sm,
                  children: [
                    for (final group in groups)
                      FilterChip(
                        label: Text(group.userName),
                        selected: _selectedMemberId == group.userId,
                        onSelected: (_) {
                          setState(() => _selectedMemberId = group.userId);
                        },
                      ),
                  ],
                ),
              ),
              const Divider(),
              // 선택된 멤버의 결제수단 리스트
              Expanded(
                child: _buildPaymentMethodList(
                  groups.firstWhere(
                    (g) => g.userId == _selectedMemberId,
                  ).methods,
                  currentUser?.id == _selectedMemberId, // 편집 가능 여부
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('오류: $error')),
      ),
    );
  }

  // 결제수단 리스트 빌더
  Widget _buildPaymentMethodList(
    List<PaymentMethod> methods,
    bool canEdit,
  ) {
    if (methods.isEmpty) {
      return Center(
        child: Text(
          canEdit ? '결제수단을 추가해주세요' : '결제수단이 없습니다',
        ),
      );
    }

    return ListView.builder(
      itemCount: methods.length,
      itemBuilder: (context, index) {
        final method = methods[index];
        return PaymentMethodListTile(
          paymentMethod: method,
          onTap: canEdit
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentMethodWizardPage(
                        paymentMethod: method,
                      ),
                    ),
                  );
                }
              : null,
          showEditIcon: canEdit,
        );
      },
    );
  }
}
```

### 3.2 PaymentMethodListTile 업데이트

```dart
// lib/features/payment_method/presentation/widgets/payment_method_list_tile.dart

class PaymentMethodListTile extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final String? currentUserId;

  const PaymentMethodListTile({
    required this.paymentMethod,
    this.onTap,
    this.showEditIcon = true,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _safeParseColor(paymentMethod.color),
        child: Text(
          paymentMethod.name.isNotEmpty ? paymentMethod.name[0] : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Row(
        children: [
          Text(paymentMethod.name),
          if (paymentMethod.userId != null && currentUserId != null)
            Padding(
              padding: const EdgeInsets.only(left: Spacing.sm),
              child: Text(
                '${paymentMethod.userId == currentUserId ? '(내 결제수단)' : '(${paymentMethod.userId}의 결제수단)'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('자동 수집: ${paymentMethod.canAutoSave ? 'ON' : 'OFF'}'),
          if (paymentMethod.isDefault)
            const Text('기본 결제수단', style: TextStyle(color: Colors.blue)),
        ],
      ),
      trailing: showEditIcon
          ? IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: onTap,
            )
          : null,
      onTap: onTap,
    );
  }

  Color _safeParseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
```

### 3.3 거래 추가 시 결제수단 필터링

```dart
// lib/features/transaction/presentation/widgets/payment_method_selector_widget.dart

// 현재 사용자의 결제수단만 표시
final userPaymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (ledgerId == null || currentUser == null) return [];

  final repository = ref.watch(paymentMethodRepositoryProvider);
  
  // 공유 가계부 확인
  final isShared = ref.watch(isSharedLedgerProvider);
  
  if (isShared) {
    // 공유 가계부: 자신의 결제수단만 표시
    return repository.getPaymentMethodsByUser(
      ledgerId: ledgerId,
      userId: currentUser.id,
    );
  } else {
    // 개인 가계부: 모든 결제수단
    return repository.getPaymentMethods(ledgerId);
  }
});
```

---

## Phase 4: 테스트 케이스

```dart
// test/features/payment_method/repositories/payment_method_repository_test.dart

void main() {
  group('PaymentMethodRepository - 멤버별 관리', () {
    test('특정 멤버의 결제수단 조회', () async {
      // given
      final ledgerId = 'test-ledger-1';
      final userId = 'user-1';

      // when
      final methods = await repository.getPaymentMethodsByUser(
        ledgerId: ledgerId,
        userId: userId,
      );

      // then
      expect(methods, isNotEmpty);
      expect(methods.every((m) => m.userId == userId), isTrue);
    });

    test('멤버별 그룹화된 결제수단 조회', () async {
      // given
      final ledgerId = 'test-ledger-1';

      // when
      final methods = await repository.getPaymentMethodsGroupedByUser(
        ledgerId: ledgerId,
      );

      // then
      expect(methods, isNotEmpty);
      // 멤버별로 정렬되어 있어야 함
      for (int i = 0; i < methods.length - 1; i++) {
        expect(
          methods[i].userId?.compareTo(methods[i + 1].userId ?? '') ?? -1,
          lessThanOrEqualTo(0),
        );
      }
    });

    test('결제수단 생성 시 현재 사용자로 자동 설정', () async {
      // given
      final ledgerId = 'test-ledger-1';
      final name = 'Test Card';

      // when
      final method = await repository.createPaymentMethod(
        ledgerId: ledgerId,
        name: name,
        // userId 미지정 → 현재 사용자로 자동 설정
      );

      // then
      expect(method.userId, isNotNull);
      expect(method.userId, equals(currentUser.id));
    });

    test('다른 사용자는 내 결제수단을 수정할 수 없음', () async {
      // given
      final methodId = 'method-1';
      final currentUserId = 'user-1';
      final otherUserId = 'user-2';

      // when & then
      expect(
        () => repository.updatePaymentMethod(id: methodId, name: 'New Name'),
        throwsException, // RLS 정책에 의해 실패
      );
    });
  });
}
```

---

## 🚀 배포 체크리스트

- [ ] 데이터베이스 마이그레이션 실행
- [ ] PaymentMethod 엔티티 수정 완료
- [ ] Repository 메서드 추가 완료
- [ ] Provider 추가 완료
- [ ] UI 페이지 수정 완료
- [ ] 단위 테스트 작성 및 통과
- [ ] 통합 테스트 작성 및 통과
- [ ] E2E 테스트 업데이트 (Maestro)
- [ ] 데이터 마이그레이션 스크립트 준비 (필요시)
- [ ] 사용자 가이드 작성
- [ ] 배포 전 QA 완료

