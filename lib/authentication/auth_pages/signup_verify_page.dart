// ignore_for_file: use_build_context_synchronously

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/logo_container.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:atomic_notes/utility/component/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Account verification: the user enters the 6-digit code emailed on sign-up.
///
/// With "Confirm email" on, `signUp` creates the account but returns no session
/// until the email is confirmed. Here we confirm it with `verifyOTP(signup)`,
/// which returns a session, and the user continues into the app. No email link
/// or deep link is involved. The email address is the route argument.
class SignupVerifyPage extends StatefulWidget {
  final String email;
  const SignupVerifyPage({required this.email, super.key});

  @override
  State<SignupVerifyPage> createState() => _SignupVerifyPageState();
}

class _SignupVerifyPageState extends State<SignupVerifyPage> {
  final supabase = Supabase.instance.client;
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _resending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      _toast('Enter the 6-digit code from your email.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      // `signup` is deprecated for verifyOTP; `email` verifies a sign-up code.
      final res = await supabase.auth.verifyOTP(
        type: OtpType.email,
        email: widget.email,
        token: code,
      );
      if (res.session == null) {
        _toast('That code did not verify. Check it and try again.');
        return;
      }
      if (!mounted) return;
      const MySnackBar(text: 'Email verified. Welcome to Atomic Notes.', sec: 2500)
          .showMySnackBar(context);
      Navigator.pushNamedAndRemoveUntil(context, '/splashpage', (r) => false);
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not verify. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await supabase.auth.resend(type: OtpType.signup, email: widget.email);
      if (!mounted) return;
      _toast('New code sent to ${widget.email}.');
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not resend the code.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    MySnackBar(text: text, sec: 2500).showMySnackBar(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenMargin, AppSpace.xl,
              AppSpace.screenMargin, AppSpace.xxl),
          children: [
            const LogoContainer(showTagline: false),
            const SizedBox(height: AppSpace.xl),
            const MonoLabel('VERIFY EMAIL', color: AppColors.signal),
            const SizedBox(height: AppSpace.sm),
            const HairRule(color: AppColors.ink),
            const SizedBox(height: AppSpace.lg),
            const EditorialHeading(
              'Confirm your\naccount.',
              style: AppType.displayLg,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'We emailed a 6-digit code to ${widget.email}. Enter it to finish '
              'creating your account.',
              style: AppType.bodyMd,
            ),
            const SizedBox(height: AppSpace.lg),
            MyTextField(
              ico: const Icon(Icons.pin_outlined),
              hintText: '6-digit code',
              controller: _codeController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpace.lg),
            InkActionButton(
              label: 'Verify email',
              signal: true,
              icon: Icons.verified_outlined,
              loading: _isLoading,
              onTap: _verify,
            ),
            const SizedBox(height: AppSpace.md),
            Center(
              child: GhostButton(
                label: _resending ? 'Sending…' : 'Resend code',
                expand: false,
                onTap: _resending ? null : _resend,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Center(
              child: GhostButton(
                label: 'Back to sign in',
                expand: false,
                onTap: _isLoading
                    ? null
                    : () => Navigator.pushNamedAndRemoveUntil(
                        context, '/loginpage', (r) => false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
