// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:async';
import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/login_button.dart';
import 'package:atomic_notes/utility/component/logo_container.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:atomic_notes/utility/component/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _redirecting = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _isSwitch = false;

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (_redirecting) return;

      final session = data.session;
      if (session != null) {
        _redirecting = true;
        Navigator.of(context).pushReplacementNamed('/splashpage');
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _authStateSubscription
        .cancel(); // Cancel the subscription to avoid memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _isSwitch = false;
    _isLoading = false;
    _redirecting = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 72),
                const LogoContainer(),
                const SizedBox(height: AppSpace.xxl),
                // Mode switch as a two-up chip pair: the active mode is a
                // solid Ink block, the inactive one an outline.
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.screenMargin),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: toggleSwitch,
                          behavior: HitTestBehavior.opaque,
                          child: _AuthModeTab(
                              label: 'Sign In', active: !_isSwitch),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: GestureDetector(
                          onTap: toggleSwitch,
                          behavior: HitTestBehavior.opaque,
                          child: _AuthModeTab(
                              label: 'Sign Up', active: _isSwitch),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                _isSwitch
                    ? Column(
                        children: [
                          // sign up textfield section
                          const _AuthHeader(
                            eyebrow: 'NEW ACCOUNT',
                            title: 'Hi there.',
                            subtitle: 'Sign up with your details.',
                          ),

                          // textfields + signup button
                          Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: AppSpace.md),
                            child: Column(
                              children: [
                                MyTextField(
                                  ico: const Icon(Icons.email),
                                  hintText: "Enter Email",
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                MyTextField(
                                  ico: const Icon(Icons.password),
                                  hintText: "Enter Password",
                                  controller: _passwordController,
                                  obscureText: true,
                                ),
                                MyTextField(
                                  ico: const Icon(Icons.password),
                                  hintText: "Confirm Password ",
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                ),
                                const SizedBox(height: AppSpace.lg),
                                // sign up gesture section
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.screenMargin),
                                  child: LoginButton(
                                    ico: "assets/login.svg",
                                    isLoading: _isLoading,
                                    signIn: _signUp,
                                    text: "Sign Up",
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.screenMargin),
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/tcpage'),
                              behavior: HitTestBehavior.opaque,
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  HairRule(),
                                  SizedBox(height: AppSpace.md),
                                  MonoLabel(
                                      'BY SIGNING UP YOU AGREE TO THE TERMS'),
                                  SizedBox(height: AppSpace.xs),
                                  ArrowLink('Read terms & conditions'),
                                ],
                              ),
                            ),
                          )
                        ],
                      )
                    : Column(
                        children: [
                          // sign in textfield section
                          const _AuthHeader(
                            eyebrow: 'RETURNING',
                            title: 'Welcome back.',
                            subtitle: 'Sign in with your email and password.',
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: AppSpace.md),
                            child: Column(
                              children: [
                                // email textfield section
                                MyTextField(
                                  ico: const Icon(Icons.email),
                                  hintText: "Enter Email",
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                // password textfield section
                                MyTextField(
                                  ico: const Icon(Icons.password),
                                  hintText: "Enter Password",
                                  controller: _passwordController,
                                  obscureText: true,
                                ),
                                const SizedBox(height: AppSpace.md),

                                // forget password gesture section
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.screenMargin),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ArrowLink(
                                        'Forgot password',
                                        onTap: () {
                                          Navigator.of(context)
                                              .pushReplacementNamed(
                                                  '/resetpage');
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: AppSpace.lg),

                                // sign in button gesture section
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.screenMargin),
                                  child: LoginButton(
                                    ico: "assets/login.svg",
                                    isLoading: _isLoading,
                                    signIn: _signIn,
                                    text: "Sign In",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
              ],
            ),
          ),
        ));
  }

  Future<void> _signIn() async {
    if (_isFilled()) {
      try {
        setState(() {
          _isLoading = true;
        });

        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on AuthException catch (error) {
        MySnackBar(
          text: error.message,
          sec: 2000,
        ).showMySnackBar(context);
      } catch (error) {
        const MySnackBar(
          text: "Unknown error occurred!",
          sec: 2000,
        ).showMySnackBar(context);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      const MySnackBar(
        text: "Please fill up all sections",
        sec: 2000,
      ).showMySnackBar(context);
    }
  }

  toggleSwitch() {
    setState(() {
      _isSwitch = !_isSwitch;
    });
  }

  Future<void> _signUp() async {
    if (_isFilled()) {
      if (_passwordConfirmed()) {
        try {
          setState(() {
            _isLoading = true;
          });

          final email = _emailController.text.trim();
          final res = await supabase.auth.signUp(
            email: email,
            password: _passwordController.text.trim(),
          );
          if (!mounted) return;
          if (res.session != null) {
            // "Confirm email" is off — the account is already usable.
            Navigator.pushReplacementNamed(context, '/splashpage');
          } else {
            // Confirmation required: Supabase emailed a 6-digit code (delivered
            // via the configured SMTP/Resend). Collect it on the verify screen.
            const MySnackBar(
              text: "We emailed you a 6-digit code to verify your account.",
              sec: 3000,
            ).showMySnackBar(context);
            Navigator.pushNamed(context, '/signupverify', arguments: email);
          }
        } on AuthException catch (error) {
          MySnackBar(
            text: error.message,
            sec: 2000,
          ).showMySnackBar(context);
        } catch (error) {
          const MySnackBar(
            sec: 2000,
            text: "Unknown error occurred!",
          ).showMySnackBar(context);
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        const MySnackBar(
          text: "Passwords didn't match",
          sec: 2000,
        ).showMySnackBar(context);
      }
    } else {
      const MySnackBar(
        text: "Please fill up all sections",
        sec: 2000,
      ).showMySnackBar(context);
    }
  }

  bool _isFilled() {
    if (_emailController.text.trim() == '' ||
        _passwordController.text.trim() == '') {
      return false;
    }
    return true;
  }

  bool _passwordConfirmed() {
    if (_passwordController.text.trim() ==
        _confirmPasswordController.text.trim()) {
      return true;
    } else {
      return false;
    }
  }
}

/// Sign-in / sign-up selector. The active mode is a solid Ink block; the
/// inactive one is an outline — the reference's filter-chip treatment.
class _AuthModeTab extends StatelessWidget {
  final String label;
  final bool active;
  const _AuthModeTab({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.ink : Colors.transparent,
        borderRadius: AppRadius.std,
        border: Border.all(
          color: active ? AppColors.ink : AppColors.outlineVariant,
          width: AppStroke.rule,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppType.cta.copyWith(
          color: active ? AppColors.paper : AppColors.slateData,
        ),
      ),
    );
  }
}

/// Eyebrow + display headline + one-line subtitle, left-aligned against the
/// page margin — the standard section opener in this design system.
class _AuthHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  const _AuthHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpace.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel(eyebrow, color: AppColors.signal),
          const SizedBox(height: AppSpace.xs),
          EditorialHeading(title, style: AppType.displayLg),
          const SizedBox(height: AppSpace.xs),
          Text(subtitle, style: AppType.bodyMd),
          const SizedBox(height: AppSpace.md),
          const HairRule(color: AppColors.ink),
        ],
      ),
    );
  }
}
