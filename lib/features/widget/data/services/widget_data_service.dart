import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

/// 홈 위젯 데이터 관리 서비스
///
/// Android/iOS 홈 화면 위젯과 데이터를 공유하고 업데이트합니다.
class WidgetDataService {
  // Android Widget Provider 클래스명
  static const String _androidQuickAddWidget = 'QuickAddWidget';
  static const String _androidMonthlySummaryWidget = 'MonthlySummaryWidget';

  // iOS App Group ID (Info.plist와 동일해야 함)
  static const String _iosAppGroupId = 'group.com.household.shared.sharedHouseholdAccount';

  // 위젯 데이터 키
  static const String keyMonthlyExpense = 'monthly_expense';
  static const String keyMonthlyIncome = 'monthly_income';
  static const String keyMonthlyBalance = 'monthly_balance';
  static const String keyLastUpdated = 'last_updated';
  static const String keyLedgerName = 'ledger_name';

  /// 서비스 초기화
  /// 앱 시작 시 호출하여 App Group 설정
  static Future<void> initialize() async {
    try {
      // iOS App Group 설정
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(_iosAppGroupId);
      }
      debugPrint('[WidgetDataService] 초기화 완료');
    } catch (e) {
      debugPrint('[WidgetDataService] 초기화 실패: $e');
    }
  }

  /// 위젯 데이터 업데이트
  ///
  /// [monthlyExpense] 이번 달 총 지출
  /// [monthlyIncome] 이번 달 총 수입
  /// [ledgerName] 현재 선택된 가계부 이름
  static Future<void> updateWidgetData({
    required int monthlyExpense,
    required int monthlyIncome,
    required String ledgerName,
  }) async {
    try {
      final balance = monthlyIncome - monthlyExpense;
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      // 데이터 저장
      await Future.wait([
        HomeWidget.saveWidgetData<int>(keyMonthlyExpense, monthlyExpense),
        HomeWidget.saveWidgetData<int>(keyMonthlyIncome, monthlyIncome),
        HomeWidget.saveWidgetData<int>(keyMonthlyBalance, balance),
        HomeWidget.saveWidgetData<String>(keyLastUpdated, dateFormat.format(now)),
        HomeWidget.saveWidgetData<String>(keyLedgerName, ledgerName),
      ]);

      debugPrint('[WidgetDataService] 데이터 저장 완료 - '
          '지출: $monthlyExpense, 수입: $monthlyIncome, 잔액: $balance');

      // 위젯 업데이트 트리거
      await refreshWidgets();
    } catch (e) {
      debugPrint('[WidgetDataService] 데이터 업데이트 실패: $e');
    }
  }

  /// 모든 위젯 새로고침
  static Future<void> refreshWidgets() async {
    try {
      if (Platform.isAndroid) {
        // Android 위젯 업데이트
        await HomeWidget.updateWidget(
          name: _androidQuickAddWidget,
          androidName: _androidQuickAddWidget,
        );
        await HomeWidget.updateWidget(
          name: _androidMonthlySummaryWidget,
          androidName: _androidMonthlySummaryWidget,
        );
      } else if (Platform.isIOS) {
        // iOS 위젯 업데이트 (WidgetKit 타임라인 리로드)
        await HomeWidget.updateWidget(iOSName: 'QuickAddWidget');
        await HomeWidget.updateWidget(iOSName: 'MonthlySummaryWidget');
      }
      debugPrint('[WidgetDataService] 위젯 새로고침 완료');
    } catch (e) {
      debugPrint('[WidgetDataService] 위젯 새로고침 실패: $e');
    }
  }

  /// 위젯 데이터 초기화 (로그아웃 시)
  static Future<void> clearWidgetData() async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<int>(keyMonthlyExpense, 0),
        HomeWidget.saveWidgetData<int>(keyMonthlyIncome, 0),
        HomeWidget.saveWidgetData<int>(keyMonthlyBalance, 0),
        HomeWidget.saveWidgetData<String>(keyLastUpdated, ''),
        HomeWidget.saveWidgetData<String>(keyLedgerName, ''),
      ]);

      await refreshWidgets();
      debugPrint('[WidgetDataService] 위젯 데이터 초기화 완료');
    } catch (e) {
      debugPrint('[WidgetDataService] 위젯 데이터 초기화 실패: $e');
    }
  }

  /// 딥링크 URI 핸들링 등록
  /// 위젯에서 앱으로 전환 시 호출되는 URI를 처리
  static Future<Uri?> getInitialLaunchUri() async {
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (e) {
      debugPrint('[WidgetDataService] 초기 딥링크 가져오기 실패: $e');
      return null;
    }
  }

  /// 딥링크 스트림 구독
  /// 앱 실행 중 위젯에서 탭 시 호출
  static Stream<Uri?> get widgetLaunchStream {
    return HomeWidget.widgetClicked;
  }
}
