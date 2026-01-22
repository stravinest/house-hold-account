# 멤버별 결제수단 관리 UI 디자인 시안

**생성일:** 2026-01-22
**목적:** 공유 가계부에서 각 멤버가 자신의 결제수단을 독립적으로 관리

---

## 📋 요구사항 분석

### 현재 상황
- ✅ 개인 가계부: 본인 결제수단만 관리 (기존 유지)
- ❌ 공유 가계부: 모든 결제수단이 공유됨 (문제)

### 변경 목표
```
공유 가계부에서:
├─ A의 결제수단 (A만 생성/수정/삭제)
│  ├─ 신한카드
│  ├─ 카카오페이
│  └─ 현금
│
└─ B의 결제수단 (B만 생성/수정/삭제)
   ├─ 우리카드
   ├─ 토스
   └─ 현금

거래 추가 시: 둘 다 선택 가능 (A도 B의 카드로 결제 기록 가능)
결제수단 관리: 본인 것만 수정 가능
```

### 핵심 원칙
1. **소유권**: 각 결제수단은 생성한 멤버가 소유
2. **읽기 권한**: 모든 멤버가 조회 가능 (거래 기록 시 선택 가능)
3. **쓰기 권한**: 소유자만 수정/삭제 가능
4. **시각적 구분**: 누구의 결제수단인지 명확하게 표시

---

## 🎨 디자인 시안

---

## 시안 1: 멤버별 탭 방식 (추천 ⭐⭐⭐⭐⭐)

### 화면 구조
```
┌─────────────────────────────────────────┐
│ ← 결제수단 관리                    ⋮    │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────┬─────────────┐         │
│  │  나 (김철수)  │    파트너    │         │
│  └─────────────┴─────────────┘         │
│   ▔▔▔▔▔▔▔▔▔                           │
│                                         │
│  💳 내 결제수단                          │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 💳 신한카드 (1234)              │   │
│  │    ✏️ 수정하기                  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 💳 카카오페이                   │   │
│  │    ✏️ 수정하기                  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 💵 현금                         │   │
│  │    ✏️ 수정하기                  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [+ 결제수단 추가]                      │
│                                         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ ← 결제수단 관리                    ⋮    │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────┬─────────────┐         │
│  │     나      │ 파트너 (이영희) │         │
│  └─────────────┴─────────────┘         │
│                  ▔▔▔▔▔▔▔▔▔▔▔          │
│                                         │
│  💳 파트너의 결제수단                    │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 💳 우리카드 (5678)              │   │
│  │    👁️ 조회만 가능               │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 💳 토스                         │   │
│  │    👁️ 조회만 가능               │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ℹ️ 파트너의 결제수단은 조회만 가능합니다 │
│                                         │
└─────────────────────────────────────────┘
```

### 장점
- ✅ **명확한 구분**: 탭으로 소유권이 명확하게 구분됨
- ✅ **직관적**: "내 것", "파트너 것" 개념이 쉬움
- ✅ **확장 가능**: 멤버가 늘어나도 탭만 추가
- ✅ **기존 패턴 활용**: 이미 결제수단 관리에서 탭 사용 중

### 단점
- ⚠️ 전체 결제수단을 한눈에 보기 어려움

### 구현 코드 예시
```dart
class PaymentMethodManagementPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<PaymentMethodManagementPage> createState() => _State();
}

class _State extends ConsumerState<PaymentMethodManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final members = ref.read(ledgerMembersProvider);
    _tabController = TabController(
      length: members.length,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final members = ref.watch(ledgerMembersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('결제수단 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: members.map((member) {
            final isMe = member.userId == currentUser?.id;
            return Tab(
              text: isMe ? '나 (${member.nickname})' : member.nickname,
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: members.map((member) {
          return PaymentMethodListView(
            memberId: member.userId,
            isOwner: member.userId == currentUser?.id,
          );
        }).toList(),
      ),
    );
  }
}
```

---

