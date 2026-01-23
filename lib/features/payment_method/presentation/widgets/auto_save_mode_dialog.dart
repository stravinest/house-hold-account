import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../domain/entities/payment_method.dart';
import '../../data/services/auto_save_service.dart';
import '../providers/payment_method_provider.dart';
import 'permission_request_dialog.dart';

class AutoSaveModeDialog extends ConsumerStatefulWidget {
  final PaymentMethod paymentMethod;
  final VoidCallback? onSave;

  const AutoSaveModeDialog({
    super.key,
    required this.paymentMethod,
    this.onSave,
  });

  @override
  ConsumerState<AutoSaveModeDialog> createState() =>
      _AutoSaveModeDialogState();
}

class _AutoSaveModeDialogState extends ConsumerState<AutoSaveModeDialog> {
  AutoSaveMode? _selectedMode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.paymentMethod.autoSaveMode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isAndroid = Platform.isAndroid;
    final isChanged = _selectedMode != widget.paymentMethod.autoSaveMode;

    return AlertDialog(
      title: Text(l10n.autoSaveSettingsTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaymentMethodInfo(colorScheme),
            const SizedBox(height: Spacing.lg),
            _buildModeSelector(context, l10n, isAndroid),
            if (!isAndroid) ...[
              const SizedBox(height: Spacing.md),
              _buildIOSUnsupportedWarning(context, l10n),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton(
          onPressed: _isLoading || !isChanged ? null : _saveSettings,
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                )
              : Text(l10n.commonSave),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodInfo(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorUtils.parseHexColor(widget.paymentMethod.color),
              borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
            ),
            child: Center(
              child: Text(
                widget.paymentMethod.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.paymentMethod.name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getModeDescription(
                    AppLocalizations.of(context),
                    widget.paymentMethod.autoSaveMode,
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(
    BuildContext context,
    AppLocalizations l10n,
    bool isAndroid,
  ) {
    return Column(
      children: [
        _buildModeOption(
          context,
          l10n,
          mode: AutoSaveMode.suggest,
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
        onTap: enabled && !_isLoading
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

  Widget _buildIOSUnsupportedWarning(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: colorScheme.error,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              l10n.autoSaveSettingsIOSUnsupported,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context);
    final selectedMode = _selectedMode;
    if (selectedMode == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (selectedMode != AutoSaveMode.manual && Platform.isAndroid) {
        final hasPermission = await _checkAndRequestPermissions();
        if (!hasPermission) {
          if (mounted) {
            SnackBarUtils.showError(
              context,
              l10n.autoSaveSettingsPermissionRequired,
            );
          }
          return;
        }
      }

      await ref
          .read(paymentMethodNotifierProvider.notifier)
          .updateAutoSaveSettings(
            id: widget.paymentMethod.id,
            autoSaveMode: selectedMode,
          );

      try {
        await AutoSaveService.instance.refreshPaymentMethods();
      } catch (e) {
        debugPrint('Failed to refresh AutoSaveService: $e');
      }

      if (mounted) {
        SnackBarUtils.showSuccess(context, l10n.autoSaveSettingsSaved);
        widget.onSave?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
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
    return true;
  }

  String _getModeDescription(AppLocalizations l10n, AutoSaveMode mode) {
    return switch (mode) {
      AutoSaveMode.manual => l10n.autoSaveSettingsModeManual,
      AutoSaveMode.suggest => l10n.autoSaveSettingsModeSuggest,
      AutoSaveMode.auto => l10n.autoSaveSettingsModeAuto,
    };
  }
}
