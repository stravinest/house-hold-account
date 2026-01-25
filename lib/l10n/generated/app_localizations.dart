import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// 앱 제목
  ///
  /// In ko, this message translates to:
  /// **'공유 가계부'**
  String get appTitle;

  /// 앱 부제목
  ///
  /// In ko, this message translates to:
  /// **'가족, 커플, 룸메이트와 함께\n가계부를 관리하세요'**
  String get appSubtitle;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @commonConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonConfirm;

  /// No description provided for @commonEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get commonEdit;

  /// No description provided for @commonDetail.
  ///
  /// In ko, this message translates to:
  /// **'상세'**
  String get commonDetail;

  /// No description provided for @commonReject.
  ///
  /// In ko, this message translates to:
  /// **'거부'**
  String get commonReject;

  /// No description provided for @commonAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get commonRetry;

  /// No description provided for @commonYes.
  ///
  /// In ko, this message translates to:
  /// **'예'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In ko, this message translates to:
  /// **'아니오'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonOk;

  /// No description provided for @commonBack.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get commonNext;

  /// No description provided for @commonDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get commonDone;

  /// No description provided for @commonSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get commonSearch;

  /// No description provided for @commonLoading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get commonError;

  /// No description provided for @commonSuccess.
  ///
  /// In ko, this message translates to:
  /// **'성공'**
  String get commonSuccess;

  /// No description provided for @tooltipSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get tooltipSearch;

  /// No description provided for @tooltipSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get tooltipSettings;

  /// No description provided for @tooltipBook.
  ///
  /// In ko, this message translates to:
  /// **'가계부 관리'**
  String get tooltipBook;

  /// No description provided for @tooltipPreviousMonth.
  ///
  /// In ko, this message translates to:
  /// **'이전 달'**
  String get tooltipPreviousMonth;

  /// No description provided for @tooltipNextMonth.
  ///
  /// In ko, this message translates to:
  /// **'다음 달'**
  String get tooltipNextMonth;

  /// No description provided for @tooltipPreviousYear.
  ///
  /// In ko, this message translates to:
  /// **'이전 년도'**
  String get tooltipPreviousYear;

  /// No description provided for @tooltipNextYear.
  ///
  /// In ko, this message translates to:
  /// **'다음 년도'**
  String get tooltipNextYear;

  /// No description provided for @tooltipTogglePassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 보기/숨기기'**
  String get tooltipTogglePassword;

  /// No description provided for @tooltipDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get tooltipDelete;

  /// No description provided for @tooltipEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get tooltipEdit;

  /// No description provided for @tooltipClear.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get tooltipClear;

  /// No description provided for @tooltipEditProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필 수정'**
  String get tooltipEditProfile;

  /// No description provided for @tooltipClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get tooltipClose;

  /// No description provided for @tooltipRefresh.
  ///
  /// In ko, this message translates to:
  /// **'새로고침'**
  String get tooltipRefresh;

  /// No description provided for @tooltipFilter.
  ///
  /// In ko, this message translates to:
  /// **'필터'**
  String get tooltipFilter;

  /// No description provided for @tooltipSort.
  ///
  /// In ko, this message translates to:
  /// **'정렬'**
  String get tooltipSort;

  /// No description provided for @tooltipInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get tooltipInfo;

  /// No description provided for @navTabCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get navTabCalendar;

  /// No description provided for @navTabStatistics.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get navTabStatistics;

  /// No description provided for @navTabAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get navTabAsset;

  /// No description provided for @navTabMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get navTabMore;

  /// No description provided for @authLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get authLogin;

  /// No description provided for @authSignup.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get authSignup;

  /// No description provided for @authLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get authLogout;

  /// No description provided for @authEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get authPassword;

  /// No description provided for @authPasswordConfirm.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 확인'**
  String get authPasswordConfirm;

  /// No description provided for @authPasswordShow.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 표시'**
  String get authPasswordShow;

  /// No description provided for @authPasswordHide.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 숨기기'**
  String get authPasswordHide;

  /// No description provided for @authName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get authName;

  /// No description provided for @authForgotPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get authForgotPassword;

  /// No description provided for @authOr.
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get authOr;

  /// No description provided for @authNoAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요?'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있으신가요?'**
  String get authHaveAccount;

  /// No description provided for @authLoginError.
  ///
  /// In ko, this message translates to:
  /// **'로그인 처리 중 오류가 발생했습니다. 다시 시도해주세요.'**
  String get authLoginError;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In ko, this message translates to:
  /// **'이메일 또는 비밀번호가 틀렸습니다.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailNotVerified.
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증이 완료되지 않았습니다. 메일함을 확인해주세요.'**
  String get authEmailNotVerified;

  /// No description provided for @authEmailAlreadyRegistered.
  ///
  /// In ko, this message translates to:
  /// **'이미 가입된 이메일입니다.'**
  String get authEmailAlreadyRegistered;

  /// No description provided for @authSignupTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 계정 만들기'**
  String get authSignupTitle;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'공유 가계부를 시작하려면\n계정을 만들어주세요'**
  String get authSignupSubtitle;

  /// No description provided for @authTermsAgreement.
  ///
  /// In ko, this message translates to:
  /// **'회원가입 시 이용약관 및 개인정보처리방침에\n동의하는 것으로 간주됩니다.'**
  String get authTermsAgreement;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'가입하신 이메일 주소를 입력하시면\n비밀번호 재설정 링크를 보내드립니다.'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authForgotPasswordSend.
  ///
  /// In ko, this message translates to:
  /// **'재설정 링크 보내기'**
  String get authForgotPasswordSend;

  /// No description provided for @authForgotPasswordSent.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정 이메일을 보냈습니다'**
  String get authForgotPasswordSent;

  /// No description provided for @authForgotPasswordSentSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이메일을 확인하고 링크를 클릭하여\n비밀번호를 재설정하세요.'**
  String get authForgotPasswordSentSubtitle;

  /// No description provided for @authForgotPasswordBackToLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인으로 돌아가기'**
  String get authForgotPasswordBackToLogin;

  /// No description provided for @authForgotPasswordSendFailed.
  ///
  /// In ko, this message translates to:
  /// **'이메일 전송 실패: {error}'**
  String authForgotPasswordSendFailed(String error);

  /// No description provided for @validationEmailRequired.
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해주세요'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일 형식이 아닙니다'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력해주세요'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 6자 이상이어야 합니다'**
  String get validationPasswordTooShort;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않습니다'**
  String get validationPasswordMismatch;

  /// No description provided for @validationNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요'**
  String get validationNameRequired;

  /// No description provided for @validationNameTooShort.
  ///
  /// In ko, this message translates to:
  /// **'이름은 2자 이상이어야 합니다'**
  String get validationNameTooShort;

  /// No description provided for @validationPasswordConfirmRequired.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 다시 입력해주세요'**
  String get validationPasswordConfirmRequired;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증'**
  String get emailVerificationTitle;

  /// No description provided for @emailVerificationWaiting.
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증 대기 중'**
  String get emailVerificationWaiting;

  /// No description provided for @emailVerificationComplete.
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증 완료!'**
  String get emailVerificationComplete;

  /// No description provided for @emailVerificationSent.
  ///
  /// In ko, this message translates to:
  /// **'위 이메일로 인증 메일을 보냈습니다.\n메일함을 확인하고 인증 링크를 클릭해주세요.'**
  String get emailVerificationSent;

  /// No description provided for @emailVerificationDone.
  ///
  /// In ko, this message translates to:
  /// **'인증이 완료되었습니다.\n잠시 후 홈 화면으로 이동합니다.'**
  String get emailVerificationDone;

  /// No description provided for @emailVerificationResent.
  ///
  /// In ko, this message translates to:
  /// **'인증 메일을 다시 보냈습니다. 메일함을 확인해주세요.'**
  String get emailVerificationResent;

  /// No description provided for @emailVerificationResendFailed.
  ///
  /// In ko, this message translates to:
  /// **'인증 메일 전송에 실패했습니다: {error}'**
  String emailVerificationResendFailed(String error);

  /// No description provided for @emailVerificationCheckStatus.
  ///
  /// In ko, this message translates to:
  /// **'인증 상태 확인'**
  String get emailVerificationCheckStatus;

  /// No description provided for @emailVerificationResendButton.
  ///
  /// In ko, this message translates to:
  /// **'인증 메일 다시 보내기'**
  String get emailVerificationResendButton;

  /// No description provided for @emailVerificationResendCooldown.
  ///
  /// In ko, this message translates to:
  /// **'재전송 ({seconds}초 후 가능)'**
  String emailVerificationResendCooldown(int seconds);

  /// No description provided for @emailVerificationVerified.
  ///
  /// In ko, this message translates to:
  /// **'인증 완료'**
  String get emailVerificationVerified;

  /// No description provided for @emailVerificationNotVerified.
  ///
  /// In ko, this message translates to:
  /// **'미인증'**
  String get emailVerificationNotVerified;

  /// No description provided for @emailVerificationChecking.
  ///
  /// In ko, this message translates to:
  /// **'확인 중...'**
  String get emailVerificationChecking;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsAppSettings.
  ///
  /// In ko, this message translates to:
  /// **'앱 설정'**
  String get settingsAppSettings;

  /// No description provided for @settingsTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @settingsNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get settingsNotification;

  /// No description provided for @settingsNotificationDescription.
  ///
  /// In ko, this message translates to:
  /// **'공유 변경, 초대 등 알림 받기'**
  String get settingsNotificationDescription;

  /// No description provided for @settingsNotificationSettings.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get settingsNotificationSettings;

  /// No description provided for @settingsNotificationSettingsDescription.
  ///
  /// In ko, this message translates to:
  /// **'알림 유형별 설정'**
  String get settingsNotificationSettingsDescription;

  /// No description provided for @settingsAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get settingsAccount;

  /// No description provided for @settingsProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get settingsProfile;

  /// No description provided for @settingsMyColor.
  ///
  /// In ko, this message translates to:
  /// **'내 색상'**
  String get settingsMyColor;

  /// No description provided for @settingsColorChanged.
  ///
  /// In ko, this message translates to:
  /// **'색상이 변경되었습니다'**
  String get settingsColorChanged;

  /// No description provided for @settingsColorChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'색상 변경 실패: {error}'**
  String settingsColorChangeFailed(String error);

  /// No description provided for @settingsPasswordChange.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get settingsPasswordChange;

  /// No description provided for @settingsData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get settingsData;

  /// No description provided for @settingsDataExport.
  ///
  /// In ko, this message translates to:
  /// **'데이터 내보내기'**
  String get settingsDataExport;

  /// No description provided for @settingsDataExportDescription.
  ///
  /// In ko, this message translates to:
  /// **'거래 내역을 CSV로 내보내기'**
  String get settingsDataExportDescription;

  /// No description provided for @settingsInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get settingsInfo;

  /// No description provided for @settingsAppInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get settingsAppInfo;

  /// No description provided for @settingsVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsTerms.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get settingsTerms;

  /// No description provided for @settingsPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get settingsPrivacy;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트 모드'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'테마 저장 실패: {error}'**
  String settingsThemeSaveFailed(String error);

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 로그아웃하시겠습니까?'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsDeleteAccountConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 탈퇴하시겠습니까?\n\n모든 데이터가 삭제되며 복구할 수 없습니다.'**
  String get settingsDeleteAccountConfirm;

  /// No description provided for @settingsDeleteAccountFailed.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴 실패: {error}'**
  String settingsDeleteAccountFailed(String error);

  /// No description provided for @settingsDisplayNameChanged.
  ///
  /// In ko, this message translates to:
  /// **'표시 이름이 변경되었습니다'**
  String get settingsDisplayNameChanged;

  /// No description provided for @settingsDisplayNameChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'표시 이름 변경 실패: {error}'**
  String settingsDisplayNameChangeFailed(String error);

  /// No description provided for @settingsDisplayName.
  ///
  /// In ko, this message translates to:
  /// **'표시 이름'**
  String get settingsDisplayName;

  /// No description provided for @settingsPasswordChanged.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 변경되었습니다'**
  String get settingsPasswordChanged;

  /// No description provided for @settingsCurrentPassword.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호'**
  String get settingsCurrentPassword;

  /// No description provided for @settingsCurrentPasswordHint.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호를 입력하세요'**
  String get settingsCurrentPasswordHint;

  /// No description provided for @settingsNewPassword.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호'**
  String get settingsNewPassword;

  /// No description provided for @settingsNewPasswordHint.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호를 입력하세요'**
  String get settingsNewPasswordHint;

  /// No description provided for @settingsNewPasswordConfirm.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 확인'**
  String get settingsNewPasswordConfirm;

  /// No description provided for @settingsNewPasswordConfirmHint.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호를 다시 입력하세요'**
  String get settingsNewPasswordConfirmHint;

  /// No description provided for @settingsNewPasswordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호가 일치하지 않습니다'**
  String get settingsNewPasswordMismatch;

  /// No description provided for @settingsChange.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get settingsChange;

  /// No description provided for @settingsLanguageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get settingsLanguageKorean;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageChanged.
  ///
  /// In ko, this message translates to:
  /// **'언어가 변경되었습니다'**
  String get settingsLanguageChanged;

  /// No description provided for @settingsFeaturePreparing.
  ///
  /// In ko, this message translates to:
  /// **'준비 중인 기능입니다'**
  String get settingsFeaturePreparing;

  /// No description provided for @settingsAboutAppName.
  ///
  /// In ko, this message translates to:
  /// **'공유 가계부'**
  String get settingsAboutAppName;

  /// No description provided for @settingsAboutAppDescription.
  ///
  /// In ko, this message translates to:
  /// **'Flutter + Supabase로 만든 공유 가계부 앱입니다.'**
  String get settingsAboutAppDescription;

  /// No description provided for @settingsAboutAppSubDescription.
  ///
  /// In ko, this message translates to:
  /// **'가족, 연인, 룸메이트와 함께 지출을 관리하세요.'**
  String get settingsAboutAppSubDescription;

  /// No description provided for @ledgerTitle.
  ///
  /// In ko, this message translates to:
  /// **'가계부'**
  String get ledgerTitle;

  /// No description provided for @ledgerManagement.
  ///
  /// In ko, this message translates to:
  /// **'가계부 관리'**
  String get ledgerManagement;

  /// No description provided for @ledgerShareManagement.
  ///
  /// In ko, this message translates to:
  /// **'가계부 및 공유 관리'**
  String get ledgerShareManagement;

  /// No description provided for @ledgerCreate.
  ///
  /// In ko, this message translates to:
  /// **'가계부 생성하기'**
  String get ledgerCreate;

  /// No description provided for @ledgerNew.
  ///
  /// In ko, this message translates to:
  /// **'새 가계부'**
  String get ledgerNew;

  /// No description provided for @ledgerName.
  ///
  /// In ko, this message translates to:
  /// **'가계부 이름'**
  String get ledgerName;

  /// No description provided for @ledgerNameHint.
  ///
  /// In ko, this message translates to:
  /// **'가계부 이름을 입력하세요'**
  String get ledgerNameHint;

  /// No description provided for @ledgerDescription.
  ///
  /// In ko, this message translates to:
  /// **'설명 (선택)'**
  String get ledgerDescription;

  /// No description provided for @ledgerCurrency.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get ledgerCurrency;

  /// No description provided for @ledgerShared.
  ///
  /// In ko, this message translates to:
  /// **'공유 가계부'**
  String get ledgerShared;

  /// No description provided for @ledgerPersonal.
  ///
  /// In ko, this message translates to:
  /// **'개인 가계부'**
  String get ledgerPersonal;

  /// No description provided for @ledgerInUse.
  ///
  /// In ko, this message translates to:
  /// **'사용중'**
  String get ledgerInUse;

  /// No description provided for @ledgerEmpty.
  ///
  /// In ko, this message translates to:
  /// **'가계부가 없습니다'**
  String get ledgerEmpty;

  /// No description provided for @ledgerEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'가계부를 생성하여 시작하세요'**
  String get ledgerEmptySubtitle;

  /// No description provided for @ledgerCreated.
  ///
  /// In ko, this message translates to:
  /// **'가계부가 생성되었습니다'**
  String get ledgerCreated;

  /// No description provided for @ledgerUpdated.
  ///
  /// In ko, this message translates to:
  /// **'가계부가 수정되었습니다'**
  String get ledgerUpdated;

  /// No description provided for @ledgerDeleted.
  ///
  /// In ko, this message translates to:
  /// **'가계부가 삭제되었습니다'**
  String get ledgerDeleted;

  /// No description provided for @ledgerDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패: {error}'**
  String ledgerDeleteFailed(String error);

  /// No description provided for @ledgerDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'가계부 삭제'**
  String get ledgerDeleteConfirmTitle;

  /// No description provided for @ledgerDeleteConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'현재 사용 중인 가계부입니다.\n삭제 후 다른 가계부로 자동 전환됩니다.\n\n이 가계부에 기록된 모든 거래, 카테고리, 예산이 함께 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'**
  String get ledgerDeleteConfirmMessage;

  /// No description provided for @ledgerDeleteNotAllowed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 불가'**
  String get ledgerDeleteNotAllowed;

  /// No description provided for @ledgerDeleteNotAllowedMessage.
  ///
  /// In ko, this message translates to:
  /// **'최소 1개의 가계부가 필요합니다.\n다른 가계부를 먼저 생성해주세요.'**
  String get ledgerDeleteNotAllowedMessage;

  /// No description provided for @ledgerChangeConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'가계부 변경'**
  String get ledgerChangeConfirmTitle;

  /// No description provided for @ledgerChangeConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 가계부를 사용하시겠습니까?'**
  String ledgerChangeConfirmMessage(String name);

  /// No description provided for @ledgerUse.
  ///
  /// In ko, this message translates to:
  /// **'사용'**
  String get ledgerUse;

  /// No description provided for @ledgerMyLedgers.
  ///
  /// In ko, this message translates to:
  /// **'내 가계부'**
  String get ledgerMyLedgers;

  /// No description provided for @ledgerInvitedLedgers.
  ///
  /// In ko, this message translates to:
  /// **'초대받은 가계부'**
  String get ledgerInvitedLedgers;

  /// No description provided for @ledgerSelectorMyLedgers.
  ///
  /// In ko, this message translates to:
  /// **'내 가계부'**
  String get ledgerSelectorMyLedgers;

  /// No description provided for @ledgerSelectorSharedLedgers.
  ///
  /// In ko, this message translates to:
  /// **'공유 가계부'**
  String get ledgerSelectorSharedLedgers;

  /// No description provided for @shareInvite.
  ///
  /// In ko, this message translates to:
  /// **'초대'**
  String get shareInvite;

  /// No description provided for @shareMemberInvite.
  ///
  /// In ko, this message translates to:
  /// **'멤버 초대'**
  String get shareMemberInvite;

  /// No description provided for @shareRole.
  ///
  /// In ko, this message translates to:
  /// **'역할'**
  String get shareRole;

  /// No description provided for @shareRoleMember.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get shareRoleMember;

  /// No description provided for @shareRoleMemberDescription.
  ///
  /// In ko, this message translates to:
  /// **'거래 내역 조회/추가/수정/삭제'**
  String get shareRoleMemberDescription;

  /// No description provided for @shareRoleAdmin.
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get shareRoleAdmin;

  /// No description provided for @shareRoleAdminDescription.
  ///
  /// In ko, this message translates to:
  /// **'거래 + 카테고리/예산 관리 + 멤버 초대'**
  String get shareRoleAdminDescription;

  /// No description provided for @shareInviteSent.
  ///
  /// In ko, this message translates to:
  /// **'초대를 보냈습니다'**
  String get shareInviteSent;

  /// No description provided for @shareInviteAccepted.
  ///
  /// In ko, this message translates to:
  /// **'초대를 수락했습니다'**
  String get shareInviteAccepted;

  /// No description provided for @shareInviteRejected.
  ///
  /// In ko, this message translates to:
  /// **'초대를 거부했습니다'**
  String get shareInviteRejected;

  /// No description provided for @shareInviteCancelled.
  ///
  /// In ko, this message translates to:
  /// **'초대를 취소했습니다'**
  String get shareInviteCancelled;

  /// No description provided for @shareInviteCancelConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'초대 취소'**
  String get shareInviteCancelConfirmTitle;

  /// No description provided for @shareInviteCancelConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'\'{email}\'님에게 보낸 초대를 취소하시겠습니까?'**
  String shareInviteCancelConfirmMessage(String email);

  /// No description provided for @shareInviteRejectConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'초대 거부'**
  String get shareInviteRejectConfirmTitle;

  /// No description provided for @shareInviteRejectConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 초대를 거부하시겠습니까?\n거부하면 목록에서 사라집니다.'**
  String shareInviteRejectConfirmMessage(String name);

  /// No description provided for @shareLeaveConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'가계부 탈퇴'**
  String get shareLeaveConfirmTitle;

  /// No description provided for @shareLeaveConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\'에서 탈퇴하시겠습니까?\n탈퇴하면 해당 가계부의 데이터에 더 이상 접근할 수 없습니다.'**
  String shareLeaveConfirmMessage(String name);

  /// No description provided for @shareLeave.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴'**
  String get shareLeave;

  /// No description provided for @shareReject.
  ///
  /// In ko, this message translates to:
  /// **'거부'**
  String get shareReject;

  /// No description provided for @categoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get categoryTitle;

  /// No description provided for @categoryManagement.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 관리'**
  String get categoryManagement;

  /// No description provided for @categoryAdd.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 추가'**
  String get categoryAdd;

  /// No description provided for @categoryEdit.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 수정'**
  String get categoryEdit;

  /// No description provided for @categoryName.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 이름'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 이름을 입력하세요'**
  String get categoryNameHint;

  /// No description provided for @categoryNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 이름을 입력해주세요'**
  String get categoryNameRequired;

  /// No description provided for @categoryDeleted.
  ///
  /// In ko, this message translates to:
  /// **'카테고리가 삭제되었습니다'**
  String get categoryDeleted;

  /// No description provided for @categoryDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패: {error}'**
  String categoryDeleteFailed(String error);

  /// No description provided for @categoryDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 삭제'**
  String get categoryDeleteConfirmTitle;

  /// No description provided for @categoryDeleteConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 카테고리로 기록된 거래는 삭제되지 않습니다.'**
  String get categoryDeleteConfirmMessage;

  /// No description provided for @categoryAdded.
  ///
  /// In ko, this message translates to:
  /// **'카테고리가 추가되었습니다'**
  String get categoryAdded;

  /// No description provided for @categoryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 {type} 카테고리가 없습니다'**
  String categoryEmpty(String type);

  /// No description provided for @transactionExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get transactionExpense;

  /// No description provided for @transactionIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get transactionIncome;

  /// No description provided for @transactionAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get transactionAsset;

  /// No description provided for @transactionTypeLabel.
  ///
  /// In ko, this message translates to:
  /// **'거래 유형'**
  String get transactionTypeLabel;

  /// No description provided for @transactionTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get transactionTitle;

  /// No description provided for @transactionMerchant.
  ///
  /// In ko, this message translates to:
  /// **'가맹점'**
  String get transactionMerchant;

  /// No description provided for @transactionMerchantHint.
  ///
  /// In ko, this message translates to:
  /// **'가맹점명을 입력하세요'**
  String get transactionMerchantHint;

  /// No description provided for @transactionAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get transactionAmount;

  /// No description provided for @transactionAmountHint.
  ///
  /// In ko, this message translates to:
  /// **'금액을 입력하세요'**
  String get transactionAmountHint;

  /// No description provided for @transactionAmountUnit.
  ///
  /// In ko, this message translates to:
  /// **'원'**
  String get transactionAmountUnit;

  /// No description provided for @noCategoryAvailable.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능한 카테고리가 없습니다'**
  String get noCategoryAvailable;

  /// No description provided for @transactionCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get transactionCategory;

  /// No description provided for @transactionPaymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제수단'**
  String get transactionPaymentMethod;

  /// No description provided for @transactionPaymentMethodOptional.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 (선택)'**
  String get transactionPaymentMethodOptional;

  /// No description provided for @transactionMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get transactionMemo;

  /// No description provided for @transactionMemoOptional.
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get transactionMemoOptional;

  /// No description provided for @transactionMemoHint.
  ///
  /// In ko, this message translates to:
  /// **'추가 메모를 입력하세요'**
  String get transactionMemoHint;

  /// No description provided for @transactionAdded.
  ///
  /// In ko, this message translates to:
  /// **'거래가 추가되었습니다'**
  String get transactionAdded;

  /// No description provided for @transactionUpdated.
  ///
  /// In ko, this message translates to:
  /// **'거래가 수정되었습니다'**
  String get transactionUpdated;

  /// No description provided for @transactionNone.
  ///
  /// In ko, this message translates to:
  /// **'선택 안함'**
  String get transactionNone;

  /// No description provided for @transactionQuickExpense.
  ///
  /// In ko, this message translates to:
  /// **'빠른 지출 추가'**
  String get transactionQuickExpense;

  /// No description provided for @transactionExpenseAdded.
  ///
  /// In ko, this message translates to:
  /// **'지출이 추가되었습니다'**
  String get transactionExpenseAdded;

  /// No description provided for @transactionAmountRequired.
  ///
  /// In ko, this message translates to:
  /// **'금액을 입력해주세요'**
  String get transactionAmountRequired;

  /// No description provided for @transactionTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해주세요'**
  String get transactionTitleRequired;

  /// No description provided for @transactionCategoryLoadError.
  ///
  /// In ko, this message translates to:
  /// **'카테고리를 불러올 수 없습니다'**
  String get transactionCategoryLoadError;

  /// No description provided for @transactionNoTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 없음'**
  String get transactionNoTitle;

  /// No description provided for @transactionDeleted.
  ///
  /// In ko, this message translates to:
  /// **'거래가 삭제되었습니다'**
  String get transactionDeleted;

  /// No description provided for @transactionDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패: {error}'**
  String transactionDeleteFailed(String error);

  /// No description provided for @transactionDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'거래 삭제'**
  String get transactionDeleteConfirmTitle;

  /// No description provided for @transactionDeleteConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 삭제하시겠습니까?'**
  String get transactionDeleteConfirmMessage;

  /// No description provided for @labelTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get labelTitle;

  /// No description provided for @labelMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get labelMemo;

  /// No description provided for @labelAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get labelAmount;

  /// No description provided for @labelDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get labelDate;

  /// No description provided for @labelCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get labelCategory;

  /// No description provided for @labelPaymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제수단'**
  String get labelPaymentMethod;

  /// No description provided for @labelAuthor.
  ///
  /// In ko, this message translates to:
  /// **'작성자'**
  String get labelAuthor;

  /// No description provided for @maturityDateSelect.
  ///
  /// In ko, this message translates to:
  /// **'만기일 선택'**
  String get maturityDateSelect;

  /// No description provided for @installmentInfoRequired.
  ///
  /// In ko, this message translates to:
  /// **'할부 정보를 입력해주세요'**
  String get installmentInfoRequired;

  /// No description provided for @installmentLabel.
  ///
  /// In ko, this message translates to:
  /// **'할부'**
  String get installmentLabel;

  /// No description provided for @installmentRegistered.
  ///
  /// In ko, this message translates to:
  /// **'{months}개월 할부가 등록되었습니다'**
  String installmentRegistered(int months);

  /// No description provided for @recurringRegistered.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래가 등록되었습니다 ({endText})'**
  String recurringRegistered(String endText);

  /// No description provided for @recurringUntil.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월까지'**
  String recurringUntil(int year, int month);

  /// No description provided for @recurringContinue.
  ///
  /// In ko, this message translates to:
  /// **'계속'**
  String get recurringContinue;

  /// No description provided for @summaryBalance.
  ///
  /// In ko, this message translates to:
  /// **'합계'**
  String get summaryBalance;

  /// No description provided for @maturityDateSelectOptional.
  ///
  /// In ko, this message translates to:
  /// **'만기일 선택 (선택사항)'**
  String get maturityDateSelectOptional;

  /// No description provided for @recurringPeriod.
  ///
  /// In ko, this message translates to:
  /// **'반복 주기'**
  String get recurringPeriod;

  /// No description provided for @recurringNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get recurringNone;

  /// No description provided for @recurringDaily.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get recurringDaily;

  /// No description provided for @recurringMonthly.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get recurringMonthly;

  /// No description provided for @recurringYearly.
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get recurringYearly;

  /// No description provided for @recurringEndDate.
  ///
  /// In ko, this message translates to:
  /// **'종료일'**
  String get recurringEndDate;

  /// No description provided for @recurringEndMonth.
  ///
  /// In ko, this message translates to:
  /// **'종료월'**
  String get recurringEndMonth;

  /// No description provided for @recurringEndYear.
  ///
  /// In ko, this message translates to:
  /// **'종료년'**
  String get recurringEndYear;

  /// No description provided for @recurringContinueRepeat.
  ///
  /// In ko, this message translates to:
  /// **'계속 반복'**
  String get recurringContinueRepeat;

  /// No description provided for @recurringClearEndDate.
  ///
  /// In ko, this message translates to:
  /// **'종료일 해제'**
  String get recurringClearEndDate;

  /// No description provided for @recurringTransactionCount.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}건의 거래가 생성됩니다'**
  String recurringTransactionCount(int count);

  /// No description provided for @recurringDailyAutoCreate.
  ///
  /// In ko, this message translates to:
  /// **'계속 반복 (매일 자동 생성)'**
  String get recurringDailyAutoCreate;

  /// No description provided for @fixedExpenseRegister.
  ///
  /// In ko, this message translates to:
  /// **'고정비로 등록'**
  String get fixedExpenseRegister;

  /// No description provided for @fixedExpenseDescription.
  ///
  /// In ko, this message translates to:
  /// **'월세, 보험료 등 정기적으로 지출되는 금액'**
  String get fixedExpenseDescription;

  /// No description provided for @yearLabel.
  ///
  /// In ko, this message translates to:
  /// **'년도'**
  String get yearLabel;

  /// No description provided for @monthLabel.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get monthLabel;

  /// No description provided for @yearFormat.
  ///
  /// In ko, this message translates to:
  /// **'{year}년'**
  String yearFormat(int year);

  /// No description provided for @monthFormat.
  ///
  /// In ko, this message translates to:
  /// **'{month}월'**
  String monthFormat(int month);

  /// No description provided for @installmentInput.
  ///
  /// In ko, this message translates to:
  /// **'할부로 입력'**
  String get installmentInput;

  /// No description provided for @installmentInputDescription.
  ///
  /// In ko, this message translates to:
  /// **'총금액을 여러 달에 나눠서 기록합니다'**
  String get installmentInputDescription;

  /// No description provided for @installmentApplied.
  ///
  /// In ko, this message translates to:
  /// **'할부 적용됨'**
  String get installmentApplied;

  /// No description provided for @installmentTotalAmount.
  ///
  /// In ko, this message translates to:
  /// **'총 금액'**
  String get installmentTotalAmount;

  /// No description provided for @installmentMonthlyPayment.
  ///
  /// In ko, this message translates to:
  /// **'월 납입금'**
  String get installmentMonthlyPayment;

  /// No description provided for @installmentFirstMonth.
  ///
  /// In ko, this message translates to:
  /// **'첫 달'**
  String get installmentFirstMonth;

  /// No description provided for @installmentPeriod.
  ///
  /// In ko, this message translates to:
  /// **'할부 기간'**
  String get installmentPeriod;

  /// No description provided for @installmentMonths.
  ///
  /// In ko, this message translates to:
  /// **'{months}개월'**
  String installmentMonths(int months);

  /// No description provided for @installmentEndMonth.
  ///
  /// In ko, this message translates to:
  /// **'종료월'**
  String get installmentEndMonth;

  /// No description provided for @installmentModify.
  ///
  /// In ko, this message translates to:
  /// **'수정하기'**
  String get installmentModify;

  /// No description provided for @installmentTotalAmountHint.
  ///
  /// In ko, this message translates to:
  /// **'할부 총 금액을 입력하세요'**
  String get installmentTotalAmountHint;

  /// No description provided for @installmentMonthsLabel.
  ///
  /// In ko, this message translates to:
  /// **'개월 수'**
  String get installmentMonthsLabel;

  /// No description provided for @installmentMonthsHint.
  ///
  /// In ko, this message translates to:
  /// **'1-60개월'**
  String get installmentMonthsHint;

  /// No description provided for @installmentPreview.
  ///
  /// In ko, this message translates to:
  /// **'할부 계산 미리보기'**
  String get installmentPreview;

  /// No description provided for @installmentApply.
  ///
  /// In ko, this message translates to:
  /// **'할부 적용'**
  String get installmentApply;

  /// No description provided for @installmentAmountError.
  ///
  /// In ko, this message translates to:
  /// **'금액이 개월 수보다 커야 합니다'**
  String get installmentAmountError;

  /// No description provided for @categoryAddType.
  ///
  /// In ko, this message translates to:
  /// **'{type} 카테고리 추가'**
  String categoryAddType(String type);

  /// No description provided for @categoryNameHintExample.
  ///
  /// In ko, this message translates to:
  /// **'예: 식비, 교통비'**
  String get categoryNameHintExample;

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 카테고리를 삭제하시겠습니까?'**
  String categoryDeleteConfirm(String name);

  /// No description provided for @paymentMethodNameHintExample.
  ///
  /// In ko, this message translates to:
  /// **'예: 신용카드, 현금'**
  String get paymentMethodNameHintExample;

  /// No description provided for @paymentMethodDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 결제수단을 삭제하시겠습니까?'**
  String paymentMethodDeleteConfirm(String name);

  /// No description provided for @paymentMethodTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제수단'**
  String get paymentMethodTitle;

  /// No description provided for @paymentMethodManagement.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 관리'**
  String get paymentMethodManagement;

  /// No description provided for @paymentMethodAdd.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 추가'**
  String get paymentMethodAdd;

  /// No description provided for @paymentMethodEdit.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 수정'**
  String get paymentMethodEdit;

  /// No description provided for @paymentMethodName.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 이름'**
  String get paymentMethodName;

  /// No description provided for @paymentMethodNameHint.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 이름을 입력하세요'**
  String get paymentMethodNameHint;

  /// No description provided for @paymentMethodNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 이름을 입력해주세요'**
  String get paymentMethodNameRequired;

  /// No description provided for @paymentMethodDeleted.
  ///
  /// In ko, this message translates to:
  /// **'결제수단이 삭제되었습니다'**
  String get paymentMethodDeleted;

  /// No description provided for @paymentMethodDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패: {error}'**
  String paymentMethodDeleteFailed(String error);

  /// No description provided for @paymentMethodDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 삭제'**
  String get paymentMethodDeleteConfirmTitle;

  /// No description provided for @paymentMethodDeleteConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 결제수단으로 기록된 거래의 결제수단 정보가 삭제됩니다.'**
  String get paymentMethodDeleteConfirmMessage;

  /// No description provided for @paymentMethodAdded.
  ///
  /// In ko, this message translates to:
  /// **'결제수단이 추가되었습니다'**
  String get paymentMethodAdded;

  /// No description provided for @paymentMethodUpdated.
  ///
  /// In ko, this message translates to:
  /// **'결제수단이 수정되었습니다'**
  String get paymentMethodUpdated;

  /// No description provided for @paymentMethodEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 결제수단이 없습니다'**
  String get paymentMethodEmpty;

  /// No description provided for @paymentMethodNotFound.
  ///
  /// In ko, this message translates to:
  /// **'결제수단을 찾을 수 없습니다'**
  String get paymentMethodNotFound;

  /// No description provided for @paymentMethodDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 결제수단'**
  String get paymentMethodDefault;

  /// No description provided for @paymentMethodDetectionKeywords.
  ///
  /// In ko, this message translates to:
  /// **'감지 키워드'**
  String get paymentMethodDetectionKeywords;

  /// No description provided for @paymentMethodDetectionKeywordsHint.
  ///
  /// In ko, this message translates to:
  /// **'쉼표로 구분하여 입력하세요 (예: KB국민, KB국민카드)'**
  String get paymentMethodDetectionKeywordsHint;

  /// No description provided for @paymentMethodDetectionKeywordsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'입력된 키워드가 메시지에 포함되면 자동으로 감지합니다'**
  String get paymentMethodDetectionKeywordsSubtitle;

  /// No description provided for @paymentMethodAmountPattern.
  ///
  /// In ko, this message translates to:
  /// **'금액 패턴'**
  String get paymentMethodAmountPattern;

  /// No description provided for @paymentMethodCurrentRules.
  ///
  /// In ko, this message translates to:
  /// **'현재 규칙으로 수집되는 정보'**
  String get paymentMethodCurrentRules;

  /// No description provided for @paymentMethodEditKeywords.
  ///
  /// In ko, this message translates to:
  /// **'키워드 수정'**
  String get paymentMethodEditKeywords;

  /// No description provided for @paymentMethodAmountPatternReadOnly.
  ///
  /// In ko, this message translates to:
  /// **'\'원\' 앞의 숫자'**
  String get paymentMethodAmountPatternReadOnly;

  /// No description provided for @paymentMethodAmountPatternNote.
  ///
  /// In ko, this message translates to:
  /// **'금액 패턴은 수정할 수 없습니다'**
  String get paymentMethodAmountPatternNote;

  /// No description provided for @paymentMethodTab.
  ///
  /// In ko, this message translates to:
  /// **'결제수단'**
  String get paymentMethodTab;

  /// No description provided for @paymentMethodEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'결제수단을 추가하여 시작하세요'**
  String get paymentMethodEmptySubtitle;

  /// No description provided for @paymentMethodNoPermissionToDelete.
  ///
  /// In ko, this message translates to:
  /// **'이 결제수단을 삭제할 권한이 없습니다'**
  String get paymentMethodNoPermissionToDelete;

  /// No description provided for @paymentMethodOptions.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 옵션'**
  String get paymentMethodOptions;

  /// No description provided for @sharedPaymentMethodTitle.
  ///
  /// In ko, this message translates to:
  /// **'공유 결제수단'**
  String get sharedPaymentMethodTitle;

  /// No description provided for @sharedPaymentMethodDescription.
  ///
  /// In ko, this message translates to:
  /// **'가계부 멤버 모두와 공유됩니다'**
  String get sharedPaymentMethodDescription;

  /// No description provided for @sharedPaymentMethodEmpty.
  ///
  /// In ko, this message translates to:
  /// **'공유 결제수단이 없습니다'**
  String get sharedPaymentMethodEmpty;

  /// No description provided for @sharedPaymentMethodAdd.
  ///
  /// In ko, this message translates to:
  /// **'공유 결제수단 추가'**
  String get sharedPaymentMethodAdd;

  /// No description provided for @autoCollectTab.
  ///
  /// In ko, this message translates to:
  /// **'수집내역'**
  String get autoCollectTab;

  /// No description provided for @autoCollectTitle.
  ///
  /// In ko, this message translates to:
  /// **'자동수집'**
  String get autoCollectTitle;

  /// No description provided for @autoCollectDescription.
  ///
  /// In ko, this message translates to:
  /// **'SMS/푸시 알림에서 거래를 자동으로 감지합니다'**
  String get autoCollectDescription;

  /// No description provided for @autoCollectPaymentMethodEmpty.
  ///
  /// In ko, this message translates to:
  /// **'자동수집 결제수단이 없습니다'**
  String get autoCollectPaymentMethodEmpty;

  /// No description provided for @autoCollectPaymentMethodAdd.
  ///
  /// In ko, this message translates to:
  /// **'자동수집 추가'**
  String get autoCollectPaymentMethodAdd;

  /// No description provided for @autoProcessSettings.
  ///
  /// In ko, this message translates to:
  /// **'자동 처리 설정'**
  String get autoProcessSettings;

  /// No description provided for @autoSaveModeOff.
  ///
  /// In ko, this message translates to:
  /// **'꺼짐'**
  String get autoSaveModeOff;

  /// No description provided for @autoSaveModeSuggest.
  ///
  /// In ko, this message translates to:
  /// **'제안'**
  String get autoSaveModeSuggest;

  /// No description provided for @autoSaveModeAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동'**
  String get autoSaveModeAuto;

  /// No description provided for @pendingTransactionTab.
  ///
  /// In ko, this message translates to:
  /// **'자동수집내역'**
  String get pendingTransactionTab;

  /// No description provided for @pendingTransactionStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'대기중'**
  String get pendingTransactionStatusPending;

  /// No description provided for @pendingTransactionStatusConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'확인됨'**
  String get pendingTransactionStatusConfirmed;

  /// No description provided for @pendingTransactionStatusRejected.
  ///
  /// In ko, this message translates to:
  /// **'거부됨'**
  String get pendingTransactionStatusRejected;

  /// No description provided for @pendingTransactionEmptyPending.
  ///
  /// In ko, this message translates to:
  /// **'대기 중인 거래가 없습니다'**
  String get pendingTransactionEmptyPending;

  /// No description provided for @pendingTransactionEmptyConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'확인된 거래가 없습니다'**
  String get pendingTransactionEmptyConfirmed;

  /// No description provided for @pendingTransactionEmptyRejected.
  ///
  /// In ko, this message translates to:
  /// **'거부된 거래가 없습니다'**
  String get pendingTransactionEmptyRejected;

  /// No description provided for @pendingTransactionEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'SMS/푸시 알림에서 감지된 거래가 여기 표시됩니다'**
  String get pendingTransactionEmptySubtitle;

  /// No description provided for @noAmountInfo.
  ///
  /// In ko, this message translates to:
  /// **'금액 정보 없음'**
  String get noAmountInfo;

  /// No description provided for @dateGroupToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get dateGroupToday;

  /// No description provided for @dateGroupYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get dateGroupYesterday;

  /// No description provided for @dateGroupThisWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get dateGroupThisWeek;

  /// No description provided for @dateGroupThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get dateGroupThisMonth;

  /// No description provided for @dateGroupOlder.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get dateGroupOlder;

  /// No description provided for @sourceTypeSms.
  ///
  /// In ko, this message translates to:
  /// **'SMS'**
  String get sourceTypeSms;

  /// No description provided for @sourceTypeNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get sourceTypeNotification;

  /// No description provided for @pendingTransactionStatusSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장됨'**
  String get pendingTransactionStatusSaved;

  /// No description provided for @pendingTransactionStatusWaiting.
  ///
  /// In ko, this message translates to:
  /// **'대기중'**
  String get pendingTransactionStatusWaiting;

  /// No description provided for @pendingTransactionStatusDenied.
  ///
  /// In ko, this message translates to:
  /// **'거부됨'**
  String get pendingTransactionStatusDenied;

  /// No description provided for @pendingTransactionParsingFailed.
  ///
  /// In ko, this message translates to:
  /// **'거래 정보를 파싱할 수 없습니다'**
  String get pendingTransactionParsingFailed;

  /// No description provided for @pendingTransactionDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'거래 삭제'**
  String get pendingTransactionDeleteConfirmTitle;

  /// No description provided for @pendingTransactionDeleteConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 삭제하시겠습니까?'**
  String get pendingTransactionDeleteConfirmMessage;

  /// No description provided for @pendingTransactionDeleted.
  ///
  /// In ko, this message translates to:
  /// **'거래가 삭제되었습니다'**
  String get pendingTransactionDeleted;

  /// No description provided for @pendingTransactionDeleteAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 삭제'**
  String get pendingTransactionDeleteAll;

  /// No description provided for @pendingTransactionDeleteAllConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'모두 삭제'**
  String get pendingTransactionDeleteAllConfirmTitle;

  /// No description provided for @pendingTransactionDeleteAllConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'{status} 내역 {count}건을 모두 삭제하시겠습니까?'**
  String pendingTransactionDeleteAllConfirmMessage(String status, int count);

  /// No description provided for @pendingTransactionDeleteAllSuccess.
  ///
  /// In ko, this message translates to:
  /// **'모든 내역이 삭제되었습니다'**
  String get pendingTransactionDeleteAllSuccess;

  /// No description provided for @pendingTransactionDetail.
  ///
  /// In ko, this message translates to:
  /// **'수집 내역 상세'**
  String get pendingTransactionDetail;

  /// No description provided for @pendingTransactionReject.
  ///
  /// In ko, this message translates to:
  /// **'거부'**
  String get pendingTransactionReject;

  /// No description provided for @pendingTransactionUpdate.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get pendingTransactionUpdate;

  /// No description provided for @pendingTransactionConfirm.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get pendingTransactionConfirm;

  /// No description provided for @pendingTransactionConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'거래가 저장되었습니다'**
  String get pendingTransactionConfirmed;

  /// No description provided for @pendingTransactionUpdated.
  ///
  /// In ko, this message translates to:
  /// **'수정되었습니다'**
  String get pendingTransactionUpdated;

  /// No description provided for @pendingTransactionRejected.
  ///
  /// In ko, this message translates to:
  /// **'거래가 거부되었습니다'**
  String get pendingTransactionRejected;

  /// No description provided for @pendingTransactionItemCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String pendingTransactionItemCount(int count);

  /// No description provided for @paymentMethodWizardAddTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 추가'**
  String get paymentMethodWizardAddTitle;

  /// No description provided for @paymentMethodWizardEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 수정'**
  String get paymentMethodWizardEditTitle;

  /// No description provided for @paymentMethodWizardManualAddTitle.
  ///
  /// In ko, this message translates to:
  /// **'직접입력 추가'**
  String get paymentMethodWizardManualAddTitle;

  /// No description provided for @paymentMethodWizardAutoCollectAddTitle.
  ///
  /// In ko, this message translates to:
  /// **'자동수집 추가'**
  String get paymentMethodWizardAutoCollectAddTitle;

  /// No description provided for @paymentMethodWizardModeQuestion.
  ///
  /// In ko, this message translates to:
  /// **'어떤 방식으로 추가하시겠습니까?'**
  String get paymentMethodWizardModeQuestion;

  /// No description provided for @paymentMethodWizardManualMode.
  ///
  /// In ko, this message translates to:
  /// **'직접입력'**
  String get paymentMethodWizardManualMode;

  /// No description provided for @paymentMethodWizardAutoCollectMode.
  ///
  /// In ko, this message translates to:
  /// **'자동수집'**
  String get paymentMethodWizardAutoCollectMode;

  /// No description provided for @paymentMethodWizardSharedBadge.
  ///
  /// In ko, this message translates to:
  /// **'공유됨'**
  String get paymentMethodWizardSharedBadge;

  /// No description provided for @paymentMethodWizardPersonalBadge.
  ///
  /// In ko, this message translates to:
  /// **'개인용'**
  String get paymentMethodWizardPersonalBadge;

  /// No description provided for @paymentMethodWizardManualDescription.
  ///
  /// In ko, this message translates to:
  /// **'이름만 입력하여 간단하게 추가합니다.\n가계부 멤버와 공유됩니다.'**
  String get paymentMethodWizardManualDescription;

  /// No description provided for @paymentMethodWizardAutoCollectDescription.
  ///
  /// In ko, this message translates to:
  /// **'SMS/푸시 알림에서 거래를 자동으로 감지합니다.\n나만 사용할 수 있습니다.'**
  String get paymentMethodWizardAutoCollectDescription;

  /// No description provided for @paymentMethodWizardServiceQuestion.
  ///
  /// In ko, this message translates to:
  /// **'어떤 서비스를 이용하시나요?'**
  String get paymentMethodWizardServiceQuestion;

  /// No description provided for @paymentMethodWizardServiceDescription.
  ///
  /// In ko, this message translates to:
  /// **'SMS/푸시 알림에서 거래를 자동으로 감지합니다.'**
  String get paymentMethodWizardServiceDescription;

  /// No description provided for @paymentMethodWizardCategoryCard.
  ///
  /// In ko, this message translates to:
  /// **'카드'**
  String get paymentMethodWizardCategoryCard;

  /// No description provided for @paymentMethodWizardCategoryLocalCurrency.
  ///
  /// In ko, this message translates to:
  /// **'지역화폐'**
  String get paymentMethodWizardCategoryLocalCurrency;

  /// No description provided for @paymentMethodWizardCategoryOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get paymentMethodWizardCategoryOther;

  /// No description provided for @paymentMethodWizardCustomSetup.
  ///
  /// In ko, this message translates to:
  /// **'직접 설정'**
  String get paymentMethodWizardCustomSetup;

  /// No description provided for @paymentMethodWizardCustomSetupDescription.
  ///
  /// In ko, this message translates to:
  /// **'지원하지 않는 서비스를 직접 설정합니다.'**
  String get paymentMethodWizardCustomSetupDescription;

  /// No description provided for @paymentMethodWizardSharedNotice.
  ///
  /// In ko, this message translates to:
  /// **'이 결제수단은 가계부 멤버와 공유됩니다'**
  String get paymentMethodWizardSharedNotice;

  /// No description provided for @paymentMethodWizardPersonalNotice.
  ///
  /// In ko, this message translates to:
  /// **'이 결제수단은 나만 사용할 수 있습니다'**
  String get paymentMethodWizardPersonalNotice;

  /// No description provided for @paymentMethodWizardNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 이름'**
  String get paymentMethodWizardNameLabel;

  /// No description provided for @paymentMethodWizardNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 신한카드, 현금'**
  String get paymentMethodWizardNameHint;

  /// No description provided for @paymentMethodWizardAliasLabel.
  ///
  /// In ko, this message translates to:
  /// **'별칭'**
  String get paymentMethodWizardAliasLabel;

  /// No description provided for @paymentMethodWizardAliasHelper.
  ///
  /// In ko, this message translates to:
  /// **'앱 내에서 표시될 이름입니다.'**
  String get paymentMethodWizardAliasHelper;

  /// No description provided for @paymentMethodWizardAutoCollectRuleTitle.
  ///
  /// In ko, this message translates to:
  /// **'자동 수집 규칙 설정'**
  String get paymentMethodWizardAutoCollectRuleTitle;

  /// No description provided for @paymentMethodWizardImportFromSms.
  ///
  /// In ko, this message translates to:
  /// **'문자에서 가져오기'**
  String get paymentMethodWizardImportFromSms;

  /// No description provided for @paymentMethodWizardKeywordsUpdated.
  ///
  /// In ko, this message translates to:
  /// **'키워드가 업데이트되었습니다.'**
  String get paymentMethodWizardKeywordsUpdated;

  /// No description provided for @paymentMethodWizardCollectSource.
  ///
  /// In ko, this message translates to:
  /// **'수집 방식'**
  String get paymentMethodWizardCollectSource;

  /// No description provided for @paymentMethodWizardSmsSource.
  ///
  /// In ko, this message translates to:
  /// **'문자'**
  String get paymentMethodWizardSmsSource;

  /// No description provided for @paymentMethodWizardPushSource.
  ///
  /// In ko, this message translates to:
  /// **'푸시 알림'**
  String get paymentMethodWizardPushSource;

  /// No description provided for @paymentMethodWizardSampleNotice.
  ///
  /// In ko, this message translates to:
  /// **'아래 메시지는 예시입니다. 실제로 받으시는 알림과 다르다면 수정해주세요.\n수정한 내용에 맞춰 수집 규칙이 변경됩니다.'**
  String get paymentMethodWizardSampleNotice;

  /// No description provided for @paymentMethodWizardCurrentRules.
  ///
  /// In ko, this message translates to:
  /// **'현재 규칙으로 수집되는 정보'**
  String get paymentMethodWizardCurrentRules;

  /// No description provided for @paymentMethodWizardDetectionKeywords.
  ///
  /// In ko, this message translates to:
  /// **'감지 키워드'**
  String get paymentMethodWizardDetectionKeywords;

  /// No description provided for @paymentMethodWizardAmountPattern.
  ///
  /// In ko, this message translates to:
  /// **'금액 패턴'**
  String get paymentMethodWizardAmountPattern;

  /// No description provided for @paymentMethodWizardSaveButton.
  ///
  /// In ko, this message translates to:
  /// **'저장하기'**
  String get paymentMethodWizardSaveButton;

  /// No description provided for @paymentMethodWizardAddButton.
  ///
  /// In ko, this message translates to:
  /// **'추가하기'**
  String get paymentMethodWizardAddButton;

  /// No description provided for @paymentMethodWizardEditKeywordsTitle.
  ///
  /// In ko, this message translates to:
  /// **'감지 키워드 수정'**
  String get paymentMethodWizardEditKeywordsTitle;

  /// No description provided for @paymentMethodWizardEditKeywordsDescription.
  ///
  /// In ko, this message translates to:
  /// **'이 키워드가 포함된 알림이 수집됩니다.'**
  String get paymentMethodWizardEditKeywordsDescription;

  /// No description provided for @paymentMethodWizardKeywordInputHint.
  ///
  /// In ko, this message translates to:
  /// **'새 키워드 입력'**
  String get paymentMethodWizardKeywordInputHint;

  /// No description provided for @paymentMethodWizardKeywordAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get paymentMethodWizardKeywordAdd;

  /// No description provided for @paymentMethodWizardKeywordDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'이미 등록된 키워드입니다'**
  String get paymentMethodWizardKeywordDuplicate;

  /// No description provided for @paymentMethodWizardEditKeywordsMinError.
  ///
  /// In ko, this message translates to:
  /// **'최소 1개 이상의 키워드가 필요합니다'**
  String get paymentMethodWizardEditKeywordsMinError;

  /// No description provided for @paymentMethodWizardSelectSmsTitle.
  ///
  /// In ko, this message translates to:
  /// **'가져올 문자 선택'**
  String get paymentMethodWizardSelectSmsTitle;

  /// No description provided for @paymentMethodWizardSmsPermissionRequired.
  ///
  /// In ko, this message translates to:
  /// **'SMS 권한이 필요합니다.'**
  String get paymentMethodWizardSmsPermissionRequired;

  /// No description provided for @paymentMethodWizardNoFinancialSms.
  ///
  /// In ko, this message translates to:
  /// **'금융 관련 문자를 찾을 수 없습니다.'**
  String get paymentMethodWizardNoFinancialSms;

  /// No description provided for @paymentMethodWizardDuplicateName.
  ///
  /// In ko, this message translates to:
  /// **'이미 존재하는 결제수단 이름입니다'**
  String get paymentMethodWizardDuplicateName;

  /// No description provided for @paymentMethodWizardSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 저장에 실패했습니다'**
  String get paymentMethodWizardSaveFailed;

  /// No description provided for @paymentMethodWizardKeywordsSaved.
  ///
  /// In ko, this message translates to:
  /// **'감지 키워드가 저장되었습니다'**
  String get paymentMethodWizardKeywordsSaved;

  /// No description provided for @paymentMethodWizardKeywordsSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'감지 키워드 저장에 실패했습니다'**
  String get paymentMethodWizardKeywordsSaveFailed;

  /// No description provided for @errorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인해주세요.'**
  String get errorNetwork;

  /// No description provided for @errorSessionExpired.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 만료되었습니다. 다시 로그인해주세요.'**
  String get errorSessionExpired;

  /// No description provided for @errorNotFound.
  ///
  /// In ko, this message translates to:
  /// **'페이지를 찾을 수 없습니다'**
  String get errorNotFound;

  /// No description provided for @errorWithMessage.
  ///
  /// In ko, this message translates to:
  /// **'오류: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @user.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get user;

  /// No description provided for @homeTitle.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get homeTitle;

  /// No description provided for @moreMenuShareManagement.
  ///
  /// In ko, this message translates to:
  /// **'가계부 및 공유 관리'**
  String get moreMenuShareManagement;

  /// No description provided for @moreMenuCategoryManagement.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 관리'**
  String get moreMenuCategoryManagement;

  /// No description provided for @moreMenuPaymentMethodManagement.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 관리'**
  String get moreMenuPaymentMethodManagement;

  /// No description provided for @moreMenuFixedExpenseManagement.
  ///
  /// In ko, this message translates to:
  /// **'고정비 관리'**
  String get moreMenuFixedExpenseManagement;

  /// No description provided for @noHistory.
  ///
  /// In ko, this message translates to:
  /// **'내역 없음'**
  String get noHistory;

  /// No description provided for @statisticsCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get statisticsCategory;

  /// No description provided for @statisticsTrend.
  ///
  /// In ko, this message translates to:
  /// **'추이'**
  String get statisticsTrend;

  /// No description provided for @statisticsPaymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제수단'**
  String get statisticsPaymentMethod;

  /// No description provided for @statisticsCategoryDistribution.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 분포'**
  String get statisticsCategoryDistribution;

  /// No description provided for @statisticsCategoryRanking.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 순위'**
  String get statisticsCategoryRanking;

  /// No description provided for @statisticsNoData.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get statisticsNoData;

  /// No description provided for @statisticsOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get statisticsOther;

  /// No description provided for @statisticsTotalIncome.
  ///
  /// In ko, this message translates to:
  /// **'총 수입'**
  String get statisticsTotalIncome;

  /// No description provided for @statisticsTotalExpense.
  ///
  /// In ko, this message translates to:
  /// **'총 지출'**
  String get statisticsTotalExpense;

  /// No description provided for @statisticsTotalAsset.
  ///
  /// In ko, this message translates to:
  /// **'총 자산'**
  String get statisticsTotalAsset;

  /// No description provided for @statisticsTotal.
  ///
  /// In ko, this message translates to:
  /// **'총 {type}'**
  String statisticsTotal(String type);

  /// No description provided for @statisticsNoPreviousData.
  ///
  /// In ko, this message translates to:
  /// **'지난달 데이터 없음'**
  String get statisticsNoPreviousData;

  /// No description provided for @statisticsIncrease.
  ///
  /// In ko, this message translates to:
  /// **'증가'**
  String get statisticsIncrease;

  /// No description provided for @statisticsDecrease.
  ///
  /// In ko, this message translates to:
  /// **'감소'**
  String get statisticsDecrease;

  /// No description provided for @statisticsSame.
  ///
  /// In ko, this message translates to:
  /// **'동일'**
  String get statisticsSame;

  /// No description provided for @statisticsVsLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'(지난달 대비 {percent}% {change})'**
  String statisticsVsLastMonth(String percent, String change);

  /// No description provided for @statisticsFixed.
  ///
  /// In ko, this message translates to:
  /// **'고정비'**
  String get statisticsFixed;

  /// No description provided for @statisticsVariable.
  ///
  /// In ko, this message translates to:
  /// **'변동비'**
  String get statisticsVariable;

  /// No description provided for @statisticsAverage.
  ///
  /// In ko, this message translates to:
  /// **'평균'**
  String get statisticsAverage;

  /// No description provided for @statisticsDetail.
  ///
  /// In ko, this message translates to:
  /// **'상세 내역'**
  String get statisticsDetail;

  /// No description provided for @statisticsYearMonth.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월'**
  String statisticsYearMonth(int year, int month);

  /// No description provided for @statisticsYear.
  ///
  /// In ko, this message translates to:
  /// **'{year}년'**
  String statisticsYear(int year);

  /// No description provided for @statisticsPaymentDistribution.
  ///
  /// In ko, this message translates to:
  /// **'결제수단별 분포'**
  String get statisticsPaymentDistribution;

  /// No description provided for @statisticsPaymentRanking.
  ///
  /// In ko, this message translates to:
  /// **'결제수단별 순위'**
  String get statisticsPaymentRanking;

  /// No description provided for @statisticsPaymentNotice.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 통계는 지출 내역만 표시됩니다.'**
  String get statisticsPaymentNotice;

  /// No description provided for @assetTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get assetTitle;

  /// No description provided for @assetTotal.
  ///
  /// In ko, this message translates to:
  /// **'총 자산'**
  String get assetTotal;

  /// No description provided for @assetChange.
  ///
  /// In ko, this message translates to:
  /// **'자산 변화'**
  String get assetChange;

  /// No description provided for @assetCategoryDistribution.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 분포'**
  String get assetCategoryDistribution;

  /// No description provided for @assetList.
  ///
  /// In ko, this message translates to:
  /// **'자산 목록'**
  String get assetList;

  /// No description provided for @assetThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 {change}원'**
  String assetThisMonth(String change);

  /// No description provided for @assetGoalTitle.
  ///
  /// In ko, this message translates to:
  /// **'목표'**
  String get assetGoalTitle;

  /// No description provided for @assetGoalSet.
  ///
  /// In ko, this message translates to:
  /// **'목표 설정'**
  String get assetGoalSet;

  /// No description provided for @assetGoalDelete.
  ///
  /// In ko, this message translates to:
  /// **'목표 삭제'**
  String get assetGoalDelete;

  /// No description provided for @assetGoalDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{title}\' 목표를 삭제하시겠습니까?'**
  String assetGoalDeleteConfirm(String title);

  /// No description provided for @assetGoalDeleted.
  ///
  /// In ko, this message translates to:
  /// **'목표가 삭제되었습니다'**
  String get assetGoalDeleted;

  /// No description provided for @assetGoalDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패: {error}'**
  String assetGoalDeleteFailed(String error);

  /// No description provided for @assetGoalEmpty.
  ///
  /// In ko, this message translates to:
  /// **'목표를 설정하고\n자산을 계획적으로 관리하세요'**
  String get assetGoalEmpty;

  /// No description provided for @assetGoalCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재'**
  String get assetGoalCurrent;

  /// No description provided for @assetGoalTarget.
  ///
  /// In ko, this message translates to:
  /// **'목표'**
  String get assetGoalTarget;

  /// No description provided for @assetGoalRemaining.
  ///
  /// In ko, this message translates to:
  /// **'{amount}원 남음'**
  String assetGoalRemaining(String amount);

  /// No description provided for @assetGoalAchieved.
  ///
  /// In ko, this message translates to:
  /// **'목표 달성 완료!'**
  String get assetGoalAchieved;

  /// No description provided for @assetGoalTapForDetails.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 상세 금액 보기'**
  String get assetGoalTapForDetails;

  /// No description provided for @assetGoalLoadError.
  ///
  /// In ko, this message translates to:
  /// **'목표 정보를 불러올 수 없습니다'**
  String get assetGoalLoadError;

  /// No description provided for @fixedExpenseTitle.
  ///
  /// In ko, this message translates to:
  /// **'고정비'**
  String get fixedExpenseTitle;

  /// No description provided for @fixedExpenseManagement.
  ///
  /// In ko, this message translates to:
  /// **'고정비 관리'**
  String get fixedExpenseManagement;

  /// No description provided for @fixedExpenseCategoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'고정비 카테고리'**
  String get fixedExpenseCategoryTitle;

  /// No description provided for @fixedExpenseIncludeInExpense.
  ///
  /// In ko, this message translates to:
  /// **'고정비를 지출에 편입'**
  String get fixedExpenseIncludeInExpense;

  /// No description provided for @fixedExpenseIncludeInExpenseOn.
  ///
  /// In ko, this message translates to:
  /// **'고정비가 달력과 통계의 지출에 포함됩니다'**
  String get fixedExpenseIncludeInExpenseOn;

  /// No description provided for @fixedExpenseIncludeInExpenseOff.
  ///
  /// In ko, this message translates to:
  /// **'고정비가 달력과 통계의 지출에서 제외됩니다'**
  String get fixedExpenseIncludeInExpenseOff;

  /// No description provided for @fixedExpenseIncludedSnackbar.
  ///
  /// In ko, this message translates to:
  /// **'고정비가 지출에 포함됩니다'**
  String get fixedExpenseIncludedSnackbar;

  /// No description provided for @fixedExpenseExcludedSnackbar.
  ///
  /// In ko, this message translates to:
  /// **'고정비가 지출에서 제외됩니다'**
  String get fixedExpenseExcludedSnackbar;

  /// No description provided for @fixedExpenseSettingsFailed.
  ///
  /// In ko, this message translates to:
  /// **'설정 변경 실패: {error}'**
  String fixedExpenseSettingsFailed(String error);

  /// No description provided for @fixedExpenseSettingsLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'설정 로드 실패'**
  String get fixedExpenseSettingsLoadFailed;

  /// No description provided for @fixedExpenseCategoryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 고정비 카테고리가 없습니다'**
  String get fixedExpenseCategoryEmpty;

  /// No description provided for @fixedExpenseCategoryEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'+ 버튼을 눌러 카테고리를 추가하세요'**
  String get fixedExpenseCategoryEmptySubtitle;

  /// No description provided for @fixedExpenseCategoryDelete.
  ///
  /// In ko, this message translates to:
  /// **'고정비 카테고리 삭제'**
  String get fixedExpenseCategoryDelete;

  /// No description provided for @fixedExpenseCategoryDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 카테고리를 삭제하시겠습니까?'**
  String fixedExpenseCategoryDeleteConfirm(String name);

  /// No description provided for @fixedExpenseCategoryAdd.
  ///
  /// In ko, this message translates to:
  /// **'고정비 카테고리 추가'**
  String get fixedExpenseCategoryAdd;

  /// No description provided for @fixedExpenseCategoryEdit.
  ///
  /// In ko, this message translates to:
  /// **'고정비 카테고리 수정'**
  String get fixedExpenseCategoryEdit;

  /// No description provided for @fixedExpenseCategoryNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 월세, 통신비'**
  String get fixedExpenseCategoryNameHint;

  /// No description provided for @categoryUpdated.
  ///
  /// In ko, this message translates to:
  /// **'카테고리가 수정되었습니다'**
  String get categoryUpdated;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsDescription.
  ///
  /// In ko, this message translates to:
  /// **'받고 싶은 알림을 선택하세요'**
  String get notificationSettingsDescription;

  /// No description provided for @notificationSettingsSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'설정 저장 실패: {error}'**
  String notificationSettingsSaveFailed(String error);

  /// No description provided for @notificationSettingsLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정을 불러올 수 없습니다'**
  String get notificationSettingsLoadFailed;

  /// No description provided for @notificationSectionSharedLedger.
  ///
  /// In ko, this message translates to:
  /// **'공유 가계부'**
  String get notificationSectionSharedLedger;

  /// No description provided for @notificationSharedLedgerChange.
  ///
  /// In ko, this message translates to:
  /// **'공유 가계부 변경'**
  String get notificationSharedLedgerChange;

  /// No description provided for @notificationSharedLedgerChangeDesc.
  ///
  /// In ko, this message translates to:
  /// **'다른 멤버가 거래를 추가/수정/삭제했을 때 알림'**
  String get notificationSharedLedgerChangeDesc;

  /// No description provided for @notificationSectionInvite.
  ///
  /// In ko, this message translates to:
  /// **'초대'**
  String get notificationSectionInvite;

  /// No description provided for @notificationInviteReceived.
  ///
  /// In ko, this message translates to:
  /// **'가계부 초대 받음'**
  String get notificationInviteReceived;

  /// No description provided for @notificationInviteReceivedDesc.
  ///
  /// In ko, this message translates to:
  /// **'다른 사용자가 가계부에 초대했을 때 알림'**
  String get notificationInviteReceivedDesc;

  /// No description provided for @notificationInviteAccepted.
  ///
  /// In ko, this message translates to:
  /// **'초대 수락됨'**
  String get notificationInviteAccepted;

  /// No description provided for @notificationInviteAcceptedDesc.
  ///
  /// In ko, this message translates to:
  /// **'내가 보낸 초대를 다른 사용자가 수락했을 때 알림'**
  String get notificationInviteAcceptedDesc;

  /// No description provided for @searchTitle.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'제목/메모로 검색...'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'제목/메모로 거래 내역을 검색하세요'**
  String get searchEmpty;

  /// No description provided for @searchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get searchNoResults;

  /// No description provided for @searchUncategorized.
  ///
  /// In ko, this message translates to:
  /// **'미분류'**
  String get searchUncategorized;

  /// No description provided for @shareManagementTitle.
  ///
  /// In ko, this message translates to:
  /// **'가계부 및 공유 관리'**
  String get shareManagementTitle;

  /// No description provided for @shareMyLedgers.
  ///
  /// In ko, this message translates to:
  /// **'내 가계부'**
  String get shareMyLedgers;

  /// No description provided for @shareInvitedLedgers.
  ///
  /// In ko, this message translates to:
  /// **'초대받은 가계부'**
  String get shareInvitedLedgers;

  /// No description provided for @shareLedgerEmpty.
  ///
  /// In ko, this message translates to:
  /// **'가계부가 없습니다'**
  String get shareLedgerEmpty;

  /// No description provided for @shareLedgerEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'가계부를 생성하여 시작하세요'**
  String get shareLedgerEmptySubtitle;

  /// No description provided for @shareCreateLedger.
  ///
  /// In ko, this message translates to:
  /// **'가계부 생성하기'**
  String get shareCreateLedger;

  /// No description provided for @shareErrorOccurred.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get shareErrorOccurred;

  /// No description provided for @shareLedgerChanged.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 가계부로 변경했습니다'**
  String shareLedgerChanged(String name);

  /// No description provided for @shareLedgerLeft.
  ///
  /// In ko, this message translates to:
  /// **'가계부에서 탈퇴했습니다'**
  String get shareLedgerLeft;

  /// No description provided for @shareInviteCancelText.
  ///
  /// In ko, this message translates to:
  /// **'초대취소'**
  String get shareInviteCancelText;

  /// No description provided for @shareInviteSentMessage.
  ///
  /// In ko, this message translates to:
  /// **'초대를 보냈습니다'**
  String get shareInviteSentMessage;

  /// No description provided for @shareInviteCancelledMessage.
  ///
  /// In ko, this message translates to:
  /// **'초대를 취소했습니다'**
  String get shareInviteCancelledMessage;

  /// No description provided for @shareInviteAcceptedMessage.
  ///
  /// In ko, this message translates to:
  /// **'초대를 수락했습니다'**
  String get shareInviteAcceptedMessage;

  /// No description provided for @shareInviteRejectedMessage.
  ///
  /// In ko, this message translates to:
  /// **'초대를 거부했습니다'**
  String get shareInviteRejectedMessage;

  /// No description provided for @shareEmailHint.
  ///
  /// In ko, this message translates to:
  /// **'example@email.com'**
  String get shareEmailHint;

  /// No description provided for @shareInUse.
  ///
  /// In ko, this message translates to:
  /// **'사용 중'**
  String get shareInUse;

  /// No description provided for @shareUse.
  ///
  /// In ko, this message translates to:
  /// **'사용'**
  String get shareUse;

  /// No description provided for @shareUnknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get shareUnknown;

  /// No description provided for @shareMemberParticipating.
  ///
  /// In ko, this message translates to:
  /// **'멤버로 참여 중'**
  String get shareMemberParticipating;

  /// No description provided for @shareAccept.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get shareAccept;

  /// No description provided for @shareMe.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get shareMe;

  /// No description provided for @shareMemberCount.
  ///
  /// In ko, this message translates to:
  /// **'멤버 {current}/{max}명'**
  String shareMemberCount(int current, int max);

  /// No description provided for @shareMemberFull.
  ///
  /// In ko, this message translates to:
  /// **'멤버 가득 참'**
  String get shareMemberFull;

  /// No description provided for @sharePendingAccept.
  ///
  /// In ko, this message translates to:
  /// **'수락 대기중'**
  String get sharePendingAccept;

  /// No description provided for @shareAccepted.
  ///
  /// In ko, this message translates to:
  /// **'수락됨'**
  String get shareAccepted;

  /// No description provided for @shareRejected.
  ///
  /// In ko, this message translates to:
  /// **'수락 거부됨'**
  String get shareRejected;

  /// No description provided for @shareExpired.
  ///
  /// In ko, this message translates to:
  /// **'초대 만료됨'**
  String get shareExpired;

  /// No description provided for @shareInviterLedger.
  ///
  /// In ko, this message translates to:
  /// **'{email}님의 가계부'**
  String shareInviterLedger(String email);

  /// No description provided for @shareSharingWith.
  ///
  /// In ko, this message translates to:
  /// **'{name}님과 공유 중'**
  String shareSharingWith(String name);

  /// No description provided for @shareSharingWithMultiple.
  ///
  /// In ko, this message translates to:
  /// **'{name1}, {name2}님과 공유 중'**
  String shareSharingWithMultiple(String name1, String name2);

  /// No description provided for @shareSharingWithMore.
  ///
  /// In ko, this message translates to:
  /// **'{name1}, {name2} 외 {count}명과 공유 중'**
  String shareSharingWithMore(String name1, String name2, int count);

  /// No description provided for @shareMemberManagement.
  ///
  /// In ko, this message translates to:
  /// **'공유 멤버 관리'**
  String get shareMemberManagement;

  /// No description provided for @shareMemberRoleOwner.
  ///
  /// In ko, this message translates to:
  /// **'소유자'**
  String get shareMemberRoleOwner;

  /// No description provided for @shareMemberRoleAdmin.
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get shareMemberRoleAdmin;

  /// No description provided for @shareMemberRoleMember.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get shareMemberRoleMember;

  /// No description provided for @shareMemberRemove.
  ///
  /// In ko, this message translates to:
  /// **'방출하기'**
  String get shareMemberRemove;

  /// No description provided for @shareMemberRemoveTitle.
  ///
  /// In ko, this message translates to:
  /// **'멤버 방출'**
  String get shareMemberRemoveTitle;

  /// No description provided for @shareMemberRemoveConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\'님을 가계부에서 방출하시겠습니까?\n\n방출된 멤버는 더 이상 이 가계부에 접근할 수 없습니다.'**
  String shareMemberRemoveConfirm(String name);

  /// No description provided for @shareMemberRemoved.
  ///
  /// In ko, this message translates to:
  /// **'멤버가 방출되었습니다'**
  String get shareMemberRemoved;

  /// No description provided for @ledgerNewTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 가계부'**
  String get ledgerNewTitle;

  /// No description provided for @ledgerEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'가계부 수정'**
  String get ledgerEditTitle;

  /// No description provided for @ledgerNoLedgers.
  ///
  /// In ko, this message translates to:
  /// **'등록된 가계부가 없습니다'**
  String get ledgerNoLedgers;

  /// No description provided for @ledgerCreateButton.
  ///
  /// In ko, this message translates to:
  /// **'가계부 만들기'**
  String get ledgerCreateButton;

  /// No description provided for @ledgerNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'가계부 이름'**
  String get ledgerNameLabel;

  /// No description provided for @ledgerNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'가계부 이름을 입력하세요'**
  String get ledgerNameRequired;

  /// No description provided for @ledgerDescriptionLabel.
  ///
  /// In ko, this message translates to:
  /// **'설명 (선택)'**
  String get ledgerDescriptionLabel;

  /// No description provided for @ledgerCurrencyLabel.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get ledgerCurrencyLabel;

  /// No description provided for @ledgerDeleteNotAllowedTitle.
  ///
  /// In ko, this message translates to:
  /// **'삭제 불가'**
  String get ledgerDeleteNotAllowedTitle;

  /// No description provided for @ledgerDeleteNotAllowedContent.
  ///
  /// In ko, this message translates to:
  /// **'최소 1개의 가계부가 필요합니다.\n다른 가계부를 먼저 생성해주세요.'**
  String get ledgerDeleteNotAllowedContent;

  /// No description provided for @ledgerMemberLoading.
  ///
  /// In ko, this message translates to:
  /// **'멤버 정보 로딩 중...'**
  String get ledgerMemberLoading;

  /// No description provided for @ledgerDeleteConfirmWithName.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 가계부를 삭제하시겠습니까?\n\n이 가계부에 기록된 모든 거래, 카테고리, 예산이 함께 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'**
  String ledgerDeleteConfirmWithName(String name);

  /// No description provided for @ledgerDeleteCurrentInUseWarning.
  ///
  /// In ko, this message translates to:
  /// **'현재 사용 중인 가계부입니다.\n삭제 후 다른 가계부로 자동 전환됩니다.\n\n'**
  String get ledgerDeleteCurrentInUseWarning;

  /// No description provided for @ledgerSharedWithOne.
  ///
  /// In ko, this message translates to:
  /// **'{name}님과 공유 중'**
  String ledgerSharedWithOne(String name);

  /// No description provided for @ledgerSharedWithTwo.
  ///
  /// In ko, this message translates to:
  /// **'{name1}, {name2}님과 공유 중'**
  String ledgerSharedWithTwo(String name1, String name2);

  /// No description provided for @ledgerSharedWithMany.
  ///
  /// In ko, this message translates to:
  /// **'{name1}, {name2} 외 {count}명과 공유 중'**
  String ledgerSharedWithMany(String name1, String name2, int count);

  /// No description provided for @ledgerUser.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get ledgerUser;

  /// No description provided for @calendarDaySun.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get calendarDaySun;

  /// No description provided for @calendarDayMon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get calendarDayMon;

  /// No description provided for @calendarDayTue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get calendarDayTue;

  /// No description provided for @calendarDayWed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get calendarDayWed;

  /// No description provided for @calendarDayThu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get calendarDayThu;

  /// No description provided for @calendarDayFri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get calendarDayFri;

  /// No description provided for @calendarDaySat.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get calendarDaySat;

  /// No description provided for @calendarToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get calendarToday;

  /// No description provided for @calendarYearMonth.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월'**
  String calendarYearMonth(int year, int month);

  /// No description provided for @calendarCategoryBreakdown.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 상세내역'**
  String get calendarCategoryBreakdown;

  /// No description provided for @calendarNoRecords.
  ///
  /// In ko, this message translates to:
  /// **'기록된 내역이 없습니다'**
  String get calendarNoRecords;

  /// No description provided for @calendarTransactionCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String calendarTransactionCount(int count);

  /// No description provided for @calendarNewTransaction.
  ///
  /// In ko, this message translates to:
  /// **'새 거래'**
  String get calendarNewTransaction;

  /// No description provided for @calendarTransactionDelete.
  ///
  /// In ko, this message translates to:
  /// **'거래 삭제'**
  String get calendarTransactionDelete;

  /// No description provided for @calendarTransactionDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 삭제하시겠습니까?'**
  String get calendarTransactionDeleteConfirm;

  /// No description provided for @calendarViewDaily.
  ///
  /// In ko, this message translates to:
  /// **'일별'**
  String get calendarViewDaily;

  /// No description provided for @calendarViewWeekly.
  ///
  /// In ko, this message translates to:
  /// **'주별'**
  String get calendarViewWeekly;

  /// No description provided for @calendarViewMonthly.
  ///
  /// In ko, this message translates to:
  /// **'월별'**
  String get calendarViewMonthly;

  /// No description provided for @calendarDailyDate.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월 {day}일'**
  String calendarDailyDate(int year, int month, int day);

  /// No description provided for @calendarWeeklyRange.
  ///
  /// In ko, this message translates to:
  /// **'{startMonth}월 {startDay}일 ~ {endMonth}월 {endDay}일'**
  String calendarWeeklyRange(
    int startMonth,
    int startDay,
    int endMonth,
    int endDay,
  );

  /// No description provided for @settingsWeekStartDay.
  ///
  /// In ko, this message translates to:
  /// **'주 시작일'**
  String get settingsWeekStartDay;

  /// No description provided for @settingsWeekStartDayDescription.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 주별 보기의 시작 요일'**
  String get settingsWeekStartDayDescription;

  /// No description provided for @settingsWeekStartSunday.
  ///
  /// In ko, this message translates to:
  /// **'일요일'**
  String get settingsWeekStartSunday;

  /// No description provided for @settingsWeekStartMonday.
  ///
  /// In ko, this message translates to:
  /// **'월요일'**
  String get settingsWeekStartMonday;

  /// No description provided for @assetNoData.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get assetNoData;

  /// No description provided for @assetOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get assetOther;

  /// No description provided for @assetNoAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산이 없습니다'**
  String get assetNoAsset;

  /// No description provided for @assetNoAssetData.
  ///
  /// In ko, this message translates to:
  /// **'자산 데이터가 없습니다'**
  String get assetNoAssetData;

  /// No description provided for @assetGoalNew.
  ///
  /// In ko, this message translates to:
  /// **'새 목표 설정'**
  String get assetGoalNew;

  /// No description provided for @assetGoalEdit.
  ///
  /// In ko, this message translates to:
  /// **'목표 수정'**
  String get assetGoalEdit;

  /// No description provided for @assetGoalAmount.
  ///
  /// In ko, this message translates to:
  /// **'목표 금액'**
  String get assetGoalAmount;

  /// No description provided for @assetGoalAmountRequired.
  ///
  /// In ko, this message translates to:
  /// **'목표 금액을 입력하세요'**
  String get assetGoalAmountRequired;

  /// No description provided for @assetGoalAmountInvalid.
  ///
  /// In ko, this message translates to:
  /// **'올바른 금액을 입력하세요'**
  String get assetGoalAmountInvalid;

  /// No description provided for @assetGoalDateOptional.
  ///
  /// In ko, this message translates to:
  /// **'목표 날짜 (선택)'**
  String get assetGoalDateOptional;

  /// No description provided for @assetGoalDateHint.
  ///
  /// In ko, this message translates to:
  /// **'목표 달성 날짜를 선택하세요'**
  String get assetGoalDateHint;

  /// No description provided for @assetGoalCreate.
  ///
  /// In ko, this message translates to:
  /// **'목표 생성'**
  String get assetGoalCreate;

  /// No description provided for @assetGoalCreated.
  ///
  /// In ko, this message translates to:
  /// **'목표가 생성되었습니다'**
  String get assetGoalCreated;

  /// No description provided for @assetGoalUpdated.
  ///
  /// In ko, this message translates to:
  /// **'목표가 수정되었습니다'**
  String get assetGoalUpdated;

  /// No description provided for @assetLedgerRequired.
  ///
  /// In ko, this message translates to:
  /// **'가계부를 선택하세요'**
  String get assetLedgerRequired;

  /// No description provided for @assetGoalAchievementRate.
  ///
  /// In ko, this message translates to:
  /// **'달성률'**
  String get assetGoalAchievementRate;

  /// No description provided for @assetGoalCurrentAmount.
  ///
  /// In ko, this message translates to:
  /// **'현재'**
  String get assetGoalCurrentAmount;

  /// No description provided for @assetGoalTargetAmount.
  ///
  /// In ko, this message translates to:
  /// **'목표'**
  String get assetGoalTargetAmount;

  /// No description provided for @assetGoalDaysPassed.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 경과'**
  String assetGoalDaysPassed(int days);

  /// No description provided for @assetGoalDaysRemaining.
  ///
  /// In ko, this message translates to:
  /// **'D-{days}'**
  String assetGoalDaysRemaining(int days);

  /// No description provided for @assetGoalCompleted.
  ///
  /// In ko, this message translates to:
  /// **'달성 완료'**
  String get assetGoalCompleted;

  /// No description provided for @assetGoalNone.
  ///
  /// In ko, this message translates to:
  /// **'설정된 목표가 없습니다'**
  String get assetGoalNone;

  /// No description provided for @assetGoalDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'목표 삭제'**
  String get assetGoalDeleteTitle;

  /// No description provided for @assetGoalDeleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'{title} 목표를 삭제하시겠습니까?'**
  String assetGoalDeleteMessage(String title);

  /// No description provided for @assetMonth.
  ///
  /// In ko, this message translates to:
  /// **'{month}월'**
  String assetMonth(int month);

  /// No description provided for @fixedExpenseCategoryName.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 이름'**
  String get fixedExpenseCategoryName;

  /// No description provided for @fixedExpenseCategoryNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 이름을 입력해주세요'**
  String get fixedExpenseCategoryNameRequired;

  /// No description provided for @fixedExpenseCategoryAdded.
  ///
  /// In ko, this message translates to:
  /// **'고정비 카테고리가 추가되었습니다'**
  String get fixedExpenseCategoryAdded;

  /// No description provided for @fixedExpenseCategoryDeleted.
  ///
  /// In ko, this message translates to:
  /// **'고정비 카테고리가 삭제되었습니다'**
  String get fixedExpenseCategoryDeleted;

  /// No description provided for @fixedExpenseCategoryNone.
  ///
  /// In ko, this message translates to:
  /// **'선택 안함'**
  String get fixedExpenseCategoryNone;

  /// No description provided for @paymentMethodOptional.
  ///
  /// In ko, this message translates to:
  /// **'결제수단 (선택)'**
  String get paymentMethodOptional;

  /// No description provided for @statisticsPeriodMonthly.
  ///
  /// In ko, this message translates to:
  /// **'월별'**
  String get statisticsPeriodMonthly;

  /// No description provided for @statisticsPeriodYearly.
  ///
  /// In ko, this message translates to:
  /// **'연별'**
  String get statisticsPeriodYearly;

  /// No description provided for @statisticsTypeIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get statisticsTypeIncome;

  /// No description provided for @statisticsTypeExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get statisticsTypeExpense;

  /// No description provided for @statisticsTypeAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get statisticsTypeAsset;

  /// No description provided for @statisticsExpenseAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get statisticsExpenseAll;

  /// No description provided for @statisticsExpenseFixed.
  ///
  /// In ko, this message translates to:
  /// **'고정비'**
  String get statisticsExpenseFixed;

  /// No description provided for @statisticsExpenseVariable.
  ///
  /// In ko, this message translates to:
  /// **'변동비'**
  String get statisticsExpenseVariable;

  /// No description provided for @statisticsExpenseAllDesc.
  ///
  /// In ko, this message translates to:
  /// **'모든 지출'**
  String get statisticsExpenseAllDesc;

  /// No description provided for @statisticsExpenseFixedDesc.
  ///
  /// In ko, this message translates to:
  /// **'월세, 보험료 등 정기 지출'**
  String get statisticsExpenseFixedDesc;

  /// No description provided for @statisticsExpenseVariableDesc.
  ///
  /// In ko, this message translates to:
  /// **'고정비 제외 지출'**
  String get statisticsExpenseVariableDesc;

  /// No description provided for @statisticsDateSelect.
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get statisticsDateSelect;

  /// No description provided for @statisticsToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get statisticsToday;

  /// No description provided for @statisticsYearLabel.
  ///
  /// In ko, this message translates to:
  /// **'{year}년'**
  String statisticsYearLabel(int year);

  /// No description provided for @statisticsMonthLabel.
  ///
  /// In ko, this message translates to:
  /// **'{month}월'**
  String statisticsMonthLabel(int month);

  /// No description provided for @statisticsYearMonthFormat.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월'**
  String statisticsYearMonthFormat(int year, int month);

  /// No description provided for @categoryUncategorized.
  ///
  /// In ko, this message translates to:
  /// **'미지정'**
  String get categoryUncategorized;

  /// No description provided for @categoryFixedExpense.
  ///
  /// In ko, this message translates to:
  /// **'고정비'**
  String get categoryFixedExpense;

  /// No description provided for @categoryUnknown.
  ///
  /// In ko, this message translates to:
  /// **'미분류'**
  String get categoryUnknown;

  /// No description provided for @defaultCategoryFood.
  ///
  /// In ko, this message translates to:
  /// **'식비'**
  String get defaultCategoryFood;

  /// No description provided for @defaultCategoryTransport.
  ///
  /// In ko, this message translates to:
  /// **'교통'**
  String get defaultCategoryTransport;

  /// No description provided for @defaultCategoryShopping.
  ///
  /// In ko, this message translates to:
  /// **'쇼핑'**
  String get defaultCategoryShopping;

  /// No description provided for @defaultCategoryLiving.
  ///
  /// In ko, this message translates to:
  /// **'생활'**
  String get defaultCategoryLiving;

  /// No description provided for @defaultCategoryTelecom.
  ///
  /// In ko, this message translates to:
  /// **'통신'**
  String get defaultCategoryTelecom;

  /// No description provided for @defaultCategoryMedical.
  ///
  /// In ko, this message translates to:
  /// **'의료'**
  String get defaultCategoryMedical;

  /// No description provided for @defaultCategoryCulture.
  ///
  /// In ko, this message translates to:
  /// **'문화'**
  String get defaultCategoryCulture;

  /// No description provided for @defaultCategoryEducation.
  ///
  /// In ko, this message translates to:
  /// **'교육'**
  String get defaultCategoryEducation;

  /// No description provided for @defaultCategoryOtherExpense.
  ///
  /// In ko, this message translates to:
  /// **'기타 지출'**
  String get defaultCategoryOtherExpense;

  /// No description provided for @defaultCategorySalary.
  ///
  /// In ko, this message translates to:
  /// **'급여'**
  String get defaultCategorySalary;

  /// No description provided for @defaultCategorySideJob.
  ///
  /// In ko, this message translates to:
  /// **'부업'**
  String get defaultCategorySideJob;

  /// No description provided for @defaultCategoryAllowance.
  ///
  /// In ko, this message translates to:
  /// **'용돈'**
  String get defaultCategoryAllowance;

  /// No description provided for @defaultCategoryInterest.
  ///
  /// In ko, this message translates to:
  /// **'이자'**
  String get defaultCategoryInterest;

  /// No description provided for @defaultCategoryOtherIncome.
  ///
  /// In ko, this message translates to:
  /// **'기타 수입'**
  String get defaultCategoryOtherIncome;

  /// No description provided for @defaultCategoryFixedDeposit.
  ///
  /// In ko, this message translates to:
  /// **'정기예금'**
  String get defaultCategoryFixedDeposit;

  /// No description provided for @defaultCategorySavings.
  ///
  /// In ko, this message translates to:
  /// **'적금'**
  String get defaultCategorySavings;

  /// No description provided for @defaultCategoryStock.
  ///
  /// In ko, this message translates to:
  /// **'주식'**
  String get defaultCategoryStock;

  /// No description provided for @defaultCategoryFund.
  ///
  /// In ko, this message translates to:
  /// **'펀드'**
  String get defaultCategoryFund;

  /// No description provided for @defaultCategoryRealEstate.
  ///
  /// In ko, this message translates to:
  /// **'부동산'**
  String get defaultCategoryRealEstate;

  /// No description provided for @defaultCategoryCrypto.
  ///
  /// In ko, this message translates to:
  /// **'암호화폐'**
  String get defaultCategoryCrypto;

  /// No description provided for @defaultCategoryOtherAsset.
  ///
  /// In ko, this message translates to:
  /// **'기타 자산'**
  String get defaultCategoryOtherAsset;

  /// No description provided for @autoSaveSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'자동 저장 설정'**
  String get autoSaveSettingsTitle;

  /// No description provided for @autoSaveSettingsAutoProcessMode.
  ///
  /// In ko, this message translates to:
  /// **'자동 처리 모드'**
  String get autoSaveSettingsAutoProcessMode;

  /// No description provided for @autoSaveSettingsSuggestModeTitle.
  ///
  /// In ko, this message translates to:
  /// **'제안 모드'**
  String get autoSaveSettingsSuggestModeTitle;

  /// No description provided for @autoSaveSettingsSuggestModeDesc.
  ///
  /// In ko, this message translates to:
  /// **'거래를 감지하면 확인 후 저장할 수 있습니다'**
  String get autoSaveSettingsSuggestModeDesc;

  /// No description provided for @autoSaveSettingsAutoModeTitle.
  ///
  /// In ko, this message translates to:
  /// **'자동 모드'**
  String get autoSaveSettingsAutoModeTitle;

  /// No description provided for @autoSaveSettingsAutoModeDesc.
  ///
  /// In ko, this message translates to:
  /// **'거래를 감지하면 바로 저장됩니다'**
  String get autoSaveSettingsAutoModeDesc;

  /// No description provided for @autoSaveSettingsRequiredPermissions.
  ///
  /// In ko, this message translates to:
  /// **'필요한 권한'**
  String get autoSaveSettingsRequiredPermissions;

  /// No description provided for @autoSaveSettingsPermissionDesc.
  ///
  /// In ko, this message translates to:
  /// **'SMS 읽기 권한 또는 알림 접근 권한이 필요합니다.\n설정 저장 시 권한 요청 화면이 표시됩니다.'**
  String get autoSaveSettingsPermissionDesc;

  /// No description provided for @autoSaveSettingsPermissionButton.
  ///
  /// In ko, this message translates to:
  /// **'권한 설정'**
  String get autoSaveSettingsPermissionButton;

  /// No description provided for @autoSaveSettingsIosNotSupported.
  ///
  /// In ko, this message translates to:
  /// **'iOS에서는 자동 저장 기능을 사용할 수 없습니다.\nAndroid 기기에서만 SMS/알림 기반 자동 저장이 가능합니다.'**
  String get autoSaveSettingsIosNotSupported;

  /// No description provided for @autoSaveSettingsSaved.
  ///
  /// In ko, this message translates to:
  /// **'자동 처리 설정이 저장되었습니다'**
  String get autoSaveSettingsSaved;

  /// No description provided for @autoSaveSettingsSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {error}'**
  String autoSaveSettingsSaveFailed(String error);

  /// No description provided for @autoSaveSettingsPermissionRequired.
  ///
  /// In ko, this message translates to:
  /// **'필요한 권한이 없습니다. 권한을 허용해주세요.'**
  String get autoSaveSettingsPermissionRequired;

  /// No description provided for @autoSaveSettingsModeManual.
  ///
  /// In ko, this message translates to:
  /// **'수동 입력'**
  String get autoSaveSettingsModeManual;

  /// No description provided for @autoSaveSettingsModeSuggest.
  ///
  /// In ko, this message translates to:
  /// **'제안 모드'**
  String get autoSaveSettingsModeSuggest;

  /// No description provided for @autoSaveSettingsModeAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동 저장'**
  String get autoSaveSettingsModeAuto;

  /// No description provided for @autoSaveSettingsSourceType.
  ///
  /// In ko, this message translates to:
  /// **'수신 방식'**
  String get autoSaveSettingsSourceType;

  /// No description provided for @autoSaveSettingsSourceSms.
  ///
  /// In ko, this message translates to:
  /// **'SMS'**
  String get autoSaveSettingsSourceSms;

  /// No description provided for @autoSaveSettingsSourcePush.
  ///
  /// In ko, this message translates to:
  /// **'Push 알림'**
  String get autoSaveSettingsSourcePush;

  /// No description provided for @autoSaveSettingsSourceSmsDesc.
  ///
  /// In ko, this message translates to:
  /// **'결제 문자 메시지를 감지합니다. 대부분의 카드사에서 지원됩니다.'**
  String get autoSaveSettingsSourceSmsDesc;

  /// No description provided for @autoSaveSettingsSourcePushDesc.
  ///
  /// In ko, this message translates to:
  /// **'카드사 앱의 푸시 알림을 감지합니다. KB국민, 신한, 삼성카드 등이 지원됩니다.'**
  String get autoSaveSettingsSourcePushDesc;

  /// No description provided for @paymentMethodPermissionWarningTitle.
  ///
  /// In ko, this message translates to:
  /// **'공유 전환 확인'**
  String get paymentMethodPermissionWarningTitle;

  /// No description provided for @paymentMethodPermissionWarningMessage.
  ///
  /// In ko, this message translates to:
  /// **'개인 결제수단을 공유 결제수단으로 변경하면 다른 멤버도 이 결제수단을 수정할 수 있습니다. 계속하시겠습니까?'**
  String get paymentMethodPermissionWarningMessage;

  /// No description provided for @errorOccurred.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get errorOccurred;

  /// No description provided for @pullToRefresh.
  ///
  /// In ko, this message translates to:
  /// **'아래로 당겨서 새로고침'**
  String get pullToRefresh;

  /// No description provided for @duplicateTransaction.
  ///
  /// In ko, this message translates to:
  /// **'중복 거래'**
  String get duplicateTransaction;

  /// No description provided for @duplicateTransactionWarning.
  ///
  /// In ko, this message translates to:
  /// **'이 거래는 중복으로 감지되었습니다'**
  String get duplicateTransactionWarning;

  /// No description provided for @originalTransactionTime.
  ///
  /// In ko, this message translates to:
  /// **'원본 거래 시간'**
  String get originalTransactionTime;

  /// No description provided for @viewOriginal.
  ///
  /// In ko, this message translates to:
  /// **'원본 보기'**
  String get viewOriginal;

  /// No description provided for @confirmDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'상세'**
  String get confirmDuplicate;

  /// No description provided for @ignoreDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get ignoreDuplicate;

  /// No description provided for @duplicateInfo.
  ///
  /// In ko, this message translates to:
  /// **'중복 정보'**
  String get duplicateInfo;

  /// No description provided for @originalTransactionNotFound.
  ///
  /// In ko, this message translates to:
  /// **'원본 거래를 찾을 수 없습니다.'**
  String get originalTransactionNotFound;

  /// No description provided for @duplicateMessageReceivedTwice.
  ///
  /// In ko, this message translates to:
  /// **'동일한 SMS/알림이 2번 수신되었을 수 있습니다.'**
  String get duplicateMessageReceivedTwice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