## 시안 2: 섹션 구분 방식 (추천 ⭐⭐⭐⭐)

### 화면 구조
```
┌─────────────────────────────────────────┐
│ ← 결제수단 관리                    ⋮    │
├─────────────────────────────────────────┤
│                                         │
│  👤 김철수 (나)               [+ 추가]  │
│  ─────────────────────────────────────  │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 💳 신한카드 (1234)       ✏️ 수정 │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 💳 카카오페이             ✏️ 수정 │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 💵 현금                   ✏️ 수정 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  👤 이영희 (파트너)                     │
│  ─────────────────────────────────────  │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 💳 우리카드 (5678)       👁️ 조회 │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 💳 토스                   👁️ 조회 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ℹ️ 파트너의 결제수단은 조회만 가능합니다 │
│                                         │
└─────────────────────────────────────────┘
```

### 장점
- ✅ **전체 조망**: 모든 결제수단을 한 화면에서 확인 가능
- ✅ **빠른 비교**: 멤버별 결제수단을 쉽게 비교 가능
- ✅ **스크롤 편의**: 위아래로 스크롤만 하면 됨

### 단점
- ⚠️ 결제수단이 많으면 스크롤이 길어짐
- ⚠️ 섹션 구분이 명확하지 않으면 혼란 가능

### 구현 코드 예시
```dart
class PaymentMethodManagementPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final members = ref.watch(ledgerMembersProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('결제수단 관리')),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          final isMe = member.userId == currentUser?.id;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                icon: Icons.person,
                title: isMe ? '${member.nickname} (나)' : member.nickname,
                trailing: isMe
                    ? IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _addPaymentMethod(context),
                      )
                    : null,
              ),
              PaymentMethodListView(
                memberId: member.userId,
                isOwner: isMe,
              ),
              SizedBox(height: Spacing.xl),
            ],
          );
        },
      ),
    );
  }
}
```

---

## 시안 3: 드롭다운 필터 방식 (추천 ⭐⭐⭐)

### 화면 구조
```
┌─────────────────────────────────────────┐
│ ← 결제수단 관리                    ⋮    │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 👤 김철수 (나)            ▼     │   │
│  └─────────────────────────────────┘   │
│  ┌───────────────────────────────────┐ │
│  │ ✓ 전체 보기                       │ │
│  │   김철수 (나)                     │ │
│  │   이영희 (파트너)                 │ │
│  └───────────────────────────────────┘ │
│                                         │
│  💳 내 결제수단                          │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 💳 신한카드 (1234)       ✏️ 수정 │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 💳 카카오페이             ✏️ 수정 │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 💵 현금                   ✏️ 수정 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [+ 결제수단 추가]                      │
│                                         │
└─────────────────────────────────────────┘
```

### 장점
- ✅ **공간 효율**: 드롭다운으로 공간 절약
- ✅ **선택의 유연성**: 전체/개인별 선택 가능
- ✅ **확장 가능**: 멤버가 많아도 드롭다운에 추가

### 단점
- ⚠️ 한 번의 추가 클릭 필요 (드롭다운 열기)
- ⚠️ 선택된 멤버를 잊어버릴 수 있음

### 구현 코드 예시
```dart
class PaymentMethodManagementPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<PaymentMethodManagementPage> createState() => _State();
}

class _State extends ConsumerState<PaymentMethodManagementPage> {
  String? _selectedMemberId; // null이면 "전체"

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final members = ref.watch(ledgerMembersProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('결제수단 관리')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(Spacing.md),
            child: DropdownButton<String?>(
              value: _selectedMemberId,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('✓ 전체 보기'),
                ),
                ...members.map((member) {
                  final isMe = member.userId == currentUser?.id;
                  return DropdownMenuItem(
                    value: member.userId,
                    child: Text(isMe ? '${member.nickname} (나)' : member.nickname),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedMemberId = value);
              },
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedMemberId == null) {
      // 전체 보기 (시안 2와 동일)
      return _buildAllMembersView();
    } else {
      // 특정 멤버만 보기
      return PaymentMethodListView(
        memberId: _selectedMemberId!,
        isOwner: _selectedMemberId == ref.read(currentUserProvider)?.id,
      );
    }
  }
}
```

