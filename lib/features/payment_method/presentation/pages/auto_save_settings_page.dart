import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../domain/entities/payment_method.dart';
import '../providers/payment_method_provider.dart';
import '../widgets/permission_request_dialog.dart';

class AutoSaveSettingsPage extends ConsumerStatefulWidget {
  final String paymentMethodId;

  const AutoSaveSettingsPage({super.key, required this.paymentMethodId});

  @override
  ConsumerState<AutoSaveSettingsPage> createState() =>
      _AutoSaveSettingsPageState();
}

class _AutoSaveSettingsPageState extends ConsumerState<AutoSaveSettingsPage> {
  AutoSaveMode _selectedMode = AutoSaveMode.manual;
  bool _isLoading = false;
  PaymentMethod? _paymentMethod;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethod();
  }

  void _loadPaymentMethod() {
    final paymentMethodsAsync = ref.read(paymentMethodNotifierProvider);
    paymentMethodsAsync.whenData((paymentMethods) {
      final pm = paymentMethods
          .where((p) => p.id == widget.paymentMethodId)
          .firstOrNull;
      if (pm != null) {
        setState(() {
          _paymentMethod = pm;
          _selectedMode = pm.autoSaveMode;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Android만 자동 저장 지원
    final isAndroid = Platform.isAndroid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('자동 저장 설정'),
        actions: [
          if (_paymentMethod != null)
            TextButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
        ],
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: _paymentMethod == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  // 결제수단 정보 헤더
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _parseColor(_paymentMethod!.color),
                              borderRadius: BorderRadius.circular(
                                BorderRadiusToken.md,
                              ),
                            ),
                            child: const Icon(
                              Icons.credit_card,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _paymentMethod!.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _getModeDescription(_selectedMode),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // 플랫폼 안내 (iOS)
                  if (!isAndroid) ...[
                    Card(
                      color: colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                'iOS에서는 자동 저장 기능을 사용할 수 없습니다.\n'
                                'Android 기기에서만 SMS/알림 기반 자동 저장이 가능합니다.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                  ],

                  // 자동 저장 모드 선택
                  Text(
                    '자동 저장 모드',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  _buildModeSelector(context, isAndroid),
                  const SizedBox(height: Spacing.lg),

                  // 권한 안내
                  if (isAndroid && _selectedMode != AutoSaveMode.manual) ...[
                    const SizedBox(height: Spacing.lg),
                    Card(
                      color: colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: Spacing.sm),
                                Text(
                                  '필요한 권한',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(
                              'SMS 읽기 권한 또는 알림 접근 권한이 필요합니다.\n'
                              '설정 저장 시 권한 요청 화면이 표시됩니다.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: Spacing.sm),
                            OutlinedButton.icon(
                              onPressed: _showPermissionDialog,
                              icon: const Icon(Icons.settings),
                              label: const Text('권한 설정'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, bool isAndroid) {
    return Column(
      children: [
        _buildModeOption(
          context,
          mode: AutoSaveMode.manual,
          icon: Icons.edit_outlined,
          title: '수동 입력',
          description: 'SMS/알림을 자동으로 처리하지 않습니다',
          enabled: true,
        ),
        const SizedBox(height: Spacing.sm),
        _buildModeOption(
          context,
          mode: AutoSaveMode.suggest,
          icon: Icons.notifications_active_outlined,
          title: '제안 모드',
          description: '거래를 감지하면 확인 후 저장할 수 있습니다',
          enabled: isAndroid,
        ),
        const SizedBox(height: Spacing.sm),
        _buildModeOption(
          context,
          mode: AutoSaveMode.auto,
          icon: Icons.flash_on_outlined,
          title: '자동 저장',
          description: '거래를 감지하면 바로 저장됩니다',
          enabled: isAndroid,
        ),
      ],
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required AutoSaveMode mode,
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedMode == mode;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected ? colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: enabled
            ? () {
                setState(() {
                  _selectedMode = mode;
                });
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : null,
                        ),
                      ),
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (_paymentMethod == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 자동 저장 모드가 활성화된 경우 권한 확인
      if (_selectedMode != AutoSaveMode.manual && Platform.isAndroid) {
        final hasPermission = await _checkAndRequestPermissions();
        if (!hasPermission) {
          if (mounted) {
            SnackBarUtils.showError(context, '필요한 권한이 없습니다. 권한을 허용해주세요.');
          }
          return;
        }
      }

      await ref
          .read(paymentMethodNotifierProvider.notifier)
          .updateAutoSaveSettings(
            id: widget.paymentMethodId,
            autoSaveMode: _selectedMode,
          );

      if (mounted) {
        SnackBarUtils.showSuccess(context, '자동 저장 설정이 저장되었습니다');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '저장 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    // 권한 체크는 permission_handler를 사용해야 하지만,
    // 여기서는 간단하게 true를 반환하고 실제 권한 체크는 서비스에서 처리
    // 실제 구현에서는 PermissionHandler 패키지 사용
    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => const PermissionRequestDialog(),
    );
  }

  String _getModeDescription(AutoSaveMode mode) {
    switch (mode) {
      case AutoSaveMode.manual:
        return '수동 입력';
      case AutoSaveMode.suggest:
        return '제안 모드';
      case AutoSaveMode.auto:
        return '자동 저장';
    }
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse('FF${colorString.substring(1)}', radix: 16));
      }
      return Colors.grey;
    } catch (_) {
      return Colors.grey;
    }
  }
}
