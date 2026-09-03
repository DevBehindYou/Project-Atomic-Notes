// ignore_for_file: use_build_context_synchronously

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/logo_container.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:atomic_notes/utility/component/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    try {
      // Show loading indicator if needed
      setState(() {
        _isLoading = true;
      });

      // Supabase generates a 6-digit recovery code and emails it (via whatever
      // SMTP is configured — Supabase's own mailer now, Resend later). The user
      // then enters that code on the verify screen and sets a new password
      // in-app, so no email deep link is needed.
      final email = _emailController.text.trim();
      await supabase.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      const MySnackBar(
        text: 'We emailed you a 6-digit code. Enter it on the next screen.',
        sec: 3000,
      ).showMySnackBar(context);
      Navigator.pushNamed(context, '/resetverify', arguments: email);
    } on AuthException catch (error) {
      // Handle specific authentication exceptions
      MySnackBar(
        text: error.message,
        sec: 2000,
      ).showMySnackBar(context);
    } catch (error) {
      // Handle other errors
      const MySnackBar(
        text: 'Unknown error occurred',
        sec: 2000,
      ).showMySnackBar(context);
    } finally {
      // Hide loading indicator if needed
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
              const SizedBox(height: 120),
              const LogoContainer(),
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  "Enter you email to reset your password",
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // email recovery textfield
              MyTextField(
                ico: const Icon(Icons.email),
                hintText: "Enter Email",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.screenMargin),
                child: Row(
                  children: [
                    // Square Ink back-block, matching MyAppBar's.
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .pushReplacementNamed('/loginpage');
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: AppRadius.std,
                          border: Border.all(
                              color: AppColors.ink, width: AppStroke.hairline),
                        ),
                        child: const Icon(Icons.arrow_back,
                            size: 18, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm + 2),
                    Expanded(
                      child: InkActionButton(
                        label: 'Send reset link',
                        icon: Icons.mail_outline,
                        loading: _isLoading,
                        onTap: _resetPassword,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
