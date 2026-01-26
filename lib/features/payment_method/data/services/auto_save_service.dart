import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'native_notification_sync_service.dart';
import 'notification_listener_wrapper.dart';
import 'sms_listener_service.dart';

enum AutoSaveStatus { notInitialized, initializing, running, stopped, error }

class AutoSaveService {
  AutoSaveService._();

  static AutoSaveService? _instance;
  static AutoSaveService get instance {
    _instance ??= AutoSaveService._();
    return _instance!;
  }

  AutoSaveStatus _status = AutoSaveStatus.notInitialized;
  String? _currentUserId;
  String? _currentLedgerId;
  String? _lastError;

  // Getters for current context
  String? get currentUserId => _currentUserId;
  String? get currentLedgerId => _currentLedgerId;

  StreamSubscription<SmsProcessedEvent>? _smsSubscription;
  StreamSubscription<NotificationProcessedEvent>? _notificationSubscription;
  StreamSubscription<NewNotificationEvent>? _nativeNotificationSubscription;

  final _onTransactionDetectedController =
      StreamController<TransactionDetectedEvent>.broadcast();
  Stream<TransactionDetectedEvent> get onTransactionDetected =>
      _onTransactionDetectedController.stream;

  /// 네이티브에서 새 알림이 수신되었을 때 발생하는 이벤트 스트림
  /// UI에서 배지 업데이트 등에 사용
  final _onNativeNotificationController =
      StreamController<NewNotificationEvent>.broadcast();
  Stream<NewNotificationEvent> get onNativeNotification =>
      _onNativeNotificationController.stream;

  final _onStatusChangedController =
      StreamController<AutoSaveStatus>.broadcast();
  Stream<AutoSaveStatus> get onStatusChanged =>
      _onStatusChangedController.stream;

  bool get isAndroid => Platform.isAndroid;
  AutoSaveStatus get status => _status;
  String? get lastError => _lastError;
  bool get isRunning => _status == AutoSaveStatus.running;

  Future<void> initialize({
    required String userId,
    required String ledgerId,
  }) async {
    if (!isAndroid) {
      debugPrint('AutoSaveService is only available on Android');
      return;
    }

    if (_status == AutoSaveStatus.initializing) {
      debugPrint('AutoSaveService is already initializing');
      return;
    }

    _updateStatus(AutoSaveStatus.initializing);

    try {
      _currentUserId = userId;
      _currentLedgerId = ledgerId;

      await SmsListenerService.instance.initialize(
        userId: userId,
        ledgerId: ledgerId,
      );

      await NotificationListenerWrapper.instance.initialize(
        userId: userId,
        ledgerId: ledgerId,
      );

      _setupEventListeners();

      debugPrint('AutoSaveService initialized');
    } catch (e) {
      _lastError = e.toString();
      _updateStatus(AutoSaveStatus.error);
      debugPrint('AutoSaveService initialization failed: $e');
      rethrow;
    }
  }

  void _setupEventListeners() {
    _smsSubscription?.cancel();
    _notificationSubscription?.cancel();

    _smsSubscription = SmsListenerService.instance.onSmsProcessed.listen(
      _onSmsProcessed,
      onError: (error) {
        debugPrint('SMS event stream error: $error');
      },
    );

    _notificationSubscription = NotificationListenerWrapper
        .instance
        .onNotificationProcessed
        .listen(
          _onNotificationProcessed,
          onError: (error) {
            debugPrint('Notification event stream error: $error');
          },
        );
  }

  void _onSmsProcessed(SmsProcessedEvent event) {
    _onTransactionDetectedController.add(
      TransactionDetectedEvent(
        source: TransactionSource.sms,
        sender: event.sender,
        content: event.content,
        success: event.success,
        reason: event.reason,
        autoSaveMode: event.autoSaveMode,
        parsedAmount: event.parsedAmount,
        parsedMerchant: event.parsedMerchant,
      ),
    );
  }

  void _onNotificationProcessed(NotificationProcessedEvent event) {
    _onTransactionDetectedController.add(
      TransactionDetectedEvent(
        source: TransactionSource.notification,
        sender: event.packageName,
        content: event.content,
        success: event.success,
        reason: event.reason,
        autoSaveMode: event.autoSaveMode,
        parsedAmount: event.parsedAmount,
        parsedMerchant: event.parsedMerchant,
      ),
    );
  }

  void start() {
    if (!isAndroid) return;
    if (_status != AutoSaveStatus.notInitialized &&
        _status != AutoSaveStatus.stopped &&
        _status != AutoSaveStatus.error) {
      if (_status == AutoSaveStatus.running) {
        debugPrint('AutoSaveService is already running');
        return;
      }
    }

    if (!SmsListenerService.instance.isInitialized ||
        !NotificationListenerWrapper.instance.isInitialized) {
      debugPrint('AutoSaveService not initialized. Call initialize() first.');
      return;
    }

    SmsListenerService.instance.startListening();
    NotificationListenerWrapper.instance.startListening();

    // 네이티브 알림 이벤트 채널 구독 시작
    _startNativeNotificationListener();

    _updateStatus(AutoSaveStatus.running);
    debugPrint('AutoSaveService started');
  }

