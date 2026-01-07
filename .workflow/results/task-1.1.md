# 프로필(Profile) 관련 코드 탐색 보고서

## 1. Profile Entity 정의 위치 및 구조

**현재 상황**: 독립적인 Profile Entity가 없습니다.

- **위치**: Profile 데이터는 Supabase의 `auth.users` 테이블과 `profiles` 테이블에 분산되어 있음
- **주요 필드 (profiles 테이블)**:
  ```sql
  - id: UUID (PRIMARY KEY, auth.users.id 참조)
  - email: TEXT (NOT NULL)
  - display_name: TEXT (선택사항)
  - avatar_url: TEXT (선택사항)
  - created_at: TIMESTAMPTZ (기본값: NOW())
  - updated_at: TIMESTAMPTZ (기본값: NOW())
  ```

- **스키마 위치**: `supabase/migrations/001_initial_schema.sql` (8-15행)

## 2. Profile 관련 Repository

**현재 상황**: 독립적인 ProfileRepository가 없습니다. 프로필 작업이 AuthService에 통합되어 있습니다.

**위치**: `lib/features/auth/presentation/providers/auth_provider.dart`

**주요 메서드**:

```dart
// 프로필 업데이트 (206-218행)
Future<void> updateProfile({
  String? displayName,
  String? avatarUrl,
}) async {
  if (currentUser == null) return;

  final updates = <String, dynamic>{};
  if (displayName != null) updates['display_name'] = displayName;
  if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
  updates['updated_at'] = DateTime.now().toIso8601String();

  await _client.from('profiles').update(updates).eq('id', currentUser!.id);
}

// 프로필 조회 (221-231행)
Future<Map<String, dynamic>?> getProfile() async {
  if (currentUser == null) return null;

  final response = await _client
      .from('profiles')
      .select()
      .eq('id', currentUser!.id)
      .single();

  return response;
}
```

**AuthService 클래스 특징**:
- 싱글톤 패턴: `SupabaseConfig.client`를 통해 Supabase 클라이언트 사용
- 직접 SQL 쿼리 수행 (Supabase RLS 정책에 의해 보호됨)
- 데이터 검증 없이 직접 업데이트

## 3. Profile 관련 Provider

**위치**: `lib/features/auth/presentation/providers/auth_provider.dart`

**현재 Provider들**:

```dart
// 인증 상태 스트림 (10-12행)
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseConfig.auth.onAuthStateChange.map((event) => event.session?.user);
});

// 현재 사용자 (15-18행)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

// AuthService (26-29행)
final authServiceProvider = Provider<AuthService>((ref) {
  final ledgerRepository = ref.watch(ledgerRepositoryProvider);
  return AuthService(ledgerRepository);
});

// AuthNotifier (310-314행)
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
```

**상태관리 방식**:
- Riverpod의 `StateNotifierProvider` 사용
- `AsyncValue<User?>` 상태로 로딩/에러/데이터 상태 관리
- 프로필 데이터는 `getProfile()`을 통해 필요할 때만 조회

## 4. 프로필 관련 UI 구현

**프로필 편집 (TODO)**:
- 위치: `lib/features/settings/presentation/pages/settings_page.dart` (85-90행)
- 현재 구현되지 않음 (TODO 주석만 있음)

**회원가입/로그인 시 프로필 생성**:
- 위치: `lib/features/auth/presentation/pages/signup_page.dart`
- `signUpWithEmail`에서 `displayName` 전달 (53행)
- Supabase 트리거 `handle_new_user()`가 자동으로 프로필 생성 (migration 330-338행)

## 5. 색상 필드 추가 시 고려사항

### 5.1 데이터베이스 변경

새로운 마이그레이션 파일 필요: `006_add_profile_color.sql`

```sql
ALTER TABLE profiles ADD COLUMN color VARCHAR(7) DEFAULT '#A8D8EA';
COMMENT ON COLUMN profiles.color IS '사용자 고유 색상 (HEX 코드)';
```

### 5.2 AuthService 확장

```dart
Future<void> updateProfile({
  String? displayName,
  String? avatarUrl,
  String? color,  // 추가
}) async {
  if (currentUser == null) return;

  final updates = <String, dynamic>{};
  if (displayName != null) updates['display_name'] = displayName;
  if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
  if (color != null) updates['color'] = color;  // 추가
  updates['updated_at'] = DateTime.now().toIso8601String();

  await _client.from('profiles').update(updates).eq('id', currentUser!.id);
}
```

### 5.3 새로운 Provider 추가 (선택사항)

프로필 데이터를 캐싱하고 반응형으로 관리:

```dart
final userProfileProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield null;
    return;
  }

  final stream = SupabaseConfig.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id);

  await for (final data in stream) {
    yield data.isNotEmpty ? data.first : null;
  }
});

final userColorProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile?['color'] ?? '#A8D8EA';
});
```

## 요약

- **Profile Entity**: 없음 (직접 Supabase `profiles` 테이블 사용)
- **Repository**: 없음 (AuthService에 통합)
- **Provider**: `authStateProvider`, `currentUserProvider`, `authServiceProvider`, `authNotifierProvider`
- **상태관리**: Riverpod StreamProvider + StateNotifierProvider
- **DB 스키마**: 6개 필드 (id, email, display_name, avatar_url, created_at, updated_at)
- **프로필 편집**: 미구현 (TODO)

## 권장 사항

색상 필드 추가는 다음 순서로 진행:
1. DB 마이그레이션 파일 작성 및 실행
2. AuthService의 `updateProfile()` 메서드 확장
3. 새로운 Provider 추가 (userProfileProvider, userColorProvider)
4. UI에서 색상 선택 및 업데이트 기능 구현

기존 아키텍처 변경은 최소화되며, 확장성 있게 구현 가능합니다.
