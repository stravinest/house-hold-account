import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _otpController = TextEditingController();
  bool _isLoading = false;

  // 0: 이메일 입력, 1: OTP 입력, 2: 완료(ResetPasswordPage로 이동)
  int _step = 0;

  // 재전송 쿨다운 타이머
  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendCooldown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _step = 1;
          _isLoading = false;
        });
        _startResendCooldown();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        String errorMessage;
        if (e is AuthRetryableFetchException ||
            e.toString().contains('SocketException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Network is unreachable')) {
          errorMessage = l10n.errorNetwork;
        } else {
          errorMessage = l10n.authForgotPasswordSendFailed(e.toString());
        }
        SnackBarUtils.showError(context, errorMessage);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCooldown > 0) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtils.showSuccess(context, l10n.authOtpResent);
        _otpController.clear();
        setState(() => _isLoading = false);
        _startResendCooldown();
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

  static const int _otpLength = 8;

  Future<void> _handleVerifyOtp(String code) async {
    if (code.length != _otpLength) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyPasswordResetOtp(
        _emailController.text.trim(),
        code,
      );

      if (mounted) {
        // OTP 검증 성공 -> 세션이 생성됨 -> ResetPasswordPage로 이동
        context.go(Routes.resetPassword);
      }
    } on AuthException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        String errorMessage;
        if (e.message.contains('expired') || e.message.contains('Token')) {
          errorMessage = l10n.authOtpExpiredError;
        } else {
          errorMessage = l10n.authOtpInvalidError;
        }
        SnackBarUtils.showError(context, errorMessage);
        _otpController.clear();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        String errorMessage;
        if (e is AuthRetryableFetchException ||
            e.toString().contains('SocketException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Network is unreachable')) {
          errorMessage = l10n.errorNetwork;
        } else {
          errorMessage = l10n.authOtpInvalidError;
        }
        SnackBarUtils.showError(context, errorMessage);
        _otpController.clear();
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
          onPressed: () {
            if (_step == 1) {
              setState(() {
                _step = 0;
                _otpController.clear();
                _resendTimer?.cancel();
                _resendCooldown = 0;
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: _step == 0
              ? _buildEmailStep(l10n, colorScheme)
              : _buildOtpStep(l10n, colorScheme),
        ),
      ),
    );
  }

  Widget _buildEmailStep(AppLocalizations l10n, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.xl),

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
          const SizedBox(height: Spacing.lg),

          // 타이틀
          Text(
            l10n.authForgotPasswordTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sm),

          // 부제목
          Text(
            l10n.authForgotPasswordSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: Spacing.xl),

          // 이메일 입력
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSendOtp(),
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

          const SizedBox(height: Spacing.lg),

          // 인증 코드 보내기 버튼
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSendOtp,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.authForgotPasswordSend),
          ),

          const SizedBox(height: Spacing.lg),

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

  Widget _buildOtpStep(AppLocalizations l10n, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Spacing.xl),

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
              Icons.mark_email_read_outlined,
              size: IconSize.xl,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // 타이틀
        Text(
          l10n.authOtpInputTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.sm),

        // 부제목
        Text(
          l10n.authOtpInputSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.sm),

        // 이메일 표시
        Container(
          padding: const EdgeInsets.symmetric(
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

        const SizedBox(height: Spacing.xl),

        // OTP 8자리 입력
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: PinCodeTextField(
            appContext: context,
            length: _otpLength,
            controller: _otpController,
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            autoFocus: true,
            enabled: !_isLoading,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
              fieldHeight: 48,
              fieldWidth: 36,
              activeFillColor: colorScheme.surface,
              inactiveFillColor: colorScheme.surfaceContainerHighest,
              selectedFillColor: colorScheme.surface,
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.outline,
              selectedColor: colorScheme.primary,
            ),
            enableActiveFill: true,
            onCompleted: _handleVerifyOtp,
            onChanged: (_) {},
          ),
        ),

        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Center(
              child: Text(
                l10n.authOtpVerifying,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),

        const SizedBox(height: Spacing.sm),

        // 만료 안내
        Center(
          child: Text(
            l10n.authOtpExpiryNotice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        const SizedBox(height: Spacing.lg),

        // 재전송 버튼
        Center(
          child: TextButton(
            onPressed: _resendCooldown > 0 || _isLoading
                ? null
                : _handleResendOtp,
            child: Text(
              _resendCooldown > 0
                  ? l10n.authOtpResendCooldown(_resendCooldown)
                  : l10n.authOtpResend,
            ),
          ),
        ),

        const SizedBox(height: Spacing.md),

        // 로그인으로 돌아가기
        Center(
          child: TextButton(
            onPressed: () => context.go(Routes.login),
            child: Text(l10n.authForgotPasswordBackToLogin),
          ),
        ),
      ],
    );
  }
}
