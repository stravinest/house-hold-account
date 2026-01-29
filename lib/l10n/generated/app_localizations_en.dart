// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shared Household';

  @override
  String get appSubtitle =>
      'Manage your household finances\nwith family, couple, or roommates';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDetail => 'Detail';

  @override
  String get commonReject => 'Reject';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Error';

  @override
  String get commonSuccess => 'Success';

  @override
  String get tooltipSearch => 'Search';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get tooltipBook => 'Ledger Management';

  @override
  String get tooltipPreviousMonth => 'Previous Month';

  @override
  String get tooltipNextMonth => 'Next Month';

  @override
  String get tooltipPreviousYear => 'Previous Year';

  @override
  String get tooltipNextYear => 'Next Year';

  @override
  String get tooltipTogglePassword => 'Show/Hide Password';

  @override
  String get tooltipDelete => 'Delete';

  @override
  String get tooltipEdit => 'Edit';

  @override
  String get tooltipClear => 'Clear';

  @override
  String get tooltipEditProfile => 'Edit Profile';

  @override
  String get tooltipClose => 'Close';

  @override
  String get tooltipRefresh => 'Refresh';

  @override
  String get tooltipFilter => 'Filter';

  @override
  String get tooltipSort => 'Sort';

  @override
  String get tooltipInfo => 'Information';

  @override
  String get navTabCalendar => 'Calendar';

  @override
  String get navTabStatistics => 'Statistics';

  @override
  String get navTabAsset => 'Asset';

  @override
  String get navTabMore => 'More';

  @override
  String get authLogin => 'Log In';

  @override
  String get authSignup => 'Sign Up';

  @override
  String get authLogout => 'Log Out';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordConfirm => 'Confirm Password';

  @override
  String get authPasswordShow => 'Show password';

  @override
  String get authPasswordHide => 'Hide password';

  @override
  String get authName => 'Name';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authOr => 'or';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authLoginError =>
      'An error occurred during login. Please try again.';

  @override
  String get authInvalidCredentials => 'Invalid email or password.';

  @override
  String get authEmailNotVerified =>
      'Email not verified. Please check your inbox.';

  @override
  String get authEmailAlreadyRegistered => 'This email is already registered.';

  @override
  String get authSignupTitle => 'Create Account';

  @override
  String get authSignupSubtitle =>
      'Create an account to start\nusing Shared Household';

  @override
  String get authTermsAgreement =>
      'By signing up, you agree to our\nTerms of Service and Privacy Policy.';

  @override
  String get authForgotPasswordTitle => 'Reset Password';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter your email address and we\'ll send you\na link to reset your password.';

  @override
  String get authForgotPasswordSend => 'Send Reset Link';

  @override
  String get authForgotPasswordSent => 'Password reset email sent';

  @override
  String get authForgotPasswordSentSubtitle =>
      'Check your email and click the link\nto reset your password.';

  @override
  String get authForgotPasswordBackToLogin => 'Back to Login';

  @override
  String authForgotPasswordSendFailed(String error) {
    return 'Failed to send email: $error';
  }

  @override
  String get validationEmailRequired => 'Please enter your email';

  @override
  String get validationEmailInvalid => 'Please enter a valid email address';

  @override
  String get validationPasswordRequired => 'Please enter your password';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 6 characters';

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

  @override
  String get validationNameRequired => 'Please enter your name';

  @override
  String get validationNameTooShort => 'Name must be at least 2 characters';

  @override
  String get validationPasswordConfirmRequired =>
      'Please confirm your password';

  @override
  String get emailVerificationTitle => 'Email Verification';

  @override
  String get emailVerificationWaiting => 'Waiting for Email Verification';

  @override
  String get emailVerificationComplete => 'Email Verified!';

  @override
  String get emailVerificationSent =>
      'We sent a verification email to the address above.\nPlease check your inbox and click the verification link.';

  @override
  String get emailVerificationDone =>
      'Verification complete.\nRedirecting to home screen...';

  @override
  String get emailVerificationResent =>
      'Verification email sent. Please check your inbox.';

  @override
  String emailVerificationResendFailed(String error) {
    return 'Failed to send verification email: $error';
  }

  @override
  String get emailVerificationCheckStatus => 'Check Verification Status';

  @override
  String get emailVerificationResendButton => 'Resend Verification Email';

  @override
  String emailVerificationResendCooldown(int seconds) {
    return 'Resend available in ${seconds}s';
  }

  @override
  String get emailVerificationVerified => 'Verified';

  @override
  String get emailVerificationNotVerified => 'Not Verified';

  @override
  String get emailVerificationChecking => 'Checking...';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppSettings => 'App Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsNotification => 'Notifications';

  @override
  String get settingsNotificationDescription =>
      'Receive notifications for shares, invites, etc.';

  @override
  String get settingsNotificationSettings => 'Notification Settings';

  @override
  String get settingsNotificationSettingsDescription =>
      'Configure notification types';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsMyColor => 'My Color';

  @override
  String get settingsColorChanged => 'Color has been changed';

  @override
  String settingsColorChangeFailed(String error) {
    return 'Failed to change color: $error';
  }

  @override
  String get settingsPasswordChange => 'Change Password';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsDataExport => 'Export Data';

  @override
  String get settingsDataExportDescription => 'Export transactions as CSV';

  @override
  String get settingsInfo => 'Information';

  @override
  String get settingsAppInfo => 'App Info';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsTerms => 'Terms of Service';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String get settingsThemeLight => 'Light Mode';

  @override
  String get settingsThemeDark => 'Dark Mode';

  @override
  String get settingsThemeSystem => 'System Default';

  @override
  String settingsThemeSaveFailed(String error) {
    return 'Failed to save theme: $error';
  }

  @override
  String get settingsLogoutConfirm => 'Are you sure you want to log out?';

  @override
  String get settingsDeleteAccountConfirm =>
      'Are you sure you want to delete your account?\n\nAll data will be permanently deleted and cannot be recovered.';

  @override
  String settingsDeleteAccountFailed(String error) {
    return 'Failed to delete account: $error';
  }

  @override
  String get settingsDisplayNameChanged => 'Display name has been changed';

  @override
  String settingsDisplayNameChangeFailed(String error) {
    return 'Failed to change display name: $error';
  }

  @override
  String get settingsDisplayName => 'Display Name';

  @override
  String get settingsPasswordChanged => 'Password has been changed';

  @override
  String get settingsCurrentPassword => 'Current Password';

  @override
  String get settingsCurrentPasswordHint => 'Enter your current password';

  @override
  String get settingsNewPassword => 'New Password';

  @override
  String get settingsNewPasswordHint => 'Enter your new password';

  @override
  String get settingsNewPasswordConfirm => 'Confirm New Password';

  @override
  String get settingsNewPasswordConfirmHint => 'Enter your new password again';

  @override
  String get settingsNewPasswordMismatch => 'New passwords do not match';

  @override
  String get settingsChange => 'Change';

  @override
  String get settingsLanguageKorean => 'Korean';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageChanged => 'Language has been changed';

  @override
  String get settingsFeaturePreparing => 'This feature is coming soon';

  @override
  String get settingsAboutAppName => 'Shared Household Account';

  @override
  String get settingsAboutAppDescription =>
      'A shared household account app built with Flutter + Supabase.';

  @override
  String get settingsAboutAppSubDescription =>
      'Manage expenses together with family, couple, or roommates.';

  @override
  String get ledgerTitle => 'Ledger';

  @override
  String get ledgerManagement => 'Ledger Management';

  @override
  String get ledgerShareManagement => 'Ledger & Share Management';

  @override
  String get ledgerCreate => 'Create Ledger';

  @override
  String get ledgerNew => 'New Ledger';

  @override
  String get ledgerName => 'Ledger Name';

  @override
  String get ledgerNameHint => 'Enter ledger name';

  @override
  String get ledgerDescription => 'Description (Optional)';

  @override
  String get ledgerCurrency => 'Currency';

  @override
  String get ledgerShared => 'Shared Ledger';

  @override
  String get ledgerPersonal => 'Personal Ledger';

  @override
  String get ledgerInUse => 'In Use';

  @override
  String get ledgerEmpty => 'No ledgers';

  @override
  String get ledgerEmptySubtitle => 'Create a ledger to get started';

  @override
  String get ledgerCreated => 'Ledger created';

  @override
  String get ledgerUpdated => 'Ledger updated';

  @override
  String get ledgerDeleted => 'Ledger deleted';

  @override
  String ledgerDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get ledgerDeleteConfirmTitle => 'Delete Ledger';

  @override
  String get ledgerDeleteConfirmMessage =>
      'This ledger is currently in use.\nIt will automatically switch to another ledger after deletion.\n\nAll transactions, categories, and budgets in this ledger will be deleted.\nThis action cannot be undone.';

  @override
  String get ledgerDeleteNotAllowed => 'Cannot Delete';

  @override
  String get ledgerDeleteNotAllowedMessage =>
      'At least one ledger is required.\nPlease create another ledger first.';

  @override
  String get ledgerChangeConfirmTitle => 'Change Ledger';

  @override
  String ledgerChangeConfirmMessage(String name) {
    return 'Do you want to use \'$name\' ledger?';
  }

  @override
  String get ledgerUse => 'Use';

  @override
  String get ledgerMyLedgers => 'My Ledgers';

  @override
  String get ledgerInvitedLedgers => 'Invited Ledgers';

  @override
  String get ledgerSelectorMyLedgers => 'My Ledgers';

  @override
  String get ledgerSelectorSharedLedgers => 'Shared Ledgers';

  @override
  String get shareInvite => 'Invite';

  @override
  String get shareMemberInvite => 'Invite Member';

  @override
  String get shareRole => 'Role';

  @override
  String get shareRoleMember => 'Member';

  @override
  String get shareRoleMemberDescription => 'View/Add/Edit/Delete transactions';

  @override
  String get shareRoleAdmin => 'Admin';

  @override
  String get shareRoleAdminDescription =>
      'Transactions + Category/Budget management + Invite members';

  @override
  String get shareInviteSent => 'Invitation sent';

  @override
  String get shareInviteAccepted => 'Invitation accepted';

  @override
  String get shareInviteRejected => 'Invitation rejected';

  @override
  String get shareInviteCancelled => 'Invitation cancelled';

  @override
  String get shareInviteCancelConfirmTitle => 'Cancel Invitation';

  @override
  String shareInviteCancelConfirmMessage(String email) {
    return 'Cancel the invitation sent to \'$email\'?';
  }

  @override
  String get shareInviteRejectConfirmTitle => 'Reject Invitation';

  @override
  String shareInviteRejectConfirmMessage(String name) {
    return 'Reject the invitation to \'$name\'?\nIt will be removed from the list.';
  }

  @override
  String get shareLeaveConfirmTitle => 'Leave Ledger';

  @override
  String shareLeaveConfirmMessage(String name) {
    return 'Leave \'$name\'?\nYou will no longer have access to this ledger\'s data.';
  }

  @override
  String get shareLeave => 'Leave';

  @override
  String get shareReject => 'Reject';

  @override
  String get categoryTitle => 'Category';

  @override
  String get categoryManagement => 'Category Management';

  @override
  String get categoryAdd => 'Add Category';

  @override
  String get categoryEdit => 'Edit Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameHint => 'Enter category name';

  @override
  String get categoryNameRequired => 'Please enter a category name';

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String categoryDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get categoryDeleteConfirmTitle => 'Delete Category';

  @override
  String get categoryDeleteConfirmMessage =>
      'Transactions with this category will not be deleted.';

  @override
  String get categoryAdded => 'Category added';

  @override
  String categoryEmpty(String type) {
    return 'No $type categories';
  }

  @override
  String get transactionExpense => 'Expense';

  @override
  String get transactionIncome => 'Income';

  @override
  String get transactionAsset => 'Asset';

  @override
  String get transactionTypeLabel => 'Transaction Type';

  @override
  String get transactionTitle => 'Title';

  @override
  String get transactionMerchant => 'Merchant';

  @override
  String get transactionMerchantHint => 'Enter merchant name';

  @override
  String get transactionAmount => 'Amount';

  @override
  String get transactionAmountHint => 'Enter amount';

  @override
  String get transactionAmountUnit => 'KRW';

  @override
  String get noCategoryAvailable => 'No categories available';

  @override
  String get transactionCategory => 'Category';

  @override
  String get transactionPaymentMethod => 'Payment Method';

  @override
  String get transactionPaymentMethodOptional => 'Payment Method (Optional)';

  @override
  String get transactionMemo => 'Memo';

  @override
  String get transactionMemoOptional => 'Memo (Optional)';

  @override
  String get transactionMemoHint => 'Enter additional notes';

  @override
  String get transactionAdded => 'Transaction added';

  @override
  String get transactionUpdated => 'Transaction updated';

  @override
  String get transactionNone => 'None';

  @override
  String get transactionQuickExpense => 'Quick Expense';

  @override
  String get transactionExpenseAdded => 'Expense added';

  @override
  String get transactionAmountRequired => 'Please enter an amount';

  @override
  String get transactionTitleRequired => 'Please enter a title';

  @override
  String get transactionCategoryLoadError => 'Failed to load categories';

  @override
  String get transactionNoTitle => 'No title';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String transactionDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get transactionDeleteConfirmTitle => 'Delete Transaction';

  @override
  String get transactionDeleteConfirmMessage => 'Delete this transaction?';

  @override
  String get labelTitle => 'Title';

  @override
  String get labelMemo => 'Memo';

  @override
  String get labelAmount => 'Amount';

  @override
  String get labelDate => 'Date';

  @override
  String get labelCategory => 'Category';

  @override
  String get labelPaymentMethod => 'Payment Method';

  @override
  String get labelAuthor => 'Author';

  @override
  String get maturityDateSelect => 'Select Maturity Date';

  @override
  String get installmentInfoRequired => 'Please enter installment information';

  @override
  String get installmentLabel => 'Installment';

  @override
  String installmentRegistered(int months) {
    return '$months-month installment registered';
  }

  @override
  String recurringRegistered(String endText) {
    return 'Recurring transaction registered ($endText)';
  }

  @override
  String recurringUntil(int year, int month) {
    return 'Until $month/$year';
  }

  @override
  String get recurringContinue => 'Continuous';

  @override
  String get summaryBalance => 'Balance';

  @override
  String get maturityDateSelectOptional => 'Select Maturity Date (Optional)';

  @override
  String get recurringPeriod => 'Recurring Period';

  @override
  String get recurringNone => 'None';

  @override
  String get recurringDaily => 'Day';

  @override
  String get recurringMonthly => 'Month';

  @override
  String get recurringYearly => 'Year';

  @override
  String get recurringEndDate => 'End Date';

  @override
  String get recurringEndMonth => 'End Month';

  @override
  String get recurringEndYear => 'End Year';

  @override
  String get recurringContinueRepeat => 'Continue repeating';

  @override
  String get recurringClearEndDate => 'Clear end date';

  @override
  String recurringTransactionCount(int count) {
    return '$count transactions will be created';
  }

  @override
  String get recurringDailyAutoCreate =>
      'Continue repeating (auto-create daily)';

  @override
  String get fixedExpenseRegister => 'Register as Fixed Expense';

  @override
  String get fixedExpenseDescription =>
      'Regular expenses like rent, insurance, etc.';

  @override
  String get yearLabel => 'Year';

  @override
  String get monthLabel => 'Month';

  @override
  String yearFormat(int year) {
    return '$year';
  }

  @override
  String monthFormat(int month) {
    return '$month';
  }

  @override
  String get installmentInput => 'Installment Input';

  @override
  String get installmentInputDescription =>
      'Record total amount split across months';

  @override
  String get installmentApplied => 'Installment Applied';

  @override
  String get installmentTotalAmount => 'Total Amount';

  @override
  String get installmentMonthlyPayment => 'Monthly Payment';

  @override
  String get installmentFirstMonth => 'First Month';

  @override
  String get installmentPeriod => 'Installment Period';

  @override
  String installmentMonths(int months) {
    return '$months months';
  }

  @override
  String get installmentEndMonth => 'End Month';

  @override
  String get installmentModify => 'Modify';

  @override
  String get installmentTotalAmountHint => 'Enter total installment amount';

  @override
  String get installmentMonthsLabel => 'Months';

  @override
  String get installmentMonthsHint => '1-60 months';

  @override
  String get installmentPreview => 'Installment Preview';

  @override
  String get installmentApply => 'Apply Installment';

  @override
  String get installmentAmountError => 'Amount must be greater than months';

  @override
  String categoryAddType(String type) {
    return 'Add $type category';
  }

  @override
  String get categoryNameHintExample => 'e.g., Food, Transport';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Delete \'$name\' category?';
  }

  @override
  String get paymentMethodNameHintExample => 'e.g., Credit Card, Cash';

  @override
  String paymentMethodDeleteConfirm(String name) {
    return 'Delete \'$name\' payment method?';
  }

  @override
  String get paymentMethodTitle => 'Payment Method';

  @override
  String get paymentMethodManagement => 'Payment Method Management';

  @override
  String get paymentMethodAdd => 'Add Payment Method';

  @override
  String get paymentMethodEdit => 'Edit Payment Method';

  @override
  String get paymentMethodName => 'Payment Method Name';

  @override
  String get paymentMethodNameHint => 'Enter payment method name';

  @override
  String get paymentMethodNameRequired => 'Please enter a payment method name';

  @override
  String get paymentMethodDeleted => 'Payment method deleted';

  @override
  String paymentMethodDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get paymentMethodDeleteConfirmTitle => 'Delete Payment Method';

  @override
  String get paymentMethodDeleteConfirmMessage =>
      'Payment method info for transactions using this will be removed.';

  @override
  String get paymentMethodAdded => 'Payment method added';

  @override
  String get paymentMethodUpdated => 'Payment method updated';

  @override
  String get paymentMethodEmpty => 'No payment methods';

  @override
  String get paymentMethodNotFound => 'Payment method not found';

  @override
  String get paymentMethodDefault => 'Default Payment Method';

  @override
  String get paymentMethodDetectionKeywords => 'Detection Keywords';

  @override
  String get paymentMethodDetectionKeywordsHint =>
      'Enter comma-separated keywords (e.g., KB Kookmin, KB Kookmin Card)';

  @override
  String get paymentMethodDetectionKeywordsSubtitle =>
      'Automatically detect when these keywords appear in messages';

  @override
  String get paymentMethodAmountPattern => 'Amount Pattern';

  @override
  String get paymentMethodCurrentRules => 'Current Rules for Collection';

  @override
  String get paymentMethodEditKeywords => 'Edit Keywords';

  @override
  String get paymentMethodAmountPatternReadOnly => 'Number before \'Won\'';

  @override
  String get paymentMethodAmountPatternNote =>
      'Amount pattern cannot be modified';

  @override
  String get paymentMethodTab => 'Payment Methods';

  @override
  String get paymentMethodEmptySubtitle =>
      'Add a payment method to get started';

  @override
  String get paymentMethodNoPermissionToDelete =>
      'You do not have permission to delete this payment method';

  @override
  String get paymentMethodOptions => 'Payment Method Options';

  @override
  String get sharedPaymentMethodTitle => 'Shared Payment Methods';

  @override
  String get sharedPaymentMethodDescription => 'Shared with all ledger members';

  @override
  String get sharedPaymentMethodEmpty => 'No shared payment methods';

  @override
  String get sharedPaymentMethodAdd => 'Add Shared Payment Method';

  @override
  String get autoCollectTab => 'Collection History';

  @override
  String get autoCollectTitle => 'Auto Collect';

  @override
  String get autoCollectDescription =>
      'Automatically detect transactions from SMS/Push notifications';

  @override
  String get autoCollectPaymentMethodEmpty => 'No auto-collect payment methods';

  @override
  String get autoCollectPaymentMethodAdd => 'Add Auto Collect';

  @override
  String get autoProcessSettings => 'Auto Process Settings';

  @override
  String get autoSaveModeOff => 'Off';

  @override
  String get autoSaveModeSuggest => 'Suggest';

  @override
  String get autoSaveModeAuto => 'Auto';

  @override
  String get pendingTransactionTab => 'Auto Collect History';

  @override
  String get pendingTransactionStatusPending => 'Pending';

  @override
  String get pendingTransactionStatusConfirmed => 'Confirmed';

  @override
  String get pendingTransactionStatusRejected => 'Rejected';

  @override
  String get pendingTransactionEmptyPending => 'No pending transactions';

  @override
  String get pendingTransactionEmptyConfirmed => 'No confirmed transactions';

  @override
  String get pendingTransactionEmptyRejected => 'No rejected transactions';

  @override
  String get pendingTransactionEmptySubtitle =>
      'Transactions detected from SMS/Push will appear here';

  @override
  String get noAmountInfo => 'No amount info';

  @override
  String get dateGroupToday => 'Today';

  @override
  String get dateGroupYesterday => 'Yesterday';

  @override
  String get dateGroupThisWeek => 'This week';

  @override
  String get dateGroupThisMonth => 'This month';

  @override
  String get dateGroupOlder => 'Older';

  @override
  String get sourceTypeSms => 'SMS';

  @override
  String get sourceTypeNotification => 'Notification';

  @override
  String get pendingTransactionStatusSaved => 'Saved';

  @override
  String get pendingTransactionStatusWaiting => 'Waiting';

  @override
  String get pendingTransactionStatusDenied => 'Denied';

  @override
  String get pendingTransactionParsingFailed =>
      'Unable to parse transaction information';

  @override
  String get pendingTransactionDeleteConfirmTitle => 'Delete Transaction';

  @override
  String get pendingTransactionDeleteConfirmMessage =>
      'Are you sure you want to delete this transaction?';

  @override
  String get pendingTransactionDeleted => 'Transaction deleted';

  @override
  String get pendingTransactionDeleteAll => 'Delete All';

  @override
  String get pendingTransactionDeleteAllConfirmTitle => 'Delete All';

  @override
  String pendingTransactionDeleteAllConfirmMessage(String status, int count) {
    return 'Delete all $count $status items?';
  }

  @override
  String get pendingTransactionDeleteAllSuccess => 'All items deleted';

  @override
  String get pendingTransactionDetail => 'Collection Detail';

  @override
  String get pendingTransactionReject => 'Reject';

  @override
  String get pendingTransactionUpdate => 'Update';

  @override
  String get pendingTransactionConfirm => 'Save';

  @override
  String get pendingTransactionConfirmed => 'Transaction saved';

  @override
  String get pendingTransactionUpdated => 'Updated';

  @override
  String get pendingTransactionRejected => 'Transaction rejected';

  @override
  String pendingTransactionItemCount(int count) {
    return '$count items';
  }

  @override
  String get paymentMethodWizardAddTitle => 'Add Payment Method';

  @override
  String get paymentMethodWizardEditTitle => 'Edit Payment Method';

  @override
  String get paymentMethodWizardManualAddTitle => 'Add Manual Entry';

  @override
  String get paymentMethodWizardAutoCollectAddTitle => 'Add Auto Collect';

  @override
  String get paymentMethodWizardModeQuestion => 'How would you like to add it?';

  @override
  String get paymentMethodWizardManualMode => 'Manual Entry';

  @override
  String get paymentMethodWizardAutoCollectMode => 'Auto Collect';

  @override
  String get paymentMethodWizardSharedBadge => 'Shared';

  @override
  String get paymentMethodWizardPersonalBadge => 'Personal';

  @override
  String get paymentMethodWizardManualDescription =>
      'Simply add by entering a name.\nShared with ledger members.';

  @override
  String get paymentMethodWizardAutoCollectDescription =>
      'Automatically detect transactions from SMS/Push notifications.\nOnly you can use this.';

  @override
  String get paymentMethodWizardServiceQuestion => 'Which service do you use?';

  @override
  String get paymentMethodWizardServiceDescription =>
      'Automatically detect transactions from SMS/Push notifications.';

  @override
  String get paymentMethodWizardCategoryCard => 'Card';

  @override
  String get paymentMethodWizardCategoryLocalCurrency => 'Local Currency';

  @override
  String get paymentMethodWizardCategoryOther => 'Other';

  @override
  String get paymentMethodWizardCustomSetup => 'Custom Setup';

  @override
  String get paymentMethodWizardCustomSetupDescription =>
      'Manually configure unsupported services.';

  @override
  String get paymentMethodWizardSharedNotice =>
      'This payment method is shared with ledger members';

  @override
  String get paymentMethodWizardPersonalNotice =>
      'This payment method is only available to you';

  @override
  String get paymentMethodWizardNameLabel => 'Payment Method Name';

  @override
  String get paymentMethodWizardNameHint => 'e.g., Credit Card, Cash';

  @override
  String get paymentMethodWizardAliasLabel => 'Alias';

  @override
  String get paymentMethodWizardAliasHelper => 'Name displayed in the app.';

  @override
  String get paymentMethodWizardAutoCollectRuleTitle =>
      'Auto Collect Rule Settings';

  @override
  String get paymentMethodWizardImportFromSms => 'Import from SMS';

  @override
  String get paymentMethodWizardKeywordsUpdated =>
      'Keywords have been updated.';

  @override
  String get paymentMethodWizardCollectSource => 'Collection Source';

  @override
  String get paymentMethodWizardSmsSource => 'SMS';

  @override
  String get paymentMethodWizardPushSource => 'Push Notification';

  @override
  String get paymentMethodWizardSampleNotice =>
      'The message below is an example. Please modify if different from your actual notifications.\nCollection rules will be updated accordingly.';

  @override
  String get paymentMethodWizardCurrentRules =>
      'Information collected with current rules';

  @override
  String get paymentMethodWizardDetectionKeywords => 'Detection Keywords';

  @override
  String get paymentMethodWizardAmountPattern => 'Amount Pattern';

  @override
  String get paymentMethodWizardSaveButton => 'Save';

  @override
  String get paymentMethodWizardAddButton => 'Add';

  @override
  String get paymentMethodWizardEditKeywordsTitle => 'Edit Detection Keywords';

  @override
  String get paymentMethodWizardEditKeywordsDescription =>
      'Notifications containing these keywords will be collected.';

  @override
  String get paymentMethodWizardKeywordInputHint => 'Enter new keyword';

  @override
  String get paymentMethodWizardKeywordAdd => 'Add';

  @override
  String get paymentMethodWizardKeywordDuplicate =>
      'This keyword is already registered';

  @override
  String get paymentMethodWizardEditKeywordsMinError =>
      'At least 1 keyword is required';

  @override
  String get paymentMethodWizardSelectSmsTitle => 'Select SMS to import';

  @override
  String get paymentMethodWizardSmsPermissionRequired =>
      'SMS permission is required.';

  @override
  String get paymentMethodWizardNoFinancialSms => 'No financial SMS found.';

  @override
  String get paymentMethodWizardDuplicateName =>
      'A payment method with this name already exists';

  @override
  String get paymentMethodWizardSaveFailed => 'Failed to save payment method';

  @override
  String get paymentMethodWizardKeywordsSaved =>
      'Detection keywords saved successfully';

  @override
  String get paymentMethodWizardKeywordsSaveFailed =>
      'Failed to save detection keywords';

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get errorNetwork => 'Please check your network connection.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errorNotFound => 'Page not found';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get user => 'User';

  @override
  String get homeTitle => 'Home';

  @override
  String get moreMenuShareManagement => 'Ledger & Share Management';

  @override
  String get moreMenuCategoryManagement => 'Category Management';

  @override
  String get moreMenuPaymentMethodManagement => 'Payment Method Management';

  @override
  String get moreMenuFixedExpenseManagement => 'Fixed Expense Management';

  @override
  String get noHistory => 'No history';

  @override
  String get statisticsCategory => 'Category';

  @override
  String get statisticsTrend => 'Trend';

  @override
  String get statisticsPaymentMethod => 'Payment';

  @override
  String get statisticsCategoryDistribution => 'Category Distribution';

  @override
  String get statisticsCategoryComparison => 'Category Comparison';

  @override
  String get statisticsFilterCombined => 'Combined';

  @override
  String get statisticsFilterOverlay => 'Compare';

  @override
  String get statisticsNoData => 'No data available';

  @override
  String get statisticsOther => 'Other';

  @override
  String get statisticsTotalIncome => 'Total Income';

  @override
  String get statisticsTotalExpense => 'Total Expense';

  @override
  String get statisticsTotalAsset => 'Total Asset';

  @override
  String statisticsTotal(String type) {
    return 'Total $type';
  }

  @override
  String get statisticsNoPreviousData => 'No previous month data';

  @override
  String get statisticsIncrease => 'increase';

  @override
  String get statisticsDecrease => 'decrease';

  @override
  String get statisticsSame => 'same';

  @override
  String statisticsVsLastMonth(String percent, String change) {
    return '(vs last month $percent% $change)';
  }

  @override
  String get statisticsFixed => 'Fixed';

  @override
  String get statisticsVariable => 'Variable';

  @override
  String get statisticsAverage => 'Average';

  @override
  String get statisticsDetail => 'Details';

  @override
  String statisticsYearMonth(int year, int month) {
    return '$year. $month';
  }

  @override
  String statisticsYear(int year) {
    return '$year';
  }

  @override
  String get statisticsPaymentDistribution => 'Payment Method Distribution';

  @override
  String get statisticsPaymentRanking => 'Payment Method Ranking';

  @override
  String get statisticsPaymentNotice =>
      'Payment method statistics only show expenses.';

  @override
  String get assetTitle => 'Asset';

  @override
  String get assetTotal => 'Total Assets';

  @override
  String get assetChange => 'Asset Change';

  @override
  String get assetCategoryDistribution => 'Category Distribution';

  @override
  String get assetList => 'Asset List';

  @override
  String assetThisMonth(String change) {
    return 'This month $change';
  }

  @override
  String get assetGoalTitle => 'Goal';

  @override
  String get assetGoalSet => 'Set Goal';

  @override
  String get assetGoalDelete => 'Delete Goal';

  @override
  String assetGoalDeleteConfirm(String title) {
    return 'Delete \'$title\' goal?';
  }

  @override
  String get assetGoalDeleted => 'Goal deleted';

  @override
  String assetGoalDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get assetGoalEmpty =>
      'Set a goal and\nmanage your assets systematically';

  @override
  String get assetGoalCurrent => 'Current';

  @override
  String get assetGoalTarget => 'Target';

  @override
  String assetGoalRemaining(String amount) {
    return '$amount remaining';
  }

  @override
  String get assetGoalAchieved => 'Goal achieved!';

  @override
  String get assetGoalTapForDetails => 'Tap for details';

  @override
  String get assetGoalLoadError => 'Failed to load goal info';

  @override
  String get fixedExpenseTitle => 'Fixed Expense';

  @override
  String get fixedExpenseManagement => 'Fixed Expense Management';

  @override
  String get fixedExpenseCategoryTitle => 'Fixed Expense Categories';

  @override
  String get fixedExpenseIncludeInExpense => 'Include in expenses';

  @override
  String get fixedExpenseIncludeInExpenseOn =>
      'Fixed expenses are included in calendar and statistics';

  @override
  String get fixedExpenseIncludeInExpenseOff =>
      'Fixed expenses are excluded from calendar and statistics';

  @override
  String get fixedExpenseIncludedSnackbar => 'Fixed expenses included';

  @override
  String get fixedExpenseExcludedSnackbar => 'Fixed expenses excluded';

  @override
  String fixedExpenseSettingsFailed(String error) {
    return 'Failed to change settings: $error';
  }

  @override
  String get fixedExpenseSettingsLoadFailed => 'Failed to load settings';

  @override
  String get fixedExpenseCategoryEmpty => 'No fixed expense categories';

  @override
  String get fixedExpenseCategoryEmptySubtitle => 'Tap + to add a category';

  @override
  String get fixedExpenseCategoryDelete => 'Delete Fixed Expense Category';

  @override
  String fixedExpenseCategoryDeleteConfirm(String name) {
    return 'Delete \'$name\' category?';
  }

  @override
  String get fixedExpenseCategoryDeleteMessage =>
      'Fixed expenses with this category will not be deleted.';

  @override
  String get fixedExpenseCategoryAdd => 'Add Fixed Expense Category';

  @override
  String get fixedExpenseCategoryEdit => 'Edit Fixed Expense Category';

  @override
  String get fixedExpenseCategoryNameHint => 'e.g., Rent, Phone Bill';

  @override
  String get categoryUpdated => 'Category updated';

  @override
  String get notificationSettingsTitle => 'Notification Settings';

  @override
  String get notificationSettingsDescription =>
      'Select the notifications you want to receive';

  @override
  String notificationSettingsSaveFailed(String error) {
    return 'Failed to save settings: $error';
  }

  @override
  String get notificationSettingsLoadFailed =>
      'Failed to load notification settings';

  @override
  String get notificationSectionSharedLedger => 'Shared Ledger';

  @override
  String get notificationSharedLedgerChange => 'Shared Ledger Changes';

  @override
  String get notificationSharedLedgerChangeDesc =>
      'Notify when other members add/edit/delete transactions';

  @override
  String get notificationSectionInvite => 'Invitations';

  @override
  String get notificationInviteReceived => 'Ledger Invite Received';

  @override
  String get notificationInviteReceivedDesc =>
      'Notify when another user invites you to a ledger';

  @override
  String get notificationInviteAccepted => 'Invite Accepted';

  @override
  String get notificationInviteAcceptedDesc =>
      'Notify when another user accepts your invitation';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search by title/memo...';

  @override
  String get searchEmpty => 'Search transactions by title or memo';

  @override
  String get searchNoResults => 'No search results';

  @override
  String get searchUncategorized => 'Uncategorized';

  @override
  String get shareManagementTitle => 'Ledger & Share Management';

  @override
  String get shareMyLedgers => 'My Ledgers';

  @override
  String get shareInvitedLedgers => 'Invited Ledgers';

  @override
  String get shareLedgerEmpty => 'No ledgers';

  @override
  String get shareLedgerEmptySubtitle => 'Create a ledger to get started';

  @override
  String get shareCreateLedger => 'Create Ledger';

  @override
  String get shareErrorOccurred => 'An error occurred';

  @override
  String shareLedgerChanged(String name) {
    return 'Switched to \'$name\' ledger';
  }

  @override
  String get shareLedgerLeft => 'Left the ledger';

  @override
  String get shareInviteCancelText => 'Cancel Invite';

  @override
  String get shareInviteSentMessage => 'Invitation sent';

  @override
  String get shareInviteCancelledMessage => 'Invitation cancelled';

  @override
  String get shareInviteAcceptedMessage => 'Invitation accepted';

  @override
  String get shareInviteRejectedMessage => 'Invitation rejected';

  @override
  String get shareEmailHint => 'example@email.com';

  @override
  String get shareInUse => 'In Use';

  @override
  String get shareUse => 'Use';

  @override
  String get shareUnknown => 'Unknown';

  @override
  String get shareMemberParticipating => 'Participating as member';

  @override
  String get shareAccept => 'Accept';

  @override
  String get shareMe => 'Me';

  @override
  String shareMemberCount(int current, int max) {
    return 'Members $current/$max';
  }

  @override
  String get shareMemberFull => 'Members full';

  @override
  String get sharePendingAccept => 'Pending';

  @override
  String get shareAccepted => 'Accepted';

  @override
  String get shareRejected => 'Rejected';

  @override
  String get shareExpired => 'Invite expired';

  @override
  String shareInviterLedger(String email) {
    return '$email\'s ledger';
  }

  @override
  String shareSharingWith(String name) {
    return 'Sharing with $name';
  }

  @override
  String shareSharingWithMultiple(String name1, String name2) {
    return 'Sharing with $name1, $name2';
  }

  @override
  String shareSharingWithMore(String name1, String name2, int count) {
    return 'Sharing with $name1, $name2 and $count more';
  }

  @override
  String get shareMemberManagement => 'Manage Shared Members';

  @override
  String get shareMemberRoleOwner => 'Owner';

  @override
  String get shareMemberRoleAdmin => 'Admin';

  @override
  String get shareMemberRoleMember => 'Member';

  @override
  String get shareMemberRemove => 'Remove';

  @override
  String get shareMemberRemoveTitle => 'Remove Member';

  @override
  String shareMemberRemoveConfirm(String name) {
    return 'Remove \'$name\' from this ledger?\n\nRemoved members will no longer have access to this ledger.';
  }

  @override
  String get shareMemberRemoved => 'Member has been removed';

  @override
  String get ledgerNewTitle => 'New Ledger';

  @override
  String get ledgerEditTitle => 'Edit Ledger';

  @override
  String get ledgerNoLedgers => 'No ledgers registered';

  @override
  String get ledgerCreateButton => 'Create Ledger';

  @override
  String get ledgerNameLabel => 'Ledger Name';

  @override
  String get ledgerNameRequired => 'Please enter a ledger name';

  @override
  String get ledgerDescriptionLabel => 'Description (Optional)';

  @override
  String get ledgerCurrencyLabel => 'Currency';

  @override
  String get ledgerDeleteNotAllowedTitle => 'Cannot Delete';

  @override
  String get ledgerDeleteNotAllowedContent =>
      'At least one ledger is required.\nPlease create another ledger first.';

  @override
  String get ledgerMemberLoading => 'Loading member info...';

  @override
  String ledgerDeleteConfirmWithName(String name) {
    return 'Delete \'$name\' ledger?\n\nAll transactions, categories, and budgets in this ledger will be deleted.\nThis action cannot be undone.';
  }

  @override
  String get ledgerDeleteCurrentInUseWarning =>
      'This is the currently active ledger.\nAfter deletion, another ledger will be selected.\n\n';

  @override
  String ledgerSharedWithOne(String name) {
    return 'Shared with $name';
  }

  @override
  String ledgerSharedWithTwo(String name1, String name2) {
    return 'Shared with $name1, $name2';
  }

  @override
  String ledgerSharedWithMany(String name1, String name2, int count) {
    return 'Shared with $name1, $name2 and $count others';
  }

  @override
  String get ledgerUser => 'User';

  @override
  String get calendarDaySun => 'Sun';

  @override
  String get calendarDayMon => 'Mon';

  @override
  String get calendarDayTue => 'Tue';

  @override
  String get calendarDayWed => 'Wed';

  @override
  String get calendarDayThu => 'Thu';

  @override
  String get calendarDayFri => 'Fri';

  @override
  String get calendarDaySat => 'Sat';

  @override
  String get calendarToday => 'Today';

  @override
  String calendarYearMonth(int year, int month) {
    return '$month/$year';
  }

  @override
  String get calendarCategoryBreakdown => 'Category breakdown';

  @override
  String get calendarNoRecords => 'No records';

  @override
  String calendarTransactionCount(int count) {
    return '$count items';
  }

  @override
  String get calendarNewTransaction => 'New Transaction';

  @override
  String get calendarTransactionDelete => 'Delete Transaction';

  @override
  String get calendarTransactionDeleteConfirm => 'Delete this transaction?';

  @override
  String get calendarViewDaily => 'Daily';

  @override
  String get calendarViewWeekly => 'Weekly';

  @override
  String get calendarViewMonthly => 'Monthly';

  @override
  String calendarDailyDate(int year, int month, int day) {
    return '$month/$day/$year';
  }

  @override
  String calendarWeeklyRange(
    int startMonth,
    int startDay,
    int endMonth,
    int endDay,
  ) {
    return '$startMonth/$startDay ~ $endMonth/$endDay';
  }

  @override
  String get settingsWeekStartDay => 'Week Start Day';

  @override
  String get settingsWeekStartDayDescription =>
      'Start day for calendar weekly view';

  @override
  String get settingsWeekStartSunday => 'Sunday';

  @override
  String get settingsWeekStartMonday => 'Monday';

  @override
  String get assetNoData => 'No data';

  @override
  String get assetOther => 'Others';

  @override
  String get assetNoAsset => 'No assets';

  @override
  String get assetNoAssetData => 'No asset data';

  @override
  String get assetGoalNew => 'Set New Goal';

  @override
  String get assetGoalEdit => 'Edit Goal';

  @override
  String get assetGoalAmount => 'Target Amount';

  @override
  String get assetGoalAmountRequired => 'Please enter target amount';

  @override
  String get assetGoalAmountInvalid => 'Please enter valid amount';

  @override
  String get assetGoalDateOptional => 'Target Date (Optional)';

  @override
  String get assetGoalDateHint => 'Select target date';

  @override
  String get assetGoalCreate => 'Create Goal';

  @override
  String get assetGoalCreated => 'Goal created';

  @override
  String get assetGoalUpdated => 'Goal updated';

  @override
  String get assetLedgerRequired => 'Please select a ledger';

  @override
  String get assetGoalAchievementRate => 'Progress';

  @override
  String get assetGoalCurrentAmount => 'Current';

  @override
  String get assetGoalTargetAmount => 'Target';

  @override
  String assetGoalDaysPassed(int days) {
    return '$days days passed';
  }

  @override
  String assetGoalDaysRemaining(int days) {
    return 'D-$days';
  }

  @override
  String get assetGoalCompleted => 'Completed';

  @override
  String get assetGoalNone => 'No goals set';

  @override
  String get assetGoalDeleteTitle => 'Delete Goal';

  @override
  String assetGoalDeleteMessage(String title) {
    return 'Delete \'$title\' goal?';
  }

  @override
  String assetMonth(int month) {
    return '$month';
  }

  @override
  String get fixedExpenseCategoryName => 'Category Name';

  @override
  String get fixedExpenseCategoryNameRequired => 'Please enter category name';

  @override
  String get fixedExpenseCategoryAdded => 'Fixed expense category added';

  @override
  String get fixedExpenseCategoryDeleted => 'Fixed expense category deleted';

  @override
  String get fixedExpenseCategoryNone => 'None';

  @override
  String get paymentMethodOptional => 'Payment Method (Optional)';

  @override
  String get statisticsPeriodMonthly => 'Monthly';

  @override
  String get statisticsPeriodYearly => 'Yearly';

  @override
  String get statisticsTypeIncome => 'Income';

  @override
  String get statisticsTypeExpense => 'Expense';

  @override
  String get statisticsTypeAsset => 'Asset';

  @override
  String get statisticsExpenseAll => 'All';

  @override
  String get statisticsExpenseFixed => 'Fixed';

  @override
  String get statisticsExpenseVariable => 'Variable';

  @override
  String get statisticsExpenseAllDesc => 'All expenses';

  @override
  String get statisticsExpenseFixedDesc =>
      'Recurring expenses like rent, insurance';

  @override
  String get statisticsExpenseVariableDesc => 'Expenses excluding fixed costs';

  @override
  String get statisticsDateSelect => 'Select Date';

  @override
  String get statisticsToday => 'Today';

  @override
  String statisticsYearLabel(int year) {
    return '$year';
  }

  @override
  String statisticsMonthLabel(int month) {
    return '$month';
  }

  @override
  String statisticsYearMonthFormat(int year, int month) {
    return '$month/$year';
  }

  @override
  String get categoryUncategorized => 'Uncategorized';

  @override
  String get categoryFixedExpense => 'Fixed Expense';

  @override
  String get categoryUnknown => 'Unknown';

  @override
  String get defaultCategoryFood => 'Food';

  @override
  String get defaultCategoryTransport => 'Transport';

  @override
  String get defaultCategoryShopping => 'Shopping';

  @override
  String get defaultCategoryLiving => 'Living';

  @override
  String get defaultCategoryTelecom => 'Telecom';

  @override
  String get defaultCategoryMedical => 'Medical';

  @override
  String get defaultCategoryCulture => 'Culture';

  @override
  String get defaultCategoryEducation => 'Education';

  @override
  String get defaultCategoryOtherExpense => 'Other Expense';

  @override
  String get defaultCategorySalary => 'Salary';

  @override
  String get defaultCategorySideJob => 'Side Job';

  @override
  String get defaultCategoryAllowance => 'Allowance';

  @override
  String get defaultCategoryInterest => 'Interest';

  @override
  String get defaultCategoryOtherIncome => 'Other Income';

  @override
  String get defaultCategoryFixedDeposit => 'Fixed Deposit';

  @override
  String get defaultCategorySavings => 'Savings';

  @override
  String get defaultCategoryStock => 'Stock';

  @override
  String get defaultCategoryFund => 'Fund';

  @override
  String get defaultCategoryRealEstate => 'Real Estate';

  @override
  String get defaultCategoryCrypto => 'Crypto';

  @override
  String get defaultCategoryOtherAsset => 'Other Asset';

  @override
  String get autoSaveSettingsTitle => 'Auto Save Settings';

  @override
  String get autoSaveSettingsAutoProcessMode => 'Auto Process Mode';

  @override
  String get autoSaveSettingsSuggestModeTitle => 'Suggest Mode';

  @override
  String get autoSaveSettingsSuggestModeDesc =>
      'Review and save detected transactions';

  @override
  String get autoSaveSettingsAutoModeTitle => 'Auto Mode';

  @override
  String get autoSaveSettingsAutoModeDesc =>
      'Automatically save detected transactions';

  @override
  String get autoSaveSettingsRequiredPermissions => 'Required Permissions';

  @override
  String get autoSaveSettingsPermissionDesc =>
      'SMS read or notification access permission is required.\nPermission request will appear when saving settings.';

  @override
  String get autoSaveSettingsPermissionButton => 'Permission Settings';

  @override
  String get autoSaveSettingsIosNotSupported =>
      'Auto save is not available on iOS.\nSMS/notification-based auto save only works on Android.';

  @override
  String get autoSaveSettingsSaved => 'Auto process settings saved';

  @override
  String autoSaveSettingsSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get autoSaveSettingsPermissionRequired =>
      'Required permissions not granted. Please allow permissions.';

  @override
  String get permissionSettingsSnackbar =>
      'Please allow permissions in Settings and return to the app';

  @override
  String get permissionCheckingStatus => 'Checking permission status...';

  @override
  String get autoSaveSettingsModeManual => 'Manual Entry';

  @override
  String get autoSaveSettingsModeSuggest => 'Suggest Mode';

  @override
  String get autoSaveSettingsModeAuto => 'Auto Save';

  @override
  String get autoSaveSettingsSourceType => 'Source Type';

  @override
  String get autoSaveSettingsSourceSms => 'SMS';

  @override
  String get autoSaveSettingsSourcePush => 'Push';

  @override
  String get autoSaveSettingsSourceSmsDesc =>
      'Detects payment text messages. Supported by most card companies.';

  @override
  String get autoSaveSettingsSourcePushDesc =>
      'Detects push notifications from card apps. Supports KB, Shinhan, Samsung Card, etc.';

  @override
  String get paymentMethodPermissionWarningTitle => 'Confirm Sharing';

  @override
  String get paymentMethodPermissionWarningMessage =>
      'Changing from personal to shared payment method will allow other members to modify it. Continue?';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get pullToRefresh => 'Pull down to refresh';

  @override
  String get duplicateTransaction => 'Duplicate Transaction';

  @override
  String get duplicateTransactionWarning =>
      'This transaction was detected as a duplicate';

  @override
  String get originalTransactionTime => 'Original Transaction Time';

  @override
  String get viewOriginal => 'View Original';

  @override
  String get confirmDuplicate => 'Details';

  @override
  String get ignoreDuplicate => 'Save';

  @override
  String get duplicateInfo => 'Duplicate Info';

  @override
  String get originalTransactionNotFound => 'Original transaction not found.';

  @override
  String get duplicateMessageReceivedTwice =>
      'The same SMS/notification may have been received twice.';
}