---

## 시안 4: 카드 기반 멤버 선택 (추천 ⭐⭐⭐)

### 화면 구조
```
┌─────────────────────────────────────────┐
│ ← 결제수단 관리                    ⋮    │
├─────────────────────────────────────────┤
│                                         │
│  누구의 결제수단을 관리하시겠습니까?      │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │                                 │   │
│  │         👤 김철수 (나)           │   │
│  │                                 │   │
│  │    💳 3개의 결제수단              │   │
│  │    ✏️ 수정 가능                  │   │
│  │                                 │   │
│  │         [관리하기 →]             │   │
│  │                                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │                                 │   │
│  │        👤 이영희 (파트너)         │   │
│  │                                 │   │
│  │    💳 2개의 결제수단              │   │
│  │    👁️ 조회만 가능                │   │
│  │                                 │   │
│  │         [보기 →]                 │   │
│  │                                 │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘

선택 후:
┌─────────────────────────────────────────┐
│ ← 김철수 (나)의 결제수단              ⋮    │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 💳 신한카드 (1234)       ✏️ 수정 │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 💳 카카오페이             ✏️ 수정 │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 💵 현금                   ✏️ 수정 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [+ 결제수단 추가]                      │
│                                         │
└─────────────────────────────────────────┘
```

### 장점
- ✅ **명확한 플로우**: 멤버 선택 → 결제수단 관리
- ✅ **시각적 임팩트**: 카드 UI로 선택하기 쉬움
- ✅ **권한 표시**: 각 카드에 권한이 명확히 표시

### 단점
- ⚠️ 한 단계 추가됨 (멤버 선택 화면)
- ⚠️ 빠른 전환이 어려움 (뒤로가기 필요)

### 구현 코드 예시
```dart
// 1단계: 멤버 선택
class PaymentMethodMemberSelectionPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final members = ref.watch(ledgerMembersProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('결제수단 관리')),
      body: ListView(
        padding: EdgeInsets.all(Spacing.md),
        children: [
          Text(
            '누구의 결제수단을 관리하시겠습니까?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: Spacing.lg),
          ...members.map((member) {
            final isMe = member.userId == currentUser?.id;
            final paymentMethodCount = ref.watch(
              paymentMethodCountProvider(member.userId),
            );
            
            return AppCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentMethodDetailPage(
                      memberId: member.userId,
                      memberName: member.nickname,
                      isOwner: isMe,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Icon(Icons.person, size: IconSize.xxl),
                  SizedBox(height: Spacing.sm),
                  Text(
                    isMe ? '${member.nickname} (나)' : member.nickname,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: Spacing.xs),
                  Text('💳 ${paymentMethodCount}개의 결제수단'),
                  Text(isMe ? '✏️ 수정 가능' : '👁️ 조회만 가능'),
                  SizedBox(height: Spacing.md),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text(isMe ? '관리하기 →' : '보기 →'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// 2단계: 결제수단 목록
class PaymentMethodDetailPage extends ConsumerWidget {
  final String memberId;
  final String memberName;
  final bool isOwner;

  // ... 결제수단 목록 표시
}
```

---

## 시안 5: 색상 구분 방식 (추천 ⭐⭐)

### 화면 구조
```
┌─────────────────────────────────────────┐
│ ← 결제수단 관리                    ⋮    │
├─────────────────────────────────────────┤
│                                         │
│  💳 모든 결제수단                        │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🟦 💳 신한카드 (1234)   ✏️ 수정  │   │
│  │    김철수 (나)                   │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🟦 💳 카카오페이         ✏️ 수정  │   │
│  │    김철수 (나)                   │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🟦 💵 현금               ✏️ 수정  │   │
│  │    김철수 (나)                   │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🟨 💳 우리카드 (5678)    👁️ 조회 │   │
│  │    이영희 (파트너)               │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🟨 💳 토스               👁️ 조회 │   │
│  │    이영희 (파트너)               │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [+ 결제수단 추가]                      │
│                                         │
└─────────────────────────────────────────┘
```

