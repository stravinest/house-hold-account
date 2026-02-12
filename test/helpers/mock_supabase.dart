import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// SupabaseClient Mock - 유일한 Mock 클래스
// from(), rpc(), auth 등에 대해 when/thenAnswer 사용
class MockSupabaseClient extends Mock implements SupabaseClient {}

// GoTrueClient Mock (Auth) - Future를 구현하지 않으므로 Mock 사용 가능
class MockGoTrueClient extends Mock implements GoTrueClient {}

// User Mock
class MockUser extends Mock implements User {}

// Session Mock
class MockSession extends Mock implements Session {}

// RealtimeChannel Mock
class MockRealtimeChannel extends Mock implements RealtimeChannel {}

// RealtimeClient Mock
class MockRealtimeClient extends Mock implements RealtimeClient {}

// StorageFileApi Mock
class MockStorageFileApi extends Mock implements StorageFileApi {}

// SupabaseStorageClient Mock
class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

// AuthResponse Mock
class MockAuthResponse extends Mock implements AuthResponse {}

// UserResponse Mock
class MockUserResponse extends Mock implements UserResponse {}

// FunctionsClient Mock
class MockFunctionsClient extends Mock implements FunctionsClient {}

// FunctionResponse Mock
class MockFunctionResponse extends Mock implements FunctionResponse {}

// ================================================================
// Fake Supabase 빌더들
// PostgrestBuilder가 Future<T>를 구현하므로 Mock 대신 Fake를 사용합니다.
// mocktail의 when/thenReturn이 Future 구현 객체와 충돌하기 때문입니다.
// ================================================================

/// FakeSupabaseQueryBuilder - from() 호출 시 반환되는 Fake 객체
/// select, insert, update, delete, upsert 체인의 시작점
class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> _selectData;
  final Map<String, dynamic>? _singleData;
  final Map<String, dynamic>? _maybeSingleData;
  final bool _hasMaybeSingleData;

  FakeSupabaseQueryBuilder({
    List<Map<String, dynamic>>? selectData,
    Map<String, dynamic>? singleData,
    Map<String, dynamic>? maybeSingleData,
    bool hasMaybeSingleData = false,
  })  : _selectData = selectData ?? [],
        _singleData = singleData,
        _maybeSingleData = maybeSingleData,
        _hasMaybeSingleData = hasMaybeSingleData;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return FakePostgrestFilterBuilder<PostgrestList>(
      _selectData,
      singleData: _singleData,
      maybeSingleData: _maybeSingleData,
      hasMaybeSingleData: _hasMaybeSingleData,
    );
  }

  @override
  PostgrestFilterBuilder<PostgrestList> insert(Object values, {bool defaultToNull = true}) {
    return FakePostgrestFilterBuilder<PostgrestList>(
      _selectData,
      singleData: _singleData,
      maybeSingleData: _maybeSingleData,
      hasMaybeSingleData: _hasMaybeSingleData,
    );
  }

  @override
  PostgrestFilterBuilder<PostgrestList> update(Map values) {
    return FakePostgrestFilterBuilder<PostgrestList>(
      _selectData,
      singleData: _singleData,
      maybeSingleData: _maybeSingleData,
      hasMaybeSingleData: _hasMaybeSingleData,
    );
  }

  @override
  PostgrestFilterBuilder<PostgrestList> delete() {
    return FakePostgrestFilterBuilder<PostgrestList>(
      _selectData,
      singleData: _singleData,
      maybeSingleData: _maybeSingleData,
      hasMaybeSingleData: _hasMaybeSingleData,
    );
  }

  @override
  PostgrestFilterBuilder<PostgrestList> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    return FakePostgrestFilterBuilder<PostgrestList>(
      _selectData,
      singleData: _singleData,
      maybeSingleData: _maybeSingleData,
      hasMaybeSingleData: _hasMaybeSingleData,
    );
  }

}

