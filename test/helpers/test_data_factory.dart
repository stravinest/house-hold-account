import 'package:shared_household_account/features/category/data/models/category_model.dart';
import 'package:shared_household_account/features/category/domain/entities/category.dart';
import 'package:shared_household_account/features/ledger/data/models/ledger_model.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/payment_method/data/models/payment_method_model.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';
import 'package:shared_household_account/features/transaction/data/models/transaction_model.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';

/// 테스트용 데이터를 생성하는 Factory 클래스
///
/// 사용 예시:
/// ```dart
/// final ledger = TestDataFactory.ledger();
/// final transaction = TestDataFactory.transaction(ledgerId: ledger.id);
/// ```
class TestDataFactory {
  // 기본 날짜
  static final DateTime defaultDate = DateTime(2026, 2, 12);

  // Ledger 생성
  static Ledger ledger({
    String id = 'test-ledger-id',
    String name = '테스트 가계부',
    String currency = 'KRW',
    String ownerId = 'test-owner-id',
    bool isShared = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return Ledger(
      id: id,
      name: name,
      currency: currency,
      ownerId: ownerId,
      isShared: isShared,
      createdAt: createdAt ?? defaultDate,
      updatedAt: updatedAt ?? defaultDate,
      description: description,
    );
  }

  // LedgerModel 생성
  static LedgerModel ledgerModel({
    String id = 'test-ledger-id',
    String name = '테스트 가계부',
    String currency = 'KRW',
    String ownerId = 'test-owner-id',
    bool isShared = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return LedgerModel(
      id: id,
      name: name,
      currency: currency,
      ownerId: ownerId,
      isShared: isShared,
      createdAt: createdAt ?? defaultDate,
      updatedAt: updatedAt ?? defaultDate,
      description: description,
    );
  }

  // Category 생성
  static Category category({
    String id = 'test-category-id',
    String ledgerId = 'test-ledger-id',
    String name = '식비',
    String icon = '🍔',
    String color = '#FF5733',
    String type = 'expense',
    bool isDefault = false,
    int sortOrder = 0,
    DateTime? createdAt,
  }) {
    return Category(
      id: id,
      ledgerId: ledgerId,
      name: name,
      icon: icon,
      color: color,
      type: type,
      isDefault: isDefault,
      sortOrder: sortOrder,
      createdAt: createdAt ?? defaultDate,
    );
  }

  // CategoryModel 생성
  static CategoryModel categoryModel({
    String id = 'test-category-id',
    String ledgerId = 'test-ledger-id',
    String name = '식비',
    String icon = '🍔',
    String color = '#FF5733',
    String type = 'expense',
    bool isDefault = false,
    int sortOrder = 0,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id,
      ledgerId: ledgerId,
      name: name,
      icon: icon,
      color: color,
      type: type,
      isDefault: isDefault,
      sortOrder: sortOrder,
      createdAt: createdAt ?? defaultDate,
    );
  }

  // Transaction 생성
  static Transaction transaction({
    String id = 'test-transaction-id',
    String ledgerId = 'test-ledger-id',
    String userId = 'test-user-id',
    String? categoryId = 'test-category-id',
    String? paymentMethodId,
    int amount = 10000,
    String type = 'expense',
    DateTime? date,
    String? title = '테스트 거래',
    String? memo,
    String? imageUrl,
    bool isRecurring = false,
    String? recurringType,
    DateTime? recurringEndDate,
    bool isFixedExpense = false,
    String? fixedExpenseCategoryId,
    bool isAsset = false,
    DateTime? maturityDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? userName,
    String? userColor,
    String? paymentMethodName,
    String? fixedExpenseCategoryName,
    String? fixedExpenseCategoryColor,
  }) {
    return Transaction(
      id: id,
      ledgerId: ledgerId,
      userId: userId,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      amount: amount,
      type: type,
      date: date ?? defaultDate,
      title: title,
      memo: memo,
      imageUrl: imageUrl,
      isRecurring: isRecurring,
      recurringType: recurringType,
      recurringEndDate: recurringEndDate,
      isFixedExpense: isFixedExpense,
      fixedExpenseCategoryId: fixedExpenseCategoryId,
      isAsset: isAsset,
      maturityDate: maturityDate,
      createdAt: createdAt ?? defaultDate,
      updatedAt: updatedAt ?? defaultDate,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
      userName: userName,
      userColor: userColor,
      paymentMethodName: paymentMethodName,
      fixedExpenseCategoryName: fixedExpenseCategoryName,
      fixedExpenseCategoryColor: fixedExpenseCategoryColor,
    );
  }

  // TransactionModel 생성
  static TransactionModel transactionModel({
    String id = 'test-transaction-id',
    String ledgerId = 'test-ledger-id',
    String userId = 'test-user-id',
    String? categoryId = 'test-category-id',
    String? paymentMethodId,
    int amount = 10000,
    String type = 'expense',
    DateTime? date,
    String? title = '테스트 거래',
    String? memo,
    String? imageUrl,
    bool isRecurring = false,
    String? recurringType,
    DateTime? recurringEndDate,
    bool isFixedExpense = false,
    String? fixedExpenseCategoryId,
    bool isAsset = false,
    DateTime? maturityDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? userName,
    String? userColor,
    String? paymentMethodName,
    String? fixedExpenseCategoryName,
    String? fixedExpenseCategoryColor,
  }) {
    return TransactionModel(
      id: id,
      ledgerId: ledgerId,
      userId: userId,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      amount: amount,
      type: type,
      date: date ?? defaultDate,
      title: title,
      memo: memo,
      imageUrl: imageUrl,
      isRecurring: isRecurring,
      recurringType: recurringType,
      recurringEndDate: recurringEndDate,
      isFixedExpense: isFixedExpense,
      fixedExpenseCategoryId: fixedExpenseCategoryId,
      isAsset: isAsset,
      maturityDate: maturityDate,
      createdAt: createdAt ?? defaultDate,
      updatedAt: updatedAt ?? defaultDate,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
      userName: userName,
      userColor: userColor,
      paymentMethodName: paymentMethodName,
      fixedExpenseCategoryName: fixedExpenseCategoryName,
      fixedExpenseCategoryColor: fixedExpenseCategoryColor,
    );
  }

  // PaymentMethod 생성
  static PaymentMethod paymentMethod({
    String id = 'test-payment-method-id',
    String ledgerId = 'test-ledger-id',
    String ownerUserId = 'test-owner-id',
    String name = '신한카드',
    String icon = '💳',
    String color = '#4A90E2',
    bool isDefault = false,
    int sortOrder = 0,
    AutoSaveMode autoSaveMode = AutoSaveMode.manual,
    String? defaultCategoryId,
    bool canAutoSave = false,
    AutoCollectSource autoCollectSource = AutoCollectSource.sms,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id,
      ledgerId: ledgerId,
      ownerUserId: ownerUserId,
      name: name,
      icon: icon,
      color: color,
      isDefault: isDefault,
      sortOrder: sortOrder,
      autoSaveMode: autoSaveMode,
      defaultCategoryId: defaultCategoryId,
      canAutoSave: canAutoSave,
      autoCollectSource: autoCollectSource,
      createdAt: createdAt ?? defaultDate,
    );
  }

  // PaymentMethodModel 생성
  static PaymentMethodModel paymentMethodModel({
    String id = 'test-payment-method-id',
    String ledgerId = 'test-ledger-id',
    String ownerUserId = 'test-owner-id',
    String name = '신한카드',
    String icon = '💳',
    String color = '#4A90E2',
    bool isDefault = false,
    int sortOrder = 0,
    AutoSaveMode autoSaveMode = AutoSaveMode.manual,
    String? defaultCategoryId,
    bool canAutoSave = false,
    AutoCollectSource autoCollectSource = AutoCollectSource.sms,
    DateTime? createdAt,
  }) {
    return PaymentMethodModel(
      id: id,
      ledgerId: ledgerId,
      ownerUserId: ownerUserId,
      name: name,
      icon: icon,
      color: color,
      isDefault: isDefault,
      sortOrder: sortOrder,
      autoSaveMode: autoSaveMode,
      defaultCategoryId: defaultCategoryId,
      canAutoSave: canAutoSave,
      autoCollectSource: autoCollectSource,
      createdAt: createdAt ?? defaultDate,
    );
  }

  // 여러 거래 목록 생성
  static List<Transaction> transactions({
    int count = 5,
    String ledgerId = 'test-ledger-id',
    String userId = 'test-user-id',
  }) {
    return List.generate(
      count,
      (index) => transaction(
        id: 'test-transaction-id-$index',
        ledgerId: ledgerId,
        userId: userId,
        amount: 10000 * (index + 1),
        title: '테스트 거래 ${index + 1}',
        date: defaultDate.add(Duration(days: index)),
      ),
    );
  }

  // 여러 카테고리 목록 생성
  static List<Category> categories({
    int count = 5,
    String ledgerId = 'test-ledger-id',
    String type = 'expense',
  }) {
    final icons = ['🍔', '🚗', '🏠', '💊', '🎮'];
    final names = ['식비', '교통비', '주거비', '의료비', '여가비'];

    return List.generate(
      count,
      (index) => category(
        id: 'test-category-id-$index',
        ledgerId: ledgerId,
        name: names[index % names.length],
        icon: icons[index % icons.length],
        type: type,
        sortOrder: index,
      ),
    );
  }
}