### 장점
- ✅ **한눈에 구분**: 색상으로 소유자 즉시 파악
- ✅ **전체 조망**: 모든 결제수단을 한 화면에
- ✅ **기존 색상 활용**: 프로필 색상 재사용 가능

### 단점
- ⚠️ 정렬이 섞여 있어 혼란 가능
- ⚠️ 본인 결제수단 찾기 어려움

---

## 📊 시안 비교표

| 항목 | 시안 1 (탭) | 시안 2 (섹션) | 시안 3 (드롭다운) | 시안 4 (카드) | 시안 5 (색상) |
|------|------------|--------------|-----------------|--------------|--------------|
| **구분 명확성** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **전체 조망** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **사용 편의성** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **구현 복잡도** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **확장성** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **기존 패턴** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |

---

## 🎯 최종 추천

### 1순위: 시안 1 (멤버별 탭 방식) ⭐⭐⭐⭐⭐

**추천 이유:**
- ✅ 현재 결제수단 관리 페이지에서 이미 탭을 사용 중 (SMS/거래내역)
- ✅ 소유권 구분이 가장 명확함
- ✅ "내 것"과 "상대방 것"의 개념이 직관적
- ✅ 구현이 상대적으로 간단
- ✅ 거래 추가 시 혼란 최소화

**사용 시나리오:**
```
1. 결제수단 관리 진입
2. 기본적으로 "나" 탭이 선택됨
3. 내 결제수단 추가/수정/삭제
4. 파트너 탭 클릭 → 파트너 결제수단 조회
5. "조회만 가능합니다" 안내 표시
```

### 2순위: 시안 2 (섹션 구분 방식) ⭐⭐⭐⭐

**추천 이유:**
- ✅ 전체 결제수단을 한눈에 비교 가능
- ✅ 스크롤만으로 모든 정보 확인
- ✅ 섹션 헤더로 명확한 구분

**적합한 경우:**
- 결제수단이 많지 않을 때 (각 멤버당 3개 이하)
- 전체 조망이 중요한 경우

---

## 🛠️ 데이터베이스 스키마 변경

### 현재 스키마
```sql
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY,
  ledger_id UUID NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 변경 후 스키마
```sql
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY,
  ledger_id UUID NOT NULL,
  owner_user_id UUID NOT NULL,  -- 추가: 소유자
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (owner_user_id) REFERENCES profiles(id)
);
```

### 마이그레이션 파일
```sql
-- filepath: supabase/migrations/023_add_payment_method_owner.sql

-- 1. owner_user_id 컬럼 추가 (nullable로 먼저 추가)
ALTER TABLE house.payment_methods 
ADD COLUMN owner_user_id UUID REFERENCES house.profiles(id);

-- 2. 기존 데이터 마이그레이션
-- 개인 가계부: 가계부 생성자를 소유자로 설정
UPDATE house.payment_methods pm
SET owner_user_id = l.created_by
FROM house.ledgers l
WHERE pm.ledger_id = l.id
  AND l.is_shared = false;

-- 공유 가계부: 첫 번째 멤버를 소유자로 설정 (임시)
UPDATE house.payment_methods pm
SET owner_user_id = (
  SELECT user_id 
  FROM house.ledger_members 
  WHERE ledger_id = pm.ledger_id 
  ORDER BY joined_at ASC 
  LIMIT 1
)
WHERE owner_user_id IS NULL;

-- 3. NOT NULL 제약조건 추가
ALTER TABLE house.payment_methods 
ALTER COLUMN owner_user_id SET NOT NULL;

-- 4. 인덱스 추가
CREATE INDEX idx_payment_methods_owner 
ON house.payment_methods(owner_user_id);

