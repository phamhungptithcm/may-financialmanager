/// Mây Family Finance — Sign In Screen (UI-02)
///
/// Primary entry point: Google and Apple sign-in buttons.
/// On success → navigate to HouseholdSetup screen.
/// On cancel/error → show Vietnamese error message.

// ignore_for_file: public_member_api_docs

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:may/features/auth/domain/auth_repository.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_spacing.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';
import 'package:may/shared/widgets/may_button.dart';
import 'package:may/shared/widgets/may_card.dart';
import 'package:may/shared/widgets/may_text.dart';

/// Sign in screen supporting Google and Apple authentication.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthRepository _auth = AuthRepository();
  bool _isSigningIn = false;
  String? _errorMessage;

  Future<void> _googleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });
    try {
      await _auth.signInWithGoogle();
      if (mounted) context.go('/onboarding/household');
    } catch (e) {
      if (mounted && e is AuthError) {
        setState(() => _errorMessage = e.userMessage);
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _appleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });
    try {
      final r = await _auth.signInWithApple();
      if (r != null && mounted) context.go('/onboarding/household');
    } catch (e) {
      if (mounted && e is AuthError) {
        setState(() => _errorMessage = e.userMessage);
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final bg = Theme.of(context).brightness == Brightness.dark
        ? MayColors.canvasDark
        : MayColors.canvas;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MaySpacing.s20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.family_restroom_rounded, size: 64, color: MayColors.accent),
                        const SizedBox(height: MaySpacing.s16),
                        MayText(
                          'Quản lý chi tiêu gia đình',
                          style: MayTypography.displayMedium(context, color: MayColors.primary),
                        ),
                        const SizedBox(height: MaySpacing.s8),
                        MayText(
                          'Theo dõi thu nhập, chi tiêu và ngân sách cho cả nhà.',
                          style: MayTypography.bodyLarge(context, color: MayColors.secondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 3,
                    child: MayCard.elevated(
                      child: Padding(
                        padding: const EdgeInsets.all(MaySpacing.s16),
                        child: Column(
                          children: [
                            MayButton.primary(
                              label: 'Đăng nhập với Google',
                              onPressed: _isSigningIn ? null : _googleSignIn,
                              isLoading: _isSigningIn,
                              leadingIcon: Icons.login_rounded,
                            ),
                            const SizedBox(height: MaySpacing.s12),
                            if (isIOS) ...[
                              MayButton.secondary(
                                label: 'Đăng nhập với Apple',
                                onPressed: _isSigningIn ? null : _appleSignIn,
                                isLoading: _isSigningIn,
                                leadingIcon: Icons.apple_rounded,
                              ),
                              const SizedBox(height: MaySpacing.s12),
                            ],
                            if (_errorMessage != null) ...[
                              MayText(
                                _errorMessage!,
                                style: const TextStyle(color: MayColors.danger, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: MaySpacing.s8),
                            ],
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(top: MaySpacing.s8),
                                child: MayText(
                                  'Bằng cách đăng nhập, bạn đồng ý với Điều khoản dịch vụ và Chính sách bảo mật của chúng tôi.',
                                  style: MayTypography.labelSmall(context, color: MayColors.secondary),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
