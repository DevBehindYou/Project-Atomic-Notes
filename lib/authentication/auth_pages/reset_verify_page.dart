// ignore_for_file: use_build_context_synchronously

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/logo_container.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:atomic_notes/utility/component/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Second half of the password reset: the user enters the 6-digit code that
/// Supabase emailed, plus a new password, and both are handled in-app.
///
/// No email deep link is involved. `resetPasswordForEmail` (previous screen)
/// triggers a recovery email whose template carries the one-time token
/// (`{{ .Token }}`). Here we verify that token with `verifyOTP(recovery)`,
/// which returns a session, then `updateUser` sets the new password on it.
///
/// The email address is passed as the route argument.
class ResetVerifyPage extends StatefulWidget {
  final String email;
  const ResetVerifyPage({required this.email, super.key});

  @override
  State<ResetVerifyPage> createState() => _ResetVerifyPageState();
}

class _ResetVerifyPageState extends State<ResetVerifyPage> {
  final supabase = Supabase.instance.client;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _resending = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (code.length < 6) {
      _toast('Enter the 6-digit code from your email.');
      return;
    }
    if (pass.length < 6) {
      _toast('New password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      _toast("Passwords don't match.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Verify the emailed code. On success this returns a recovery session.
      final res = await supabase.auth.verifyOTP(
        type: OtpType.recovery,
        email: widget.email,
        token: code,
      );
      if (res.session == null) {
        _toast('That code did not verify. Check it and try again.');
        return;
      }
      // Set the new password on the session the code just established.
      await supabase.auth.updateUser(UserAttributes(password: pass));
      if (!mounted) return;
      const MySnackBar(
        text: 'Password updated. You are signed in.',
        sec: 2500,
      ).showMySnackBar(context);
      // The recovery verify already signed the user in, so continue into the
      // app through the splash (which wires up the vault and sync).
      Navigator.pushNamedAndRemoveUntil(context, '/splashpage', (r) => false);
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not reset the password. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await supabase.auth.resetPasswordForEmail(widget.email);
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
            const MonoLabel('PASSWORD RESET', color: AppColors.signal),
            const SizedBox(height: AppSpace.sm),
            const HairRule(color: AppColors.ink),
            const SizedBox(height: AppSpace.lg),
            const EditorialHeading(
              'Enter your\ncode.',
              style: AppType.displayLg,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'We emailed a 6-digit code to ${widget.email}. Enter it below with '
              'your new password. The code is checked on the server and never '
              'leaves this flow.',
              style: AppType.bodyMd,
            ),
            const SizedBox(height: AppSpace.lg),
            MyTextField(
              ico: const Icon(Icons.pin_outlined),
              hintText: '6-digit code',
              controller: _codeController,
              keyboardType: TextInputType.number,
              // Recovery tokens are numeric; cap at 6 and strip anything else.
            ),
            MyTextField(
              ico: const Icon(Icons.password),
              hintText: 'New password',
              controller: _passwordController,
              obscureText: true,
            ),
            MyTextField(
              ico: const Icon(Icons.password),
              hintText: 'Confirm new password',
              controller: _confirmController,
              obscureText: true,
            ),
            const SizedBox(height: AppSpace.lg),
            InkActionButton(
              label: 'Set new password',
              signal: true,
              icon: Icons.lock_reset,
              loading: _isLoading,
              onTap: _submit,
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
