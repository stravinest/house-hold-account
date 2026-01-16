import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/router.dart';
import '../../../../config/supabase_config.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isVerified = false;
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _pollingTimer;
  StreamSubscription<AuthState>? _authSubscription;
  late AnimationController _syncAnimationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkInitialVerificationStatus();
    _listenToAuthChanges();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _pollingTimer?.cancel();
    _authSubscription?.cancel();
    _syncAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App resumed to foreground, check verification status
    if (state == AppLifecycleState.resumed && !_isVerified) {
      debugPrint(
        '[EmailVerificationPage] App resumed - checking verification status',
      );
      _checkVerificationFromServer();
    }
  }

  void _checkInitialVerificationStatus() {
    final user = SupabaseConfig.auth.currentUser;
    if (user != null && user.emailConfirmedAt != null) {
      setState(() => _isVerified = true);
      _navigateToHomeAfterDelay();
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = SupabaseConfig.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final user = data.session?.user;

      debugPrint('[EmailVerificationPage] Auth event: $event');
      debugPrint(
        '[EmailVerificationPage] emailConfirmedAt: ${user?.emailConfirmedAt}',
      );

      // Detect email verification completion
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.userUpdated) {
        if (user != null && user.emailConfirmedAt != null) {
          if (!_isVerified) {
            setState(() => _isVerified = true);
            _navigateToHomeAfterDelay();
          }
        }
      }
    });
  }

  // Poll server every 5 seconds (to detect web verification completion)
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isVerified && mounted) {
        _checkVerificationFromServer();
      }
    });
  }

  // Get latest user info from server to check verification status
  Future<void> _checkVerificationFromServer() async {
    if (_isVerified || _isChecking) return;

    setState(() => _isChecking = true);
    _syncAnimationController.forward(from: 0);

    try {
      // Get latest user info from server
      final response = await SupabaseConfig.auth.getUser();
      final user = response.user;

      debugPrint(
        '[EmailVerificationPage] Server check - emailConfirmedAt: ${user?.emailConfirmedAt}',
      );

      if (user != null && user.emailConfirmedAt != null) {
        if (!_isVerified && mounted) {
          setState(() => _isVerified = true);
          _pollingTimer?.cancel();
          _navigateToHomeAfterDelay();
        }
      }
    } catch (e) {
      debugPrint(
        '[EmailVerificationPage] Server verification check failed: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _navigateToHomeAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go(Routes.home);
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await SupabaseConfig.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackBarUtils.showSuccess(
          context,
          l10n.emailVerificationResent,
        );

        // Start 60 second cooldown
        setState(() => _resendCooldown = 60);
        _startCooldownTimer();
      }
    } catch (e) {
      debugPrint(
        '[EmailVerificationPage] Resend verification email failed: $e',
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackBarUtils.showError(
          context,
          l10n.emailVerificationResendFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emailVerificationTitle),
        leading: IconButton(
          tooltip: l10n.commonBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.login),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Verification status icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isVerified
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isVerified
                      ? Icons.check_circle_outline
                      : Icons.mark_email_unread_outlined,
                  size: IconSize.xxl,
                  color: _isVerified
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),

              SizedBox(height: Spacing.xl),

              // Status text
              Text(
                _isVerified
                    ? l10n.emailVerificationComplete
                    : l10n.emailVerificationWaiting,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isVerified ? colorScheme.primary : null,
                ),
              ),

              SizedBox(height: Spacing.md),

              // Email address
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
                  widget.email,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: Spacing.lg),

              // Verification badge
              _buildVerificationBadge(colorScheme, textTheme, l10n),

              SizedBox(height: Spacing.lg),

              // Guide text
              Text(
                _isVerified
                    ? l10n.emailVerificationDone
                    : l10n.emailVerificationSent,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              if (!_isVerified) ...[
                SizedBox(height: Spacing.xl),

                // Check verification status button
                OutlinedButton.icon(
                  onPressed: _isChecking ? null : _checkVerificationFromServer,
                  icon: RotationTransition(
                    turns: _syncAnimationController,
                    child: const Icon(Icons.sync),
                  ),
                  label: Text(
                    _isChecking
                        ? l10n.emailVerificationChecking
                        : l10n.emailVerificationCheckStatus,
                  ),
                ),

                SizedBox(height: Spacing.sm),

                // Resend button
                OutlinedButton.icon(
                  onPressed: _resendCooldown > 0 || _isResending
                      ? null
                      : _resendVerificationEmail,
                  icon: _isResending
                      ? SizedBox(
                          width: IconSize.sm,
                          height: IconSize.sm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _resendCooldown > 0
                        ? l10n.emailVerificationResendCooldown(_resendCooldown)
                        : l10n.emailVerificationResendButton,
                  ),
                ),

                SizedBox(height: Spacing.md),
              ],

              if (_isVerified) ...[
                SizedBox(height: Spacing.xl),

                // Loading indicator
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: _isVerified
            ? colorScheme.primaryContainer
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(BorderRadiusToken.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isVerified ? Icons.verified : Icons.pending,
            size: IconSize.sm,
            color: _isVerified
                ? colorScheme.onPrimaryContainer
                : colorScheme.onErrorContainer,
          ),
          SizedBox(width: Spacing.xs),
          Text(
            _isVerified
                ? l10n.emailVerificationVerified
                : l10n.emailVerificationNotVerified,
            style: textTheme.labelLarge?.copyWith(
              color: _isVerified
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
