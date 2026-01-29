import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../providers/statistics_provider.dart';
import '../common/expense_type_filter.dart';
import '../common/statistics_type_filter.dart';
import 'shared_category_distribution_card.dart';
import 'shared_category_summary_card.dart';

/// 공유 가계부용 카테고리 통계 탭 뷰
class SharedCategoryTabView extends ConsumerStatefulWidget {
  const SharedCategoryTabView({super.key});

  @override
  ConsumerState<SharedCategoryTabView> createState() =>
      _SharedCategoryTabViewState();
}

class _SharedCategoryTabViewState extends ConsumerState<SharedCategoryTabView> {
  Future<void> _refreshData() async {
    ref.invalidate(categoryStatisticsByUserProvider);
    ref.invalidate(categoryExpenseStatisticsProvider);
    ref.invalidate(categoryIncomeStatisticsProvider);
    ref.invalidate(categoryAssetStatisticsProvider);

    try {
      await ref.read(categoryStatisticsByUserProvider.future);
    } on AuthException catch (e) {
      debugPrint('공유 통계 새로고침 오류 (인증): $e');
      if (mounted) {
        _handleAuthError(e);
      }
      rethrow;
    } on SocketException catch (e) {
      debugPrint('공유 통계 새로고침 오류 (네트워크): $e');
      if (mounted) {
        _showNetworkError();
      }
      rethrow;
    } catch (e) {
      debugPrint('공유 통계 새로고침 오류: $e');
      if (mounted && _isNetworkError(e)) {
        _showNetworkError();
      }
      rethrow;
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network') ||
        errorString.contains('authretryablefetchexception');
  }

  void _handleAuthError(AuthException error) {
    final l10n = AppLocalizations.of(context);
    final errorMessage = error.message.toLowerCase();

    if (errorMessage.contains('expired') ||
        errorMessage.contains('refresh') ||
        errorMessage.contains('invalid') ||
        error.statusCode == '401') {
      SnackBarUtils.showError(
        context,
        l10n.errorSessionExpired,
        duration: const Duration(seconds: 4),
      );

      Future.delayed(const Duration(seconds: 1), () async {
        await ref.read(authNotifierProvider.notifier).signOut();
      });
    }
  }

  void _showNetworkError() {
    final l10n = AppLocalizations.of(context);
    SnackBarUtils.showError(
      context,
      l10n.errorNetwork,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = ref.watch(selectedStatisticsTypeProvider);
    final expenseTypeFilter = ref.watch(selectedExpenseTypeFilterProvider);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 타입 필터 (수입/지출/자산)
            const Center(child: StatisticsTypeFilter()),

            // 고정비/변동비 필터 (지출 선택 시에만 표시)
            if (selectedType == 'expense') ...[
              const SizedBox(height: 12),
              Center(
                child: ExpenseTypeFilterWidget(
                  selectedFilter: expenseTypeFilter,
                  onChanged: (filter) {
                    ref.read(selectedExpenseTypeFilterProvider.notifier).state =
                        filter;
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 요약 카드 - Pencil Oleyd 디자인 (사용자별 내역 포함)
            const SharedCategorySummaryCard(),
            const SizedBox(height: 16),

            // 카테고리 분포 카드 - Pencil Nzqas + memberTabs 디자인 적용
            const SharedCategoryDistributionCard(),
          ],
        ),
      ),
    );
  }
}