  void _startNativeNotificationListener() {
    if (!isAndroid) return;

    NativeNotificationSyncService.instance.startListening();
    _nativeNotificationSubscription?.cancel();
    _nativeNotificationSubscription = NativeNotificationSyncService
        .instance
        .onNewNotification
        .listen((event) async {
      if (kDebugMode) {
        debugPrint('[AutoSave] Native notification received: ${event.packageName}');
      }

      // 네이티브 캐시 동기화 실행
      if (NotificationListenerWrapper.instance.isInitialized) {
        await NotificationListenerWrapper.instance.syncCachedNotifications();
      }

      // UI 업데이트를 위해 이벤트 전파
      _onNativeNotificationController.add(event);
    });
  }

  void stop() {
    if (!isAndroid) return;

    SmsListenerService.instance.stopListening();
    NotificationListenerWrapper.instance.stopListening();

    // 네이티브 알림 이벤트 구독 정지
    _nativeNotificationSubscription?.cancel();
    _nativeNotificationSubscription = null;
    NativeNotificationSyncService.instance.stopListening();

    _updateStatus(AutoSaveStatus.stopped);
    debugPrint('AutoSaveService stopped');
  }

  Future<void> refreshPaymentMethods() async {
    await SmsListenerService.instance.refreshPaymentMethods();
    await NotificationListenerWrapper.instance.refreshPaymentMethods();
    debugPrint('Payment methods refreshed');
  }

  Future<void> updateLedger({
    required String userId,
    required String ledgerId,
  }) async {
    final wasRunning = isRunning;

    if (wasRunning) {
      stop();
    }

    _currentUserId = userId;
    _currentLedgerId = ledgerId;

    await SmsListenerService.instance.initialize(
      userId: userId,
      ledgerId: ledgerId,
    );

    await NotificationListenerWrapper.instance.initialize(
      userId: userId,
      ledgerId: ledgerId,
    );

    if (wasRunning) {
      start();
    }

    debugPrint('AutoSaveService updated for ledger: $ledgerId');
  }

  Future<PermissionStatus> checkPermissions() async {
    if (!isAndroid) {
      return const PermissionStatus(
        smsGranted: false,
        notificationGranted: false,
        isAndroid: false,
      );
    }

    final smsGranted = await SmsListenerService.instance.checkPermissions();
    final notificationGranted = await NotificationListenerWrapper.instance
        .isPermissionGranted();

    return PermissionStatus(
      smsGranted: smsGranted,
      notificationGranted: notificationGranted,
      isAndroid: true,
    );
  }

  Future<bool> requestSmsPermission() async {
    if (!isAndroid) return false;
    return await SmsListenerService.instance.requestPermissions();
  }

  Future<bool> requestNotificationPermission() async {
    if (!isAndroid) return false;
    return await NotificationListenerWrapper.instance.requestPermission();
  }

  Future<void> processPastSms({int days = 7, int maxCount = 100}) async {
    if (!isAndroid) return;
    await SmsListenerService.instance.processPastSms(
      days: days,
      maxCount: maxCount,
    );
  }

  void _updateStatus(AutoSaveStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    _onStatusChangedController.add(newStatus);
  }

  void dispose() {
    stop();
    _smsSubscription?.cancel();
    _notificationSubscription?.cancel();
    _nativeNotificationSubscription?.cancel();
    _onTransactionDetectedController.close();
    _onStatusChangedController.close();
    _onNativeNotificationController.close();
    SmsListenerService.instance.dispose();
    NotificationListenerWrapper.instance.dispose();
    _currentUserId = null;
    _currentLedgerId = null;
    _lastError = null;
    _status = AutoSaveStatus.notInitialized;
    _instance = null;
  }
}

enum TransactionSource { sms, notification }

class TransactionDetectedEvent {
  final TransactionSource source;
  final String sender;
  final String content;
  final bool success;
  final String? reason;
  final String? autoSaveMode;
  final int? parsedAmount;
  final String? parsedMerchant;

  const TransactionDetectedEvent({
    required this.source,
    required this.sender,
    required this.content,
    required this.success,
    this.reason,
    this.autoSaveMode,
    this.parsedAmount,
    this.parsedMerchant,
  });

  bool get isFromSms => source == TransactionSource.sms;
  bool get isFromNotification => source == TransactionSource.notification;
}

class PermissionStatus {
  final bool smsGranted;
  final bool notificationGranted;
  final bool isAndroid;

  const PermissionStatus({
    required this.smsGranted,
    required this.notificationGranted,
    required this.isAndroid,
  });

  bool get allGranted => smsGranted && notificationGranted;
  bool get anyGranted => smsGranted || notificationGranted;
  bool get noneGranted => !smsGranted && !notificationGranted;
}
