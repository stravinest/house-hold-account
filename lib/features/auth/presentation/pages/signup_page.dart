import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    debugPrint('[SignupPage] signup started');

    if (!_formKey.currentState!.validate()) {
      debugPrint('[SignupPage] form validation failed');
      return;
    }

    debugPrint('[SignupPage] form validation passed');
    setState(() => _isLoading = true);

    try {
      debugPrint('[SignupPage] signUpWithEmail call started');
      await ref
          .read(authNotifierProvider.notifier)
          .signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );

      debugPrint('[SignupPage] signUpWithEmail call succeeded');

      if (mounted) {
        debugPrint('[SignupPage] signup success - navigating to home');
        context.go(Routes.home);
      }
    } catch (e, st) {
      debugPrint('[SignupPage] signup failed: ${e.runtimeType}');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        String errorMessage;
        if (e is AuthApiException) {
          switch (e.code) {
            case 'user_already_exists':
              errorMessage = l10n.authEmailAlreadyRegistered;
              break;
            case 'email_not_confirmed':
              errorMessage = l10n.authEmailNotVerified;
              break;
            default:
              // 영어 메시지를 한글로 변환
              if (e.message.contains('already registered') ||
                  e.message.contains('User already registered')) {
                errorMessage = l10n.authEmailAlreadyRegistered;
              } else {
                errorMessage = l10n.errorWithMessage(e.message);
              }
          }
        } else {
          final errorStr = e.toString();
          if (errorStr.contains('already registered') ||
              errorStr.contains('User already registered')) {
            errorMessage = l10n.authEmailAlreadyRegistered;
          } else {
            errorMessage = l10n.errorWithMessage(errorStr);
          }
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authSignup)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // 안내 문구
                Text(
                  l10n.authSignupTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.authSignupSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                // 이름 입력
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.authName,
                    prefixIcon: const Icon(Icons.person_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.validationNameRequired;
                    }
                    if (value.length < 2) {
                      return l10n.validationNameTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 이메일 입력
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.authEmail,
                    prefixIcon: const Icon(Icons.email_outlined),
                    hintText: 'example@email.com',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.validationEmailRequired;
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return l10n.validationEmailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 비밀번호 입력
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.authPassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? l10n.authPasswordShow
                          : l10n.authPasswordHide,
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
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
                const SizedBox(height: 16),

                // 비밀번호 확인
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignup(),
                  decoration: InputDecoration(
                    labelText: l10n.authPasswordConfirm,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword
                          ? l10n.authPasswordShow
                          : l10n.authPasswordHide,
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.validationPasswordConfirmRequired;
                    }
                    if (value != _passwordController.text) {
                      return l10n.validationPasswordMismatch;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // 회원가입 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.authSignup),
                ),

                const SizedBox(height: 16),

                // 이용약관 안내
                Text(
                  l10n.authTermsAgreement,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // 로그인 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.authHaveAccount,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(l10n.authLogin),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
