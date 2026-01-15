import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/router.dart';
import '../../../../config/supabase_config.dart';
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
    // 앱이 포그라운드로 돌아올 때 인증 상태 확인
    if (state == AppLifecycleState.resumed && !_isVerified) {
      debugPrint('[EmailVerificationPage] 앱 포그라운드 복귀 - 인증 상태 확인');
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

      // 이메일 인증 완료 감지
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

  // 5초마다 서버에서 인증 상태 확인 (웹에서 인증 완료한 경우 감지)
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isVerified && mounted) {
        _checkVerificationFromServer();
      }
    });
  }

  // 서버에서 최신 사용자 정보를 가져와 인증 상태 확인
  Future<void> _checkVerificationFromServer() async {
    if (_isVerified || _isChecking) return;

    setState(() => _isChecking = true);
    _syncAnimationController.forward(from: 0);

    try {
      // 서버에서 최신 사용자 정보 가져오기
      final response = await SupabaseConfig.auth.getUser();
      final user = response.user;

      debugPrint(
        '[EmailVerificationPage] 서버 확인 - emailConfirmedAt: ${user?.emailConfirmedAt}',
      );

      if (user != null && user.emailConfirmedAt != null) {
        if (!_isVerified && mounted) {
          setState(() => _isVerified = true);
          _pollingTimer?.cancel();
          _navigateToHomeAfterDelay();
        }
      }
    } catch (e) {
      debugPrint('[EmailVerificationPage] 서버 인증 상태 확인 실패: $e');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증 메일을 다시 보냈습니다. 메일함을 확인해주세요.'),
            duration: Duration(seconds: 3),
          ),
        );

        // 60초 쿨다운 시작
        setState(() => _resendCooldown = 60);
        _startCooldownTimer();
      }
    } catch (e) {
      debugPrint('[EmailVerificationPage] 인증 메일 재전송 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증 메일 전송에 실패했습니다: $e'),
            duration: const Duration(seconds: 3),
          ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('이메일 인증'),
        leading: IconButton(
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
              // 인증 상태 아이콘
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

              // 상태 텍스트
              Text(
                _isVerified ? '이메일 인증 완료!' : '이메일 인증 대기 중',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isVerified ? colorScheme.primary : null,
                ),
              ),

              SizedBox(height: Spacing.md),

              // 이메일 주소
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

              // 인증 상태 배지
              _buildVerificationBadge(colorScheme, textTheme),

              SizedBox(height: Spacing.lg),

              // 안내 텍스트
              Text(
                _isVerified
                    ? '인증이 완료되었습니다.\n잠시 후 홈 화면으로 이동합니다.'
                    : '위 이메일로 인증 메일을 보냈습니다.\n메일함을 확인하고 인증 링크를 클릭해주세요.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              if (!_isVerified) ...[
                SizedBox(height: Spacing.xl),

                // 인증 상태 확인 버튼
                OutlinedButton.icon(
                  onPressed: _isChecking ? null : _checkVerificationFromServer,
                  icon: RotationTransition(
                    turns: _syncAnimationController,
                    child: const Icon(Icons.sync),
                  ),
                  label: Text(_isChecking ? '확인 중...' : '인증 상태 확인'),
                ),

                SizedBox(height: Spacing.sm),

                // 재전송 버튼
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
                        ? '재전송 ($_resendCooldown초 후 가능)'
                        : '인증 메일 다시 보내기',
                  ),
                ),

                SizedBox(height: Spacing.md),

                // 자동 확인 안내 + 스팸 폴더 안내
                Text(
                  '5초마다 자동으로 인증 상태를 확인합니다.\n메일이 오지 않나요? 스팸 폴더를 확인해주세요.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              if (_isVerified) ...[
                SizedBox(height: Spacing.xl),

                // 로딩 인디케이터
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(ColorScheme colorScheme, TextTheme textTheme) {
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
            _isVerified ? '인증 완료' : '미인증',
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