/// FakePostgrestFilterBuilder - 필터 체인 처리
/// eq, neq, gte, lte, order, limit 등의 필터 메서드와
/// select, single, maybeSingle 등의 변환 메서드를 처리
class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final T _data;
  final Map<String, dynamic>? _singleData;
  final Map<String, dynamic>? _maybeSingleData;
  final bool _hasMaybeSingleData;

  FakePostgrestFilterBuilder(
    this._data, {
    Map<String, dynamic>? singleData,
    Map<String, dynamic>? maybeSingleData,
    bool hasMaybeSingleData = false,
  })  : _singleData = singleData,
        _maybeSingleData = maybeSingleData,
        _hasMaybeSingleData = hasMaybeSingleData;

  // 필터 메서드들 - 자기 자신을 반환
  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<T> neq(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<T> gt(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<T> gte(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<T> lt(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<T> lte(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<T> inFilter(String column, List values) => this;
  @override
  PostgrestFilterBuilder<T> isFilter(String column, Object? value) => this;

  // transform 메서드들
  @override
  PostgrestFilterBuilder<T> order(String column,
          {bool ascending = true,
          bool nullsFirst = false,
          String? referencedTable}) =>
      this;

  @override
  PostgrestFilterBuilder<T> limit(int count, {String? referencedTable}) => this;

  // select - 체인에서 select()가 호출되는 경우 (insert().select(), update().select() 등)
  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) {
    final listData = _data is PostgrestList ? _data as PostgrestList : <Map<String, dynamic>>[];
    return FakePostgrestTransformBuilder<PostgrestList>(
      listData,
      singleData: _singleData,
      maybeSingleData: _maybeSingleData,
      hasMaybeSingleData: _hasMaybeSingleData,
    );
  }

  @override
  PostgrestTransformBuilder<PostgrestMap> single() {
    if (_singleData != null) {
      return FakePostgrestTransformBuilder<PostgrestMap>(_singleData);
    }
    if (_data is PostgrestList && (_data as PostgrestList).isNotEmpty) {
      return FakePostgrestTransformBuilder<PostgrestMap>(
          (_data as PostgrestList).first);
    }
    return FakePostgrestTransformBuilder<PostgrestMap>({});
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    if (_hasMaybeSingleData) {
      return FakePostgrestTransformBuilder<PostgrestMap?>(_maybeSingleData);
    }
    if (_data is PostgrestList && (_data as PostgrestList).isNotEmpty) {
      return FakePostgrestTransformBuilder<PostgrestMap?>(
          (_data as PostgrestList).first);
    }
    return FakePostgrestTransformBuilder<PostgrestMap?>(null);
  }

  // Future 메서드들
  @override
  Future<S> then<S>(FutureOr<S> Function(T value) onValue,
      {Function? onError}) {
    return Future<T>.value(_data).then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError,
      {bool Function(Object error)? test}) {
    return Future<T>.value(_data).catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return Future<T>.value(_data).whenComplete(action);
  }

  @override
  Future<T> timeout(Duration timeLimit,
      {FutureOr<T> Function()? onTimeout}) {
    return Future<T>.value(_data).timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Stream<T> asStream() {
    return Future<T>.value(_data).asStream();
  }
}

/// FakePostgrestTransformBuilder - single(), maybeSingle() 처리
class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  final T _data;
  final Map<String, dynamic>? _singleData;
  final Map<String, dynamic>? _maybeSingleData;
  final bool _hasMaybeSingleData;

  FakePostgrestTransformBuilder(
    this._data, {
    Map<String, dynamic>? singleData,
    Map<String, dynamic>? maybeSingleData,
    bool hasMaybeSingleData = false,
  })  : _singleData = singleData,
        _maybeSingleData = maybeSingleData,
        _hasMaybeSingleData = hasMaybeSingleData;

  @override
  PostgrestTransformBuilder<PostgrestMap> single() {
    if (_singleData != null) {
      return FakePostgrestTransformBuilder<PostgrestMap>(_singleData);
    }
    if (_data is PostgrestList && (_data as PostgrestList).isNotEmpty) {
      return FakePostgrestTransformBuilder<PostgrestMap>(
          (_data as PostgrestList).first);
    }
    return FakePostgrestTransformBuilder<PostgrestMap>(
        _data is PostgrestMap ? _data as PostgrestMap : {});
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    if (_hasMaybeSingleData) {
      return FakePostgrestTransformBuilder<PostgrestMap?>(_maybeSingleData);
    }
    if (_data is PostgrestList && (_data as PostgrestList).isNotEmpty) {
      return FakePostgrestTransformBuilder<PostgrestMap?>(
          (_data as PostgrestList).first);
    }
    return FakePostgrestTransformBuilder<PostgrestMap?>(
        _data is PostgrestMap ? _data as PostgrestMap : null);
  }

  // Future 메서드들
  @override
  Future<S> then<S>(FutureOr<S> Function(T value) onValue,
      {Function? onError}) {
    return Future<T>.value(_data).then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError,
      {bool Function(Object error)? test}) {
    return Future<T>.value(_data).catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return Future<T>.value(_data).whenComplete(action);
  }

  @override
  Future<T> timeout(Duration timeLimit,
      {FutureOr<T> Function()? onTimeout}) {
    return Future<T>.value(_data).timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Stream<T> asStream() {
    return Future<T>.value(_data).asStream();
  }
}

// ================================================================
// 하위 호환성을 위한 레거시 Mock 클래스들 (다른 테스트에서 사용)
// 주의: 이 Mock들은 PostgrestBuilder가 Future를 구현하므로
// when/thenReturn과 함께 사용하면 안 됩니다.
// thenAnswer를 사용하거나, 위의 Fake 클래스를 사용하세요.
// ================================================================

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {}

class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

class MockPostgrestBuilder<T, R, C> extends Mock
    implements PostgrestBuilder<T, R, C> {}
