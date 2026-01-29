import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // auth state stream이 업데이트될 때까지 대기 (최대 3초)
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;

        final authState = ref.read(authStateProvider);
        if (authState.valueOrNull != null) {
          context.go(Routes.home);
          return;
        }
      }

      // 3초 후에도 auth state가 업데이트되지 않으면 에러 표시
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtils.showError(context, l10n.authLoginError);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        String errorMessage;
        if (e is AuthApiException) {
          switch (e.code) {
            case 'invalid_credentials':
              errorMessage = l10n.authInvalidCredentials;
              break;
            case 'email_not_confirmed':
              errorMessage = l10n.authEmailNotVerified;
              break;
            default:
              errorMessage = l10n.errorWithMessage(e.message);
          }
        } else if (e is AuthRetryableFetchException ||
            e.toString().contains('SocketException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Network is unreachable')) {
          // 네트워크 연결 에러
          errorMessage = l10n.errorNetwork;
        } else {
          errorMessage = l10n.errorWithMessage(e.toString());
        }
        SnackBarUtils.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();

      // 로그인 성공 시 홈으로 이동
      if (!mounted) return;

      // auth state stream이 업데이트될 때까지 대기 (최대 3초)
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;

        final authState = ref.read(authStateProvider);
        if (authState.valueOrNull != null) {
          context.go(Routes.home);
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        // 사용자 취소는 에러 메시지 표시하지 않음
        if (e.toString().contains('취소') ||
            e.toString().contains('canceled') ||
            e.toString().contains('CANCELED')) {
          return;
        }

        final l10n = AppLocalizations.of(context);
        String errorMessage;
        if (e is AuthRetryableFetchException ||
            e.toString().contains('SocketException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Network is unreachable')) {
          // 네트워크 연결 에러
          errorMessage = l10n.errorNetwork;
        } else {
          errorMessage = l10n.errorWithMessage(e.toString());
        }
        SnackBarUtils.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // 디자인 시스템 토큰
    const inputBorderRadius = 12.0;
    const buttonHeight = 52.0;
    const inputHeight = 56.0;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더 섹션
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
                  child: Column(
                    children: [
                      // 앱 아이콘 로고
                      Image.asset(
                        'assets/images/app_icon.png',
                        width: 80,
                        height: 80,
                      ),
                      const SizedBox(height: 16),
                      // 타이틀
                      Text(
                        l10n.appTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1C19),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.appSubtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // 폼 섹션
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // 이메일 입력
                      SizedBox(
                        height: inputHeight,
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: inputDecoration.copyWith(
                            hintText: l10n.authEmail,
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
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
                      ),
                      const SizedBox(height: 16),

                      // 비밀번호 입력
                      SizedBox(
                        height: inputHeight,
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleEmailLogin(),
                          decoration: inputDecoration.copyWith(
                            hintText: l10n.authPassword,
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              tooltip: l10n.tooltipTogglePassword,
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.validationPasswordRequired;
                            }
                            if (value.length < 6) {
                              return l10n.validationPasswordTooShort;
                            }
                            return null;
                          },
                        ),
                      ),

                      // 비밀번호 찾기
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push(Routes.forgotPassword),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 8),
                          ),
                          child: Text(
                            l10n.authForgotPassword,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 버튼 섹션
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // 로그인 버튼
                      SizedBox(
                        height: buttonHeight,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleEmailLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(inputBorderRadius),
                            ),
                            elevation: 2,
                            shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  l10n.authLogin,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 구분선
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                l10n.authOr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Google 로그인
                      SizedBox(
                        height: buttonHeight,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(color: colorScheme.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(inputBorderRadius),
                            ),
                            backgroundColor: colorScheme.surface,
                          ),
                          icon: CachedNetworkImage(
                            imageUrl: 'https://www.google.com/favicon.ico',
                            width: 20,
                            height: 20,
                            placeholder: (context, url) => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.g_mobiledata, size: 20),
                          ),
                          label: const Text(
                            'Google로 계속하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 회원가입 링크
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.authNoAccount,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => context.push(Routes.signup),
                        child: Text(
                          l10n.authSignup,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
