import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtils.showError(
          context,
          l10n.authForgotPasswordSendFailed(e.toString()),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Spacing.lg),
          child: _emailSent
              ? _buildSuccessView(l10n, colorScheme)
              : _buildFormView(l10n, colorScheme),
        ),
      ),
    );
  }

  Widget _buildFormView(AppLocalizations l10n, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: Spacing.xl),

          // 아이콘
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_outlined,
                size: IconSize.xl,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          SizedBox(height: Spacing.lg),

          // 타이틀
          Text(
            l10n.authForgotPasswordTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Spacing.sm),

          // 부제목
          Text(
            l10n.authForgotPasswordSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: Spacing.xl),

          // 이메일 입력
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
            decoration: InputDecoration(
              labelText: l10n.authEmail,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.validationEmailRequired;
              }
              if (!value.contains('@')) {
                return l10n.validationEmailInvalid;
              }
              return null;
            },
          ),

          SizedBox(height: Spacing.lg),

          // 재설정 링크 보내기 버튼
          ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.authForgotPasswordSend),
          ),

          SizedBox(height: Spacing.lg),

          // 로그인으로 돌아가기
          Center(
            child: TextButton(
              onPressed: () => context.go(Routes.login),
              child: Text(l10n.authForgotPasswordBackToLogin),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(AppLocalizations l10n, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: Spacing.xxl),

        // 성공 아이콘
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: IconSize.xxl,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        SizedBox(height: Spacing.lg),

        // 성공 메시지
        Text(
          l10n.authForgotPasswordSent,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: Spacing.sm),

        // 이메일 표시
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(BorderRadiusToken.md),
          ),
          child: Text(
            _emailController.text.trim(),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: Spacing.md),

        // 안내 메시지
        Text(
          l10n.authForgotPasswordSentSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: Spacing.xxl),

        // 로그인으로 돌아가기 버튼
        ElevatedButton(
          onPressed: () => context.go(Routes.login),
          child: Text(l10n.authForgotPasswordBackToLogin),
        ),
      ],
    );
  }
}
