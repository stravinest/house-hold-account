import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/asset/data/repositories/asset_repository.dart';
import 'package:shared_household_account/features/category/data/repositories/category_repository.dart';
import 'package:shared_household_account/features/fixed_expense/data/repositories/fixed_expense_category_repository.dart';
import 'package:shared_household_account/features/fixed_expense/data/repositories/fixed_expense_settings_repository.dart';
import 'package:shared_household_account/features/ledger/data/repositories/ledger_repository.dart';
import 'package:shared_household_account/features/notification/data/repositories/fcm_token_repository.dart';
import 'package:shared_household_account/features/notification/data/repositories/notification_settings_repository.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/learned_push_format_repository.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/learned_sms_format_repository.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/payment_method_repository.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/pending_transaction_repository.dart';
import 'package:shared_household_account/features/share/data/repositories/share_repository.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/transaction/data/repositories/transaction_repository.dart';

// Ledger Repository Mock
class MockLedgerRepository extends Mock implements LedgerRepository {}

// Transaction Repository Mock
class MockTransactionRepository extends Mock implements TransactionRepository {}

// Category Repository Mock
class MockCategoryRepository extends Mock implements CategoryRepository {}

// Asset Repository Mock
class MockAssetRepository extends Mock implements AssetRepository {}

// Statistics Repository Mock
class MockStatisticsRepository extends Mock implements StatisticsRepository {}

// Payment Method Repository Mock
class MockPaymentMethodRepository extends Mock
    implements PaymentMethodRepository {}

// Pending Transaction Repository Mock
class MockPendingTransactionRepository extends Mock
    implements PendingTransactionRepository {}

// Learned SMS Format Repository Mock
class MockLearnedSmsFormatRepository extends Mock
    implements LearnedSmsFormatRepository {}

// Learned Push Format Repository Mock
class MockLearnedPushFormatRepository extends Mock
    implements LearnedPushFormatRepository {}

// Share Repository Mock
class MockShareRepository extends Mock implements ShareRepository {}

// FCM Token Repository Mock
class MockFcmTokenRepository extends Mock implements FcmTokenRepository {}

// Notification Settings Repository Mock
class MockNotificationSettingsRepository extends Mock
    implements NotificationSettingsRepository {}

// Fixed Expense Category Repository Mock
class MockFixedExpenseCategoryRepository extends Mock
    implements FixedExpenseCategoryRepository {}

// Fixed Expense Settings Repository Mock
class MockFixedExpenseSettingsRepository extends Mock
    implements FixedExpenseSettingsRepository {}
