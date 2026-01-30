import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_badge_service.dart';

/// 네이티브 SQLite에 저장된 알림을 Flutter로 동기화하는 서비스
/// 앱이 종료되어도 네이티브 서비스가 금융 알림을 수집하여 저장하고,
/// 앱 재시작 시 이 서비스를 통해 Flutter로 동기화
class NativeNotificationSyncService {
  NativeNotificationSyncService._();

  static NativeNotificationSyncService? _instance;
  static NativeNotificationSyncService get instance {
    _instance ??= NativeNotificationSyncService._();
    return _instance!;
  }

  static const String _channelName = 'com.household.shared/notification_sync';
  static const String _eventChannelName =
      'com.household.shared/notification_events';
  static const MethodChannel _channel = MethodChannel(_channelName);
  static const EventChannel _eventChannel = EventChannel(_eventChannelName);

  StreamSubscription<dynamic>? _eventSubscription;
  final _onNewNotificationController =
      StreamController<NewNotificationEvent>.broadcast();

  /// 새 알림 이벤트 스트림 (네이티브에서 실시간으로 전달)
  Stream<NewNotificationEvent> get onNewNotification =>
      _onNewNotificationController.stream;

  bool get isSupported => Platform.isAndroid;

  /// EventChannel 구독 시작 (앱 시작 시 호출)
  void startListening() {
    if (!isSupported) return;
    if (_eventSubscription != null) return;

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final type = event['type'] as String?;
          if (type == 'new_notification') {
            final packageName = event['packageName'] as String? ?? '';
            final pendingCount = (event['pendingCount'] as num?)?.toInt() ?? 0;
            if (kDebugMode) {
              debugPrint(
                '[NativeSync] New notification event: $packageName, count: $pendingCount',
              );
            }
            _onNewNotificationController.add(
              NewNotificationEvent(
                packageName: packageName,
                pendingCount: pendingCount,
              ),
            );
            AppBadgeService.instance.updateBadge(pendingCount);
          }
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('[NativeSync] Event channel error: $error');
        }
      },
    );

    if (kDebugMode) {
      debugPrint(
        '[NativeSync] Started listening for native notification events',
      );
    }
  }

  /// EventChannel 구독 중지
  void stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    if (kDebugMode) {
      debugPrint(
        '[NativeSync] Stopped listening for native notification events',
      );
    }
  }

  /// 동기화 대기 중인 알림 목록 조회
  /// 앱 시작 시 호출하여 앱 종료 중 수집된 알림 가져오기
  Future<List<CachedNotification>> getPendingNotifications() async {
    if (!isSupported) return [];

    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getPendingNotifications',
      );
      if (result == null) return [];

      return result.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return CachedNotification.fromMap(map);
      }).toList();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[NativeSync] Error getting pending notifications: ${e.message}',
        );
      }
      return [];
    }
  }

  /// 알림을 동기화됨으로 표시
  /// Flutter에서 처리 완료 후 호출
  Future<int> markAsSynced(List<int> ids) async {
    if (!isSupported || ids.isEmpty) return 0;

    try {
      final result = await _channel.invokeMethod<int>('markAsSynced', {
        'ids': ids,
      });
      if (kDebugMode) {
        debugPrint(
          '[NativeSync] Marked ${result ?? 0} notifications as synced',
        );
      }
      return result ?? 0;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[NativeSync] Error marking as synced: ${e.message}');
      }
      return 0;
    }
  }

  /// 오래된 알림 삭제 (동기화 완료된 것만)
  Future<int> clearOldNotifications({int olderThanDays = 7}) async {
    if (!isSupported) return 0;

    try {
      final result = await _channel.invokeMethod<int>('clearOldNotifications', {
        'days': olderThanDays,
      });
      if (kDebugMode) {
        debugPrint('[NativeSync] Cleared ${result ?? 0} old notifications');
      }
      return result ?? 0;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[NativeSync] Error clearing old notifications: ${e.message}',
        );
      }
      return 0;
    }
  }

  /// 동기화 대기 알림 수 조회
  Future<int> getPendingCount() async {
    if (!isSupported) return 0;

    try {
      final result = await _channel.invokeMethod<int>('getPendingCount');
      return result ?? 0;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[NativeSync] Error getting pending count: ${e.message}');
      }
      return 0;
    }
  }

  /// 영구 실패한 알림 수 조회 (재시도 초과)
  Future<int> getFailedCount() async {
    if (!isSupported) return 0;

    try {
      final result = await _channel.invokeMethod<int>('getFailedCount');
      return result ?? 0;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[NativeSync] Error getting failed count: ${e.message}');
      }
      return 0;
    }
  }

  /// 알림의 재시도 횟수를 1 증가
  /// 처리 실패 시 호출하여 재시도 횟수 추적
  /// 반환값: 새로운 retry_count (3 이상이면 더 이상 재시도하지 않음)
  Future<int> incrementRetryCount(int id) async {
    if (!isSupported) return 0;

    try {
      final result = await _channel.invokeMethod<int>('incrementRetryCount', {
        'id': id,
      });
      if (kDebugMode) {
        debugPrint(
          '[NativeSync] Incremented retry count for id $id to ${result ?? 0}',
        );
      }
      return result ?? 0;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[NativeSync] Error incrementing retry count: ${e.message}');
      }
      return 0;
    }
  }

  /// 모든 알림 삭제 (테스트/디버그용)
  Future<int> clearAll() async {
    if (!isSupported) return 0;

    try {
      final result = await _channel.invokeMethod<int>('clearAll');
      if (kDebugMode) {
        debugPrint('[NativeSync] Cleared all ${result ?? 0} notifications');
      }
      return result ?? 0;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[NativeSync] Error clearing all: ${e.message}');
      }
      return 0;
    }
  }

  /// 리소스 정리
  void dispose() {
    stopListening();
    _onNewNotificationController.close();
  }
}

/// 네이티브에서 전달된 새 알림 이벤트
class NewNotificationEvent {
  final String packageName;
  final int pendingCount;

  const NewNotificationEvent({
    required this.packageName,
    required this.pendingCount,
  });
}

/// 네이티브 SQLite에 캐싱된 알림 데이터
class CachedNotification {
  final int id;
  final String packageName;
  final String? title;
  final String text;
  final DateTime receivedAt;
  final bool isSynced;

  const CachedNotification({
    required this.id,
    required this.packageName,
    this.title,
    required this.text,
    required this.receivedAt,
    required this.isSynced,
  });

  factory CachedNotification.fromMap(Map<String, dynamic> map) {
    // null 안전 캐스팅으로 네이티브 데이터 불일치 방지
    return CachedNotification(
      id: (map['id'] as num?)?.toInt() ?? 0,
      packageName: map['packageName'] as String? ?? '',
      title: map['title'] as String?,
      text: map['text'] as String? ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['receivedAt'] as num?)?.toInt() ?? 0,
      ),
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'CachedNotification(id: $id, package: $packageName, text: ${text.length > 30 ? '${text.substring(0, 30)}...' : text})';
  }
}