-- 5. RLS 정책 수정
DROP POLICY IF EXISTS "payment_methods_select" ON house.payment_methods;
CREATE POLICY "payment_methods_select"
ON house.payment_methods FOR SELECT
USING (
  ledger_id IN (
    SELECT ledger_id 
    FROM house.ledger_members 
    WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "payment_methods_insert" ON house.payment_methods;
CREATE POLICY "payment_methods_insert"
ON house.payment_methods FOR INSERT
WITH CHECK (
  ledger_id IN (
    SELECT ledger_id 
    FROM house.ledger_members 
    WHERE user_id = auth.uid()
  )
  AND owner_user_id = auth.uid()  -- 본인 소유만 생성 가능
);

DROP POLICY IF EXISTS "payment_methods_update" ON house.payment_methods;
CREATE POLICY "payment_methods_update"
ON house.payment_methods FOR UPDATE
USING (owner_user_id = auth.uid())  -- 본인 소유만 수정 가능
WITH CHECK (owner_user_id = auth.uid());

DROP POLICY IF EXISTS "payment_methods_delete" ON house.payment_methods;
CREATE POLICY "payment_methods_delete"
ON house.payment_methods FOR DELETE
USING (owner_user_id = auth.uid());  -- 본인 소유만 삭제 가능
```

---

## 📱 UI 구현 순서

### Phase 1: 데이터베이스 변경
1. ✅ 마이그레이션 파일 작성
2. ✅ RLS 정책 업데이트
3. ✅ 기존 데이터 마이그레이션

### Phase 2: 모델 & Repository 수정
1. `PaymentMethodModel`에 `ownerUserId` 필드 추가
2. `PaymentMethodRepository`에 `ownerUserId` 파라미터 추가
3. 권한 체크 로직 추가

### Phase 3: Provider 수정
1. `paymentMethodProvider`에 멤버별 필터링 추가
2. 권한 체크 Provider 추가 (`canEditPaymentMethodProvider`)

### Phase 4: UI 구현 (시안 1 기준)
1. `PaymentMethodManagementPage`에 TabController 추가
2. 멤버 목록 조회 (ledgerMembersProvider 활용)
3. 탭별 결제수단 목록 표시
4. 권한에 따른 버튼 활성화/비활성화
5. 안내 메시지 표시

---

## 🎨 디자인 토큰 활용

```dart
// 소유자 표시 색상
final ownerColor = Theme.of(context).colorScheme.primary;
final otherColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

// 카드 스타일
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: isOwner ? ownerColor : otherColor,
      width: 2,
    ),
    borderRadius: BorderRadius.circular(BorderRadiusToken.md),
  ),
  padding: EdgeInsets.all(Spacing.md),
  // ...
)
```

---

## ❓ 고려사항

### Q1: 공유 가계부에서 상대방 결제수단으로 거래를 기록할 수 있나요?
**A:** 네! 거래 추가 시에는 모든 멤버의 결제수단을 선택할 수 있습니다.
- 예: A가 "B의 우리카드"로 결제한 경우를 기록 가능

### Q2: 결제수단 삭제 시 기존 거래는 어떻게 되나요?
**A:** 거래는 유지되고 결제수단 이름만 표시됩니다.
- DB에서 `payment_method_id`는 유지
- UI에서 "삭제된 결제수단 (우리카드)" 형태로 표시

### Q3: 공유 가계부를 개인 가계부로 전환하면?
**A:** 모든 결제수단이 그대로 유지됩니다.
- `owner_user_id`는 변경 없음
- 이전 파트너의 결제수단도 조회 가능

---

## 📝 다음 단계

사용자가 시안을 선택하면:
1. 데이터베이스 마이그레이션 파일 생성
2. 모델 및 Repository 수정
3. Provider 수정
4. UI 구현
5. 테스트 코드 작성
6. E2E 테스트 (Maestro)

**어떤 시안을 선택하시겠습니까?**
