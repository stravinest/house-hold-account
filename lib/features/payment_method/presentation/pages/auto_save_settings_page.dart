import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../domain/entities/payment_method.dart';
import '../../data/services/auto_save_service.dart';
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
  AutoSaveMode? _selectedMode;
  AutoCollectSource? _selectedSource;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Android only supports auto save
    final isAndroid = Platform.isAndroid;

    // Watch provider to detect state changes
    final paymentMethodsAsync = ref.watch(paymentMethodNotifierProvider);

    return paymentMethodsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.autoSaveSettingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.autoSaveSettingsTitle)),
        body: Center(child: Text(l10n.errorWithMessage(error.toString()))),
      ),
      data: (paymentMethods) {
        final paymentMethod = paymentMethods
            .where((p) => p.id == widget.paymentMethodId)
            .firstOrNull;

        if (paymentMethod == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.autoSaveSettingsTitle)),
            body: Center(child: Text(l10n.paymentMethodNotFound)),
          );
        }

        // Use user-changed mode if available, otherwise use server value
        final currentMode = _selectedMode ?? paymentMethod.autoSaveMode;
        final currentSource = _selectedSource ?? paymentMethod.autoCollectSource;

        return _buildContent(
          context,
          l10n,
          colorScheme,
          textTheme,
          isAndroid,
          paymentMethod,
          currentMode,
          currentSource,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isAndroid,
    PaymentMethod paymentMethod,
    AutoSaveMode currentMode,
    AutoCollectSource currentSource,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.autoSaveSettingsTitle),
        actions: [
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
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            // Payment method info header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ColorUtils.parseHexColor(paymentMethod.color),
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
                            paymentMethod.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getModeDescription(l10n, currentMode),
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

            // Platform notice (iOS)
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
                          l10n.autoSaveSettingsIosNotSupported,
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

            // 수신 방식 선택 (SMS / Push)
            if (isAndroid) ...[
              Text(
                l10n.autoSaveSettingsSourceType,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              _buildSourceSelector(context, l10n, colorScheme, currentSource),
              const SizedBox(height: Spacing.xs),
              Text(
                _getSourceDescription(l10n, currentSource),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.lg),
            ],

            // Auto process mode selection
            Text(
              l10n.autoSaveSettingsAutoProcessMode,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            _buildModeSelector(context, l10n, isAndroid, currentMode),
            const SizedBox(height: Spacing.lg),

            // Permission notice (auto-collect always requires permission)
            if (isAndroid) ...[
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
                                  l10n.autoSaveSettingsRequiredPermissions,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(
                              l10n.autoSaveSettingsPermissionDesc,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: Spacing.sm),
                            OutlinedButton.icon(
                              onPressed: _showPermissionDialog,
                              icon: const Icon(Icons.settings),
                              label: Text(l10n.autoSaveSettingsPermissionButton),
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

  /// SegmentedButton으로 SMS/Push 선택
  Widget _buildSourceSelector(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    AutoCollectSource currentSource,
  ) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<AutoCollectSource>(
        segments: [
          ButtonSegment<AutoCollectSource>(
            value: AutoCollectSource.sms,
            label: Text(l10n.autoSaveSettingsSourceSms),
            icon: const Icon(Icons.sms_outlined),
          ),
          ButtonSegment<AutoCollectSource>(
            value: AutoCollectSource.push,
            label: Text(l10n.autoSaveSettingsSourcePush),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
        selected: {currentSource},
        onSelectionChanged: (Set<AutoCollectSource> newSelection) {
          setState(() {
            _selectedSource = newSelection.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primaryContainer;
            }
            return null;
          }),
        ),
      ),
    );
  }

  String _getSourceDescription(AppLocalizations l10n, AutoCollectSource source) {
    switch (source) {
      case AutoCollectSource.sms:
        return l10n.autoSaveSettingsSourceSmsDesc;
      case AutoCollectSource.push:
        return l10n.autoSaveSettingsSourcePushDesc;
    }
  }

  Widget _buildModeSelector(BuildContext context, AppLocalizations l10n, bool isAndroid, AutoSaveMode currentMode) {
    return Column(
      children: [
        _buildModeOption(
          context,
          l10n,
          mode: AutoSaveMode.suggest,
          currentMode: currentMode,
          icon: Icons.notifications_active_outlined,
          title: l10n.autoSaveSettingsSuggestModeTitle,
          description: l10n.autoSaveSettingsSuggestModeDesc,
          enabled: isAndroid,
        ),
        const SizedBox(height: Spacing.sm),
        _buildModeOption(
          context,
          l10n,
          mode: AutoSaveMode.auto,
          currentMode: currentMode,
          icon: Icons.auto_awesome_outlined,
          title: l10n.autoSaveSettingsAutoModeTitle,
          description: l10n.autoSaveSettingsAutoModeDesc,
          enabled: isAndroid,
        ),
      ],
    );
  }

  Widget _buildModeOption(
    BuildContext context,
    AppLocalizations l10n, {
    required AutoSaveMode mode,
    required AutoSaveMode currentMode,
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = currentMode == mode;

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
    final l10n = AppLocalizations.of(context);
    final selectedMode = _selectedMode;
    final selectedSource = _selectedSource;

    // 변경사항이 없으면 리턴
    if (selectedMode == null && selectedSource == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 결제수단 정보 가져오기
      final paymentMethods = ref.read(paymentMethodNotifierProvider).valueOrNull ?? [];
      final currentPaymentMethod = paymentMethods
          .where((p) => p.id == widget.paymentMethodId)
          .firstOrNull;

      final modeToSave = selectedMode ?? currentPaymentMethod?.autoSaveMode ?? AutoSaveMode.manual;

      // Check permission if auto save mode is enabled
      if (modeToSave != AutoSaveMode.manual && Platform.isAndroid) {
        final hasPermission = await _checkAndRequestPermissions();
        if (!hasPermission) {
          if (mounted) {
            SnackBarUtils.showError(context, l10n.autoSaveSettingsPermissionRequired);
          }
          return;
        }
      }

      await ref
          .read(paymentMethodNotifierProvider.notifier)
          .updateAutoSaveSettings(
            id: widget.paymentMethodId,
            autoSaveMode: modeToSave,
            autoCollectSource: selectedSource,
          );

      // Immediately reflect changed settings to the service
      try {
        await AutoSaveService.instance.refreshPaymentMethods();
      } catch (e) {
        debugPrint('Failed to refresh AutoSaveService: $e');
      }

      if (mounted) {
        SnackBarUtils.showSuccess(context, l10n.autoSaveSettingsSaved);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, l10n.autoSaveSettingsSaveFailed(e.toString()));
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
    // Permission check should use permission_handler,
    // but for now return true and let actual permission check happen in the service
    // In actual implementation, use PermissionHandler package
    // TODO: Implement actual permission check with permission_handler
    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => const PermissionRequestDialog(),
    );
  }

  String _getModeDescription(AppLocalizations l10n, AutoSaveMode mode) {
    switch (mode) {
      case AutoSaveMode.manual:
        return l10n.autoSaveSettingsModeManual;
      case AutoSaveMode.suggest:
        return l10n.autoSaveSettingsModeSuggest;
      case AutoSaveMode.auto:
        return l10n.autoSaveSettingsModeAuto;
    }
  }
}
