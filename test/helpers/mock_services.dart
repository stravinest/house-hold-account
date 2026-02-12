import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/data/services/google_sign_in_service.dart';
import 'package:shared_household_account/features/notification/data/services/notification_service.dart';
import 'package:shared_household_account/features/notification/services/firebase_messaging_service.dart';
import 'package:shared_household_account/features/notification/services/local_notification_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/app_badge_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/auto_save_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/category_mapping_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/debug_test_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/duplicate_check_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/native_notification_sync_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/sms_listener_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/sms_parsing_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/sms_scanner_service.dart';
import 'package:shared_household_account/features/settings/data/services/export_service.dart';
import 'package:shared_household_account/features/widget/data/services/widget_data_service.dart';

// Auth Services
class MockGoogleSignInService extends Mock implements GoogleSignInService {}

// Notification Services
class MockNotificationService extends Mock implements NotificationService {}

class MockFirebaseMessagingService extends Mock
    implements FirebaseMessagingService {}

class MockLocalNotificationService extends Mock
    implements LocalNotificationService {}

// Payment Method Services
class MockSmsParsingService extends Mock implements SmsParsingService {}

class MockSmsListenerService extends Mock implements SmsListenerService {}

class MockSmsScannerService extends Mock implements SmsScannerService {}

class MockAutoSaveService extends Mock implements AutoSaveService {}

class MockCategoryMappingService extends Mock
    implements CategoryMappingService {}

class MockDuplicateCheckService extends Mock
    implements DuplicateCheckService {}

class MockNativeNotificationSyncService extends Mock
    implements NativeNotificationSyncService {}

class MockDebugTestService extends Mock implements DebugTestService {}

class MockAppBadgeService extends Mock implements AppBadgeService {}

// Settings Services
class MockExportService extends Mock implements ExportService {}

// Widget Services
class MockWidgetDataService extends Mock implements WidgetDataService {}
