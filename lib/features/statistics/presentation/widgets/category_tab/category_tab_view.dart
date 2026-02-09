import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../providers/statistics_provider.dart';
import '../common/statistics_filter_section.dart';
import 'category_distribution_card.dart';
import 'category_summary_card.dart';
import 'shared_category_tab_view.dart';

class CategoryTabView extends ConsumerStatefulWidget {
  const CategoryTabView({super.key});

  @override
  ConsumerState<CategoryTabView> createState() => _CategoryTabViewState();
}

class _CategoryTabViewState extends ConsumerState<CategoryTabView> {
  Future<void> _refreshCategoryData() async {
    ref.invalidate(categoryExpenseStatisticsProvider);
    ref.invalidate(categoryIncomeStatisticsProvider);
    ref.invalidate(categoryAssetStatisticsProvider);
    ref.invalidate(monthComparisonProvider);

    try {
      await Future.wait([
        ref.read(categoryExpenseStatisticsProvider.future),
        ref.read(categoryIncomeStatisticsProvider.future),
        ref.read(categoryAssetStatisticsProvider.future),
        ref.read(monthComparisonProvider.future),
      ]);
    } on AuthException catch (e) {
      debugPrint('카테고리 통계 새로고침 오류 (인증): $e');
      if (mounted) {
        _handleAuthError(e);
      }
      rethrow;
    } on SocketException catch (e) {
      debugPrint('카테고리 통계 새로고침 오류 (네트워크): $e');
      if (mounted) {
        _showNetworkError();
      }
      rethrow;
    } catch (e) {
      debugPrint('카테고리 통계 새로고침 오류: $e');
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
    // 공유 가계부인 경우 SharedCategoryTabView 표시
    final isSharedLedger = ref.watch(isSharedLedgerProvider);
    if (isSharedLedger) {
      return const SharedCategoryTabView();
    }

    return RefreshIndicator(
      onRefresh: _refreshCategoryData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 타입 필터 (드롭다운 + 서브필터)
            const StatisticsFilterSection(),
            const SizedBox(height: 16),

            // 요약 카드 (전월 대비 포함)
            const CategorySummaryCard(),
            const SizedBox(height: 16),

            // 카테고리 분포 카드 - Pencil Nzqas 디자인 적용
            const CategoryDistributionCard(),
          ],
        ),
      ),
    );
  }
}
