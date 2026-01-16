// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '공유 가계부';

  @override
  String get appSubtitle => '가족, 커플, 룸메이트와 함께\n가계부를 관리하세요';

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonEdit => '수정';

  @override
  String get commonAdd => '추가';

  @override
  String get commonClose => '닫기';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonYes => '예';

  @override
  String get commonNo => '아니오';

  @override
  String get commonOk => '확인';

  @override
  String get commonBack => '뒤로';

  @override
  String get commonNext => '다음';

  @override
  String get commonDone => '완료';

  @override
  String get commonSearch => '검색';

  @override
  String get commonLoading => '로딩 중...';

  @override
  String get commonError => '오류';

  @override
  String get commonSuccess => '성공';

  @override
  String get tooltipSearch => '검색';

  @override
  String get tooltipSettings => '설정';

  @override
  String get tooltipBook => '가계부 관리';

  @override
  String get tooltipPreviousMonth => '이전 달';

  @override
  String get tooltipNextMonth => '다음 달';

  @override
  String get tooltipPreviousYear => '이전 년도';

  @override
  String get tooltipNextYear => '다음 년도';

  @override
  String get tooltipTogglePassword => '비밀번호 보기/숨기기';

  @override
  String get tooltipDelete => '삭제';

  @override
  String get tooltipEdit => '수정';

  @override
  String get tooltipClear => '지우기';

  @override
  String get tooltipEditProfile => '프로필 수정';

  @override
  String get tooltipClose => '닫기';

  @override
  String get tooltipRefresh => '새로고침';

  @override
  String get tooltipFilter => '필터';

  @override
  String get tooltipSort => '정렬';

  @override
  String get tooltipInfo => '정보';

  @override
  String get navTabCalendar => '캘린더';

  @override
  String get navTabStatistics => '통계';

  @override
  String get navTabAsset => '자산';

  @override
  String get navTabMore => '더보기';

  @override
  String get authLogin => '로그인';

  @override
  String get authSignup => '회원가입';

  @override
  String get authLogout => '로그아웃';

  @override
  String get authEmail => '이메일';

  @override
  String get authPassword => '비밀번호';

  @override
  String get authPasswordConfirm => '비밀번호 확인';

  @override
  String get authName => '이름';

  @override
  String get authForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get authOr => '또는';

  @override
  String get authNoAccount => '계정이 없으신가요?';

  @override
  String get authHaveAccount => '이미 계정이 있으신가요?';

  @override
  String get authLoginError => '로그인 처리 중 오류가 발생했습니다. 다시 시도해주세요.';

  @override
  String get authInvalidCredentials => '이메일 또는 비밀번호가 틀렸습니다.';

  @override
  String get authEmailNotVerified => '이메일 인증이 완료되지 않았습니다. 메일함을 확인해주세요.';

  @override
  String get authSignupTitle => '새 계정 만들기';

  @override
  String get authSignupSubtitle => '공유 가계부를 시작하려면\n계정을 만들어주세요';

  @override
  String get authTermsAgreement => '회원가입 시 이용약관 및 개인정보처리방침에\n동의하는 것으로 간주됩니다.';

  @override
  String get validationEmailRequired => '이메일을 입력해주세요';

  @override
  String get validationEmailInvalid => '올바른 이메일 형식이 아닙니다';

  @override
  String get validationPasswordRequired => '비밀번호를 입력해주세요';

  @override
  String get validationPasswordTooShort => '비밀번호는 6자 이상이어야 합니다';

  @override
  String get validationPasswordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get validationNameRequired => '이름을 입력해주세요';

  @override
  String get validationNameTooShort => '이름은 2자 이상이어야 합니다';

  @override
  String get validationPasswordConfirmRequired => '비밀번호를 다시 입력해주세요';

  @override
  String get emailVerificationTitle => '이메일 인증';

  @override
  String get emailVerificationWaiting => '이메일 인증 대기 중';

  @override
  String get emailVerificationComplete => '이메일 인증 완료!';

  @override
  String get emailVerificationSent =>
      '위 이메일로 인증 메일을 보냈습니다.\n메일함을 확인하고 인증 링크를 클릭해주세요.';

  @override
  String get emailVerificationDone => '인증이 완료되었습니다.\n잠시 후 홈 화면으로 이동합니다.';

  @override
  String get emailVerificationResent => '인증 메일을 다시 보냈습니다. 메일함을 확인해주세요.';

  @override
  String emailVerificationResendFailed(String error) {
    return '인증 메일 전송에 실패했습니다: $error';
  }

  @override
  String get emailVerificationCheckStatus => '인증 상태 확인';

  @override
  String get emailVerificationResendButton => '인증 메일 다시 보내기';

  @override
  String emailVerificationResendCooldown(int seconds) {
    return '재전송 ($seconds초 후 가능)';
  }

  @override
  String get emailVerificationVerified => '인증 완료';

  @override
  String get emailVerificationNotVerified => '미인증';

  @override
  String get emailVerificationChecking => '확인 중...';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsAppSettings => '앱 설정';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsNotification => '알림';

  @override
  String get settingsNotificationDescription => '공유 변경, 초대 등 알림 받기';

  @override
  String get settingsNotificationSettings => '알림 설정';

  @override
  String get settingsNotificationSettingsDescription => '알림 유형별 설정';

  @override
  String get settingsAccount => '계정';

  @override
  String get settingsProfile => '프로필';

  @override
  String get settingsMyColor => '내 색상';

  @override
  String get settingsColorChanged => '색상이 변경되었습니다';

  @override
  String settingsColorChangeFailed(String error) {
    return '색상 변경 실패: $error';
  }

  @override
  String get settingsPasswordChange => '비밀번호 변경';

  @override
  String get settingsData => '데이터';

  @override
  String get settingsDataExport => '데이터 내보내기';

  @override
  String get settingsDataExportDescription => '거래 내역을 CSV로 내보내기';

  @override
  String get settingsInfo => '정보';

  @override
  String get settingsAppInfo => '앱 정보';

  @override
  String settingsVersion(String version) {
    return '버전 $version';
  }

  @override
  String get settingsTerms => '이용약관';

  @override
  String get settingsPrivacy => '개인정보처리방침';

  @override
  String get settingsDeleteAccount => '회원 탈퇴';

  @override
  String get settingsThemeLight => '라이트 모드';

  @override
  String get settingsThemeDark => '다크 모드';

  @override
  String get settingsThemeSystem => '시스템 설정';

  @override
  String settingsThemeSaveFailed(String error) {
    return '테마 저장 실패: $error';
  }

  @override
  String get settingsLogoutConfirm => '정말 로그아웃하시겠습니까?';

  @override
  String get settingsDeleteAccountConfirm =>
      '정말 탈퇴하시겠습니까?\n\n모든 데이터가 삭제되며 복구할 수 없습니다.';

  @override
  String settingsDeleteAccountFailed(String error) {
    return '회원 탈퇴 실패: $error';
  }

  @override
  String get settingsDisplayNameChanged => '표시 이름이 변경되었습니다';

  @override
  String settingsDisplayNameChangeFailed(String error) {
    return '표시 이름 변경 실패: $error';
  }

  @override
  String get settingsDisplayName => '표시 이름';

  @override
  String get settingsPasswordChanged => '비밀번호가 변경되었습니다';

  @override
  String get settingsCurrentPassword => '현재 비밀번호';

  @override
  String get settingsCurrentPasswordHint => '현재 비밀번호를 입력하세요';

  @override
  String get settingsNewPassword => '새 비밀번호';

  @override
  String get settingsNewPasswordHint => '새 비밀번호를 입력하세요';

  @override
  String get settingsNewPasswordConfirm => '새 비밀번호 확인';

  @override
  String get settingsNewPasswordConfirmHint => '새 비밀번호를 다시 입력하세요';

  @override
  String get settingsNewPasswordMismatch => '새 비밀번호가 일치하지 않습니다';

  @override
  String get settingsChange => '변경';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageChanged => '언어가 변경되었습니다';

  @override
  String get settingsFeaturePreparing => '준비 중인 기능입니다';

  @override
  String get settingsAboutAppName => '공유 가계부';

  @override
  String get settingsAboutAppDescription =>
      'Flutter + Supabase로 만든 공유 가계부 앱입니다.';

  @override
  String get settingsAboutAppSubDescription => '가족, 연인, 룸메이트와 함께 지출을 관리하세요.';

  @override
  String get ledgerTitle => '가계부';

  @override
  String get ledgerManagement => '가계부 관리';

  @override
  String get ledgerShareManagement => '가계부 및 공유 관리';

  @override
  String get ledgerCreate => '가계부 생성하기';

  @override
  String get ledgerNew => '새 가계부';

  @override
  String get ledgerName => '가계부 이름';

  @override
  String get ledgerNameHint => '가계부 이름을 입력하세요';

  @override
  String get ledgerDescription => '설명 (선택)';

  @override
  String get ledgerCurrency => '통화';

  @override
  String get ledgerShared => '공유 가계부';

  @override
  String get ledgerPersonal => '개인 가계부';

  @override
  String get ledgerInUse => '사용중';

  @override
  String get ledgerEmpty => '가계부가 없습니다';

  @override
  String get ledgerEmptySubtitle => '가계부를 생성하여 시작하세요';

  @override
  String get ledgerCreated => '가계부가 생성되었습니다';

  @override
  String get ledgerUpdated => '가계부가 수정되었습니다';

  @override
  String get ledgerDeleted => '가계부가 삭제되었습니다';

  @override
  String ledgerDeleteFailed(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get ledgerDeleteConfirmTitle => '가계부 삭제';

  @override
  String get ledgerDeleteConfirmMessage =>
      '현재 사용 중인 가계부입니다.\n삭제 후 다른 가계부로 자동 전환됩니다.\n\n이 가계부에 기록된 모든 거래, 카테고리, 예산이 함께 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.';

  @override
  String get ledgerDeleteNotAllowed => '삭제 불가';

  @override
  String get ledgerDeleteNotAllowedMessage =>
      '최소 1개의 가계부가 필요합니다.\n다른 가계부를 먼저 생성해주세요.';

  @override
  String get ledgerChangeConfirmTitle => '가계부 변경';

  @override
  String ledgerChangeConfirmMessage(String name) {
    return '\'$name\' 가계부를 사용하시겠습니까?';
  }

  @override
  String get ledgerUse => '사용';

  @override
  String get ledgerMyLedgers => '내 가계부';

  @override
  String get ledgerInvitedLedgers => '초대받은 가계부';

  @override
  String get shareInvite => '초대';

  @override
  String get shareMemberInvite => '멤버 초대';

  @override
  String get shareRole => '역할';

  @override
  String get shareRoleMember => '멤버';

  @override
  String get shareRoleMemberDescription => '거래 내역 조회/추가/수정/삭제';

  @override
  String get shareRoleAdmin => '관리자';

  @override
  String get shareRoleAdminDescription => '거래 + 카테고리/예산 관리 + 멤버 초대';

  @override
  String get shareInviteSent => '초대를 보냈습니다';

  @override
  String get shareInviteAccepted => '초대를 수락했습니다';

  @override
  String get shareInviteRejected => '초대를 거부했습니다';

  @override
  String get shareInviteCancelled => '초대를 취소했습니다';

  @override
  String get shareInviteCancelConfirmTitle => '초대 취소';

  @override
  String shareInviteCancelConfirmMessage(String email) {
    return '\'$email\'님에게 보낸 초대를 취소하시겠습니까?';
  }

  @override
  String get shareInviteRejectConfirmTitle => '초대 거부';

  @override
  String shareInviteRejectConfirmMessage(String name) {
    return '\'$name\' 초대를 거부하시겠습니까?\n거부하면 목록에서 사라집니다.';
  }

  @override
  String get shareLeaveConfirmTitle => '가계부 탈퇴';

  @override
  String shareLeaveConfirmMessage(String name) {
    return '\'$name\'에서 탈퇴하시겠습니까?\n탈퇴하면 해당 가계부의 데이터에 더 이상 접근할 수 없습니다.';
  }

  @override
  String get shareLeave => '탈퇴';

  @override
  String get shareReject => '거부';

  @override
  String get categoryTitle => '카테고리';

  @override
  String get categoryManagement => '카테고리 관리';

  @override
  String get categoryAdd => '카테고리 추가';

  @override
  String get categoryEdit => '카테고리 수정';

  @override
  String get categoryName => '카테고리 이름';

  @override
  String get categoryNameHint => '카테고리 이름을 입력하세요';

  @override
  String get categoryNameRequired => '카테고리 이름을 입력해주세요';

  @override
  String get categoryDeleted => '카테고리가 삭제되었습니다';

  @override
  String categoryDeleteFailed(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get categoryDeleteConfirmTitle => '카테고리 삭제';

  @override
  String get categoryDeleteConfirmMessage => '이 카테고리로 기록된 거래는 삭제되지 않습니다.';

  @override
  String get categoryAdded => '카테고리가 추가되었습니다';

  @override
  String categoryEmpty(String type) {
    return '등록된 $type 카테고리가 없습니다';
  }

  @override
  String get transactionExpense => '지출';

  @override
  String get transactionIncome => '수입';

  @override
  String get transactionAsset => '자산';

  @override
  String get transactionTitle => '제목';

  @override
  String get transactionAmount => '금액';

  @override
  String get transactionAmountUnit => '원';

  @override
  String get transactionCategory => '카테고리';

  @override
  String get transactionPaymentMethod => '결제수단';

  @override
  String get transactionPaymentMethodOptional => '결제수단 (선택)';

  @override
  String get transactionMemo => '메모';

  @override
  String get transactionMemoOptional => '메모 (선택)';

  @override
  String get transactionMemoHint => '추가 메모를 입력하세요';

  @override
  String get transactionAdded => '거래가 추가되었습니다';

  @override
  String get transactionUpdated => '거래가 수정되었습니다';

  @override
  String get transactionNone => '선택 안함';

  @override
  String get transactionQuickExpense => '빠른 지출 추가';

  @override
  String get transactionExpenseAdded => '지출이 추가되었습니다';

  @override
  String get transactionAmountRequired => '금액을 입력해주세요';

  @override
  String get transactionTitleRequired => '제목을 입력해주세요';

  @override
  String get transactionCategoryLoadError => '카테고리를 불러올 수 없습니다';

  @override
  String get transactionNoTitle => '제목 없음';

  @override
  String get transactionDeleted => '거래가 삭제되었습니다';

  @override
  String transactionDeleteFailed(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get transactionDeleteConfirmTitle => '거래 삭제';

  @override
  String get transactionDeleteConfirmMessage => '이 거래를 삭제하시겠습니까?';

  @override
  String get labelTitle => '제목';

  @override
  String get labelMemo => '메모';

  @override
  String get labelAmount => '금액';

  @override
  String get labelDate => '날짜';

  @override
  String get labelCategory => '카테고리';

  @override
  String get labelPaymentMethod => '결제수단';

  @override
  String get labelAuthor => '작성자';

  @override
  String get maturityDateSelect => '만기일 선택';

  @override
  String get installmentInfoRequired => '할부 정보를 입력해주세요';

  @override
  String get installmentLabel => '할부';

  @override
  String installmentRegistered(int months) {
    return '$months개월 할부가 등록되었습니다';
  }

  @override
  String recurringRegistered(String endText) {
    return '반복 거래가 등록되었습니다 ($endText)';
  }

  @override
  String recurringUntil(int year, int month) {
    return '$year년 $month월까지';
  }

  @override
  String get recurringContinue => '계속';

  @override
  String get summaryBalance => '합계';

  @override
  String get maturityDateSelectOptional => '만기일 선택 (선택사항)';

  @override
  String get recurringPeriod => '반복 주기';

  @override
  String get recurringNone => '없음';

  @override
  String get recurringDaily => '일';

  @override
  String get recurringMonthly => '월';

  @override
  String get recurringYearly => '년';

  @override
  String get recurringEndDate => '종료일';

  @override
  String get recurringEndMonth => '종료월';

  @override
  String get recurringEndYear => '종료년';

  @override
  String get recurringContinueRepeat => '계속 반복';

  @override
  String get recurringClearEndDate => '종료일 해제';

  @override
  String recurringTransactionCount(int count) {
    return '총 $count건의 거래가 생성됩니다';
  }

  @override
  String get recurringDailyAutoCreate => '계속 반복 (매일 자동 생성)';

  @override
  String get fixedExpenseRegister => '고정비로 등록';

  @override
  String get fixedExpenseDescription => '월세, 보험료 등 정기적으로 지출되는 금액';

  @override
  String get yearLabel => '년도';

  @override
  String get monthLabel => '월';

  @override
  String yearFormat(int year) {
    return '$year년';
  }

  @override
  String monthFormat(int month) {
    return '$month월';
  }

  @override
  String get installmentInput => '할부로 입력';

  @override
  String get installmentInputDescription => '총금액을 여러 달에 나눠서 기록합니다';

  @override
  String get installmentApplied => '할부 적용됨';

  @override
  String get installmentTotalAmount => '총 금액';

  @override
  String get installmentMonthlyPayment => '월 납입금';

  @override
  String get installmentFirstMonth => '첫 달';

  @override
  String get installmentPeriod => '할부 기간';

  @override
  String installmentMonths(int months) {
    return '$months개월';
  }

  @override
  String get installmentEndMonth => '종료월';

  @override
  String get installmentModify => '수정하기';

  @override
  String get installmentTotalAmountHint => '할부 총 금액을 입력하세요';

  @override
  String get installmentMonthsLabel => '개월 수';

  @override
  String get installmentMonthsHint => '1-60개월';

  @override
  String get installmentPreview => '할부 계산 미리보기';

  @override
  String get installmentApply => '할부 적용';

  @override
  String get installmentAmountError => '금액이 개월 수보다 커야 합니다';

  @override
  String categoryAddType(String type) {
    return '$type 카테고리 추가';
  }

  @override
  String get categoryNameHintExample => '예: 식비, 교통비';

  @override
  String categoryDeleteConfirm(String name) {
    return '\'$name\' 카테고리를 삭제하시겠습니까?';
  }

  @override
  String get paymentMethodNameHintExample => '예: 신용카드, 현금';

  @override
  String paymentMethodDeleteConfirm(String name) {
    return '\'$name\' 결제수단을 삭제하시겠습니까?';
  }

  @override
  String get paymentMethodTitle => '결제수단';

  @override
  String get paymentMethodManagement => '결제수단 관리';

  @override
  String get paymentMethodAdd => '결제수단 추가';

  @override
  String get paymentMethodEdit => '결제수단 수정';

  @override
  String get paymentMethodName => '결제수단 이름';

  @override
  String get paymentMethodNameHint => '결제수단 이름을 입력하세요';

  @override
  String get paymentMethodNameRequired => '결제수단 이름을 입력해주세요';

  @override
  String get paymentMethodDeleted => '결제수단이 삭제되었습니다';

  @override
  String paymentMethodDeleteFailed(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get paymentMethodDeleteConfirmTitle => '결제수단 삭제';

  @override
  String get paymentMethodDeleteConfirmMessage =>
      '이 결제수단으로 기록된 거래의 결제수단 정보가 삭제됩니다.';

  @override
  String get paymentMethodAdded => '결제수단이 추가되었습니다';

  @override
  String get paymentMethodUpdated => '결제수단이 수정되었습니다';

  @override
  String get paymentMethodEmpty => '등록된 결제수단이 없습니다';

  @override
  String get paymentMethodDefault => '기본 결제수단';

  @override
  String get errorGeneric => '오류가 발생했습니다';

  @override
  String get errorNetwork => '네트워크 연결을 확인해주세요.';

  @override
  String get errorSessionExpired => '로그인이 만료되었습니다. 다시 로그인해주세요.';

  @override
  String get errorNotFound => '페이지를 찾을 수 없습니다';

  @override
  String errorWithMessage(String message) {
    return '오류: $message';
  }

  @override
  String get user => '사용자';

  @override
  String get homeTitle => '홈';

  @override
  String get moreMenuShareManagement => '가계부 및 공유 관리';

  @override
  String get moreMenuCategoryManagement => '카테고리 관리';

  @override
  String get moreMenuPaymentMethodManagement => '결제수단 관리';

  @override
  String get moreMenuFixedExpenseManagement => '고정비 관리';

  @override
  String get noHistory => '내역 없음';

  @override
  String get statisticsCategory => '카테고리';

  @override
  String get statisticsTrend => '추이';

  @override
  String get statisticsPaymentMethod => '결제수단';

  @override
  String get statisticsCategoryDistribution => '카테고리별 분포';

  @override
  String get statisticsCategoryRanking => '카테고리별 순위';

  @override
  String get statisticsNoData => '데이터가 없습니다';

  @override
  String get statisticsOther => '기타';

  @override
  String get statisticsTotalIncome => '총 수입';

  @override
  String get statisticsTotalExpense => '총 지출';

  @override
  String get statisticsTotalAsset => '총 자산';

  @override
  String statisticsTotal(String type) {
    return '총 $type';
  }

  @override
  String get statisticsNoPreviousData => '지난달 데이터 없음';

  @override
  String get statisticsIncrease => '증가';

  @override
  String get statisticsDecrease => '감소';

  @override
  String get statisticsSame => '동일';

  @override
  String statisticsVsLastMonth(String percent, String change) {
    return '(지난달 대비 $percent% $change)';
  }

  @override
  String get statisticsFixed => '고정비';

  @override
  String get statisticsVariable => '변동비';

  @override
  String get statisticsAverage => '평균';

  @override
  String get statisticsDetail => '상세 내역';

  @override
  String statisticsYearMonth(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String statisticsYear(int year) {
    return '$year년';
  }

  @override
  String get statisticsPaymentDistribution => '결제수단별 분포';

  @override
  String get statisticsPaymentRanking => '결제수단별 순위';

  @override
  String get statisticsPaymentNotice => '결제수단 통계는 지출 내역만 표시됩니다.';

  @override
  String get assetTitle => '자산';

  @override
  String get assetTotal => '총 자산';

  @override
  String get assetChange => '자산 변화';

  @override
  String get assetCategoryDistribution => '카테고리별 분포';

  @override
  String get assetList => '자산 목록';

  @override
  String assetThisMonth(String change) {
    return '이번 달 $change원';
  }

  @override
  String get assetGoalTitle => '목표';

  @override
  String get assetGoalSet => '목표 설정';

  @override
  String get assetGoalDelete => '목표 삭제';

  @override
  String assetGoalDeleteConfirm(String title) {
    return '\'$title\' 목표를 삭제하시겠습니까?';
  }

  @override
  String get assetGoalDeleted => '목표가 삭제되었습니다';

  @override
  String assetGoalDeleteFailed(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get assetGoalEmpty => '목표를 설정하고\n자산을 계획적으로 관리하세요';

  @override
  String get assetGoalCurrent => '현재';

  @override
  String get assetGoalTarget => '목표';

  @override
  String assetGoalRemaining(String amount) {
    return '$amount원 남음';
  }

  @override
  String get assetGoalAchieved => '목표 달성 완료!';

  @override
  String get assetGoalTapForDetails => '탭하여 상세 금액 보기';

  @override
  String get assetGoalLoadError => '목표 정보를 불러올 수 없습니다';

  @override
  String get fixedExpenseTitle => '고정비';

  @override
  String get fixedExpenseManagement => '고정비 관리';

  @override
  String get fixedExpenseCategoryTitle => '고정비 카테고리';

  @override
  String get fixedExpenseIncludeInExpense => '고정비를 지출에 편입';

  @override
  String get fixedExpenseIncludeInExpenseOn => '고정비가 달력과 통계의 지출에 포함됩니다';

  @override
  String get fixedExpenseIncludeInExpenseOff => '고정비가 달력과 통계의 지출에서 제외됩니다';

  @override
  String get fixedExpenseIncludedSnackbar => '고정비가 지출에 포함됩니다';

  @override
  String get fixedExpenseExcludedSnackbar => '고정비가 지출에서 제외됩니다';

  @override
  String fixedExpenseSettingsFailed(String error) {
    return '설정 변경 실패: $error';
  }

  @override
  String get fixedExpenseSettingsLoadFailed => '설정 로드 실패';

  @override
  String get fixedExpenseCategoryEmpty => '등록된 고정비 카테고리가 없습니다';

  @override
  String get fixedExpenseCategoryEmptySubtitle => '+ 버튼을 눌러 카테고리를 추가하세요';

  @override
  String get fixedExpenseCategoryDelete => '고정비 카테고리 삭제';

  @override
  String fixedExpenseCategoryDeleteConfirm(String name) {
    return '\'$name\' 카테고리를 삭제하시겠습니까?';
  }

  @override
  String get fixedExpenseCategoryAdd => '고정비 카테고리 추가';

  @override
  String get fixedExpenseCategoryEdit => '고정비 카테고리 수정';

  @override
  String get fixedExpenseCategoryNameHint => '예: 월세, 통신비';

  @override
  String get categoryUpdated => '카테고리가 수정되었습니다';

  @override
  String get notificationSettingsTitle => '알림 설정';

  @override
  String get notificationSettingsDescription => '받고 싶은 알림을 선택하세요';

  @override
  String notificationSettingsSaveFailed(String error) {
    return '설정 저장 실패: $error';
  }

  @override
  String get notificationSettingsLoadFailed => '알림 설정을 불러올 수 없습니다';

  @override
  String get notificationSectionSharedLedger => '공유 가계부';

  @override
  String get notificationSharedLedgerChange => '공유 가계부 변경';

  @override
  String get notificationSharedLedgerChangeDesc => '다른 멤버가 거래를 추가/수정/삭제했을 때 알림';

  @override
  String get notificationSectionInvite => '초대';

  @override
  String get notificationInviteReceived => '가계부 초대 받음';

  @override
  String get notificationInviteReceivedDesc => '다른 사용자가 가계부에 초대했을 때 알림';

  @override
  String get notificationInviteAccepted => '초대 수락됨';

  @override
  String get notificationInviteAcceptedDesc => '내가 보낸 초대를 다른 사용자가 수락했을 때 알림';

  @override
  String get searchTitle => '검색';

  @override
  String get searchHint => '제목/메모로 검색...';

  @override
  String get searchEmpty => '제목/메모로 거래 내역을 검색하세요';

  @override
  String get searchNoResults => '검색 결과가 없습니다';

  @override
  String get searchUncategorized => '미분류';

  @override
  String get shareManagementTitle => '가계부 및 공유 관리';

  @override
  String get shareMyLedgers => '내 가계부';

  @override
  String get shareInvitedLedgers => '초대받은 가계부';

  @override
  String get shareLedgerEmpty => '가계부가 없습니다';

  @override
  String get shareLedgerEmptySubtitle => '가계부를 생성하여 시작하세요';

  @override
  String get shareCreateLedger => '가계부 생성하기';

  @override
  String get shareErrorOccurred => '오류가 발생했습니다';

  @override
  String shareLedgerChanged(String name) {
    return '\'$name\' 가계부로 변경했습니다';
  }

  @override
  String get shareLedgerLeft => '가계부에서 탈퇴했습니다';

  @override
  String get shareInviteCancelText => '초대취소';

  @override
  String get shareInviteSentMessage => '초대를 보냈습니다';

  @override
  String get shareInviteCancelledMessage => '초대를 취소했습니다';

  @override
  String get shareInviteAcceptedMessage => '초대를 수락했습니다';

  @override
  String get shareInviteRejectedMessage => '초대를 거부했습니다';

  @override
  String get shareEmailHint => 'example@email.com';

  @override
  String get shareInUse => '사용 중';

  @override
  String get shareUse => '사용';

  @override
  String get shareUnknown => '알 수 없음';

  @override
  String get shareMemberParticipating => '멤버로 참여 중';

  @override
  String get shareAccept => '수락';

  @override
  String get shareMe => '나';

  @override
  String shareMemberCount(int current, int max) {
    return '멤버 $current/$max명';
  }

  @override
  String get shareMemberFull => '멤버 가득 참';

  @override
  String get sharePendingAccept => '수락 대기중';

  @override
  String get shareAccepted => '수락됨';

  @override
  String get shareRejected => '수락 거부됨';

  @override
  String shareInviterLedger(String email) {
    return '$email님의 가계부';
  }

  @override
  String shareSharingWith(String name) {
    return '$name님과 공유 중';
  }

  @override
  String shareSharingWithMultiple(String name1, String name2) {
    return '$name1, $name2님과 공유 중';
  }

  @override
  String shareSharingWithMore(String name1, String name2, int count) {
    return '$name1, $name2 외 $count명과 공유 중';
  }

  @override
  String get ledgerNewTitle => '새 가계부';

  @override
  String get ledgerEditTitle => '가계부 수정';

  @override
  String get ledgerNoLedgers => '등록된 가계부가 없습니다';

  @override
  String get ledgerCreateButton => '가계부 만들기';

  @override
  String get ledgerNameLabel => '가계부 이름';

  @override
  String get ledgerNameRequired => '가계부 이름을 입력하세요';

  @override
  String get ledgerDescriptionLabel => '설명 (선택)';

  @override
  String get ledgerCurrencyLabel => '통화';

  @override
  String get ledgerDeleteNotAllowedTitle => '삭제 불가';

  @override
  String get ledgerDeleteNotAllowedContent =>
      '최소 1개의 가계부가 필요합니다.\n다른 가계부를 먼저 생성해주세요.';

  @override
  String get ledgerMemberLoading => '멤버 정보 로딩 중...';

  @override
  String ledgerDeleteConfirmWithName(String name) {
    return '\'$name\' 가계부를 삭제하시겠습니까?\n\n이 가계부에 기록된 모든 거래, 카테고리, 예산이 함께 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get ledgerDeleteCurrentInUseWarning =>
      '현재 사용 중인 가계부입니다.\n삭제 후 다른 가계부로 자동 전환됩니다.\n\n';

  @override
  String ledgerSharedWithOne(String name) {
    return '$name님과 공유 중';
  }

  @override
  String ledgerSharedWithTwo(String name1, String name2) {
    return '$name1, $name2님과 공유 중';
  }

  @override
  String ledgerSharedWithMany(String name1, String name2, int count) {
    return '$name1, $name2 외 $count명과 공유 중';
  }

  @override
  String get ledgerUser => '사용자';

  @override
  String get calendarDaySun => '일';

  @override
  String get calendarDayMon => '월';

  @override
  String get calendarDayTue => '화';

  @override
  String get calendarDayWed => '수';

  @override
  String get calendarDayThu => '목';

  @override
  String get calendarDayFri => '금';

  @override
  String get calendarDaySat => '토';

  @override
  String get calendarToday => '오늘';

  @override
  String calendarYearMonth(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String get calendarCategoryBreakdown => '카테고리별 상세내역';

  @override
  String get calendarNoRecords => '기록된 내역이 없습니다';

  @override
  String calendarTransactionCount(int count) {
    return '$count건';
  }

  @override
  String get calendarNewTransaction => '새 거래';

  @override
  String get calendarTransactionDelete => '거래 삭제';

  @override
  String get calendarTransactionDeleteConfirm => '이 거래를 삭제하시겠습니까?';

  @override
  String get assetNoData => '데이터가 없습니다';

  @override
  String get assetOther => '기타';

  @override
  String get assetNoAsset => '자산이 없습니다';

  @override
  String get assetNoAssetData => '자산 데이터가 없습니다';

  @override
  String get assetGoalNew => '새 목표 설정';

  @override
  String get assetGoalEdit => '목표 수정';

  @override
  String get assetGoalAmount => '목표 금액';

  @override
  String get assetGoalAmountRequired => '목표 금액을 입력하세요';

  @override
  String get assetGoalAmountInvalid => '올바른 금액을 입력하세요';

  @override
  String get assetGoalDateOptional => '목표 날짜 (선택)';

  @override
  String get assetGoalDateHint => '목표 달성 날짜를 선택하세요';

  @override
  String get assetGoalCreate => '목표 생성';

  @override
  String get assetGoalCreated => '목표가 생성되었습니다';

  @override
  String get assetGoalUpdated => '목표가 수정되었습니다';

  @override
  String get assetLedgerRequired => '가계부를 선택하세요';

  @override
  String get assetGoalAchievementRate => '달성률';

  @override
  String get assetGoalCurrentAmount => '현재';

  @override
  String get assetGoalTargetAmount => '목표';

  @override
  String assetGoalDaysPassed(int days) {
    return '$days일 경과';
  }

  @override
  String assetGoalDaysRemaining(int days) {
    return 'D-$days';
  }

  @override
  String get assetGoalCompleted => '달성 완료';

  @override
  String get assetGoalNone => '설정된 목표가 없습니다';

  @override
  String get assetGoalDeleteTitle => '목표 삭제';

  @override
  String assetGoalDeleteMessage(String title) {
    return '$title 목표를 삭제하시겠습니까?';
  }

  @override
  String assetMonth(int month) {
    return '$month월';
  }

  @override
  String get fixedExpenseCategoryName => '카테고리 이름';

  @override
  String get fixedExpenseCategoryNameRequired => '카테고리 이름을 입력해주세요';

  @override
  String get fixedExpenseCategoryAdded => '고정비 카테고리가 추가되었습니다';

  @override
  String get fixedExpenseCategoryDeleted => '고정비 카테고리가 삭제되었습니다';

  @override
  String get fixedExpenseCategoryNone => '선택 안함';

  @override
  String get paymentMethodOptional => '결제수단 (선택)';

  @override
  String get statisticsPeriodMonthly => '월별';

  @override
  String get statisticsPeriodYearly => '연별';

  @override
  String get statisticsTypeIncome => '수입';

  @override
  String get statisticsTypeExpense => '지출';

  @override
  String get statisticsTypeAsset => '자산';

  @override
  String get statisticsExpenseAll => '전체';

  @override
  String get statisticsExpenseFixed => '고정비';

  @override
  String get statisticsExpenseVariable => '변동비';

  @override
  String get statisticsExpenseAllDesc => '모든 지출';

  @override
  String get statisticsExpenseFixedDesc => '월세, 보험료 등 정기 지출';

  @override
  String get statisticsExpenseVariableDesc => '고정비 제외 지출';

  @override
  String get statisticsDateSelect => '날짜 선택';

  @override
  String get statisticsToday => '오늘';

  @override
  String statisticsYearLabel(int year) {
    return '$year년';
  }

  @override
  String statisticsMonthLabel(int month) {
    return '$month월';
  }

  @override
  String statisticsYearMonthFormat(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String get categoryUncategorized => '미지정';

  @override
  String get categoryFixedExpense => '고정비';

  @override
  String get categoryUnknown => '미분류';

  @override
  String get defaultCategoryFood => '식비';

  @override
  String get defaultCategoryTransport => '교통';

  @override
  String get defaultCategoryShopping => '쇼핑';

  @override
  String get defaultCategoryLiving => '생활';

  @override
  String get defaultCategoryTelecom => '통신';

  @override
  String get defaultCategoryMedical => '의료';

  @override
  String get defaultCategoryCulture => '문화';

  @override
  String get defaultCategoryEducation => '교육';

  @override
  String get defaultCategoryOtherExpense => '기타 지출';

  @override
  String get defaultCategorySalary => '급여';

  @override
  String get defaultCategorySideJob => '부업';

  @override
  String get defaultCategoryAllowance => '용돈';

  @override
  String get defaultCategoryInterest => '이자';

  @override
  String get defaultCategoryOtherIncome => '기타 수입';

  @override
  String get defaultCategoryFixedDeposit => '정기예금';

  @override
  String get defaultCategorySavings => '적금';

  @override
  String get defaultCategoryStock => '주식';

  @override
  String get defaultCategoryFund => '펀드';

  @override
  String get defaultCategoryRealEstate => '부동산';

  @override
  String get defaultCategoryCrypto => '암호화폐';

  @override
  String get defaultCategoryOtherAsset => '기타 자산';
}
