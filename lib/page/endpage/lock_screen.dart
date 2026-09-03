// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:atomic_notes/security/vault.dart';
import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/logo_container.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:local_auth/local_auth.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final LocalAuthentication auth;

  bool _mounted = true;
  bool _supportState = false;
  bool _isLoading = false;

  @override
  void initState() {
    auth = LocalAuthentication();
    auth.isDeviceSupported().then(
      (bool isSupported) {
        if (!mounted) return;
        setState(() {
          _supportState = isSupported;
        });
      },
    );
    super.initState();
    autoAuth();
  }

  @override
  void dispose() {
    _mounted = false;
    _isLoading = false;
    super.dispose();
  }

  autoAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    _auth();
  }

  Future<void> _auth() async {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
    });
    try {
      bool authenticated = await auth.authenticate(
          localizedReason: "Privacy for AtomicNotes",
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ));

      if (!_mounted) return;
      if (authenticated) {
        // The device lock has passed. If the vault is still sealed on this
        // device, ask for the recovery phrase before showing notes.
        if (Vault.instance.isLocked) {
          Navigator.pushReplacementNamed(context, '/vaultunlock',
              arguments: true);
        } else {
          Navigator.pushReplacementNamed(context, '/mainpage');
        }
      }
    } on PlatformException catch (e) {
      if (!_mounted) return;
      MySnackBar(
        text: e.toString(),
        sec: 1000,
      ).showMySnackBar(context);
    } finally {
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const LogoContainer(showTagline: false),
              const Spacer(flex: 2),
              const MonoLabel('LOCKED', color: AppColors.signal),
              const SizedBox(height: AppSpace.sm),
              const HairRule(color: AppColors.ink),
              const SizedBox(height: AppSpace.lg),
              const EditorialHeading(
                'This device is\nlocked.',
                style: AppType.displayLg,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Unlock with your fingerprint or device credential to open '
                'your notes.',
                style: AppType.bodyMd.copyWith(color: AppColors.slateData),
              ),
              const SizedBox(height: AppSpace.xl),
              // Tap target is the whole action block — an Ink slab with a
              // Paper glyph, rather than a floating coloured square.
              GestureDetector(
                onTap: _isLoading ? null : _auth,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpace.lg, horizontal: AppSpace.md),
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: AppRadius.std,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.signal,
                        offset: Offset(AppStroke.offset, AppStroke.offset),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.paper),
                          ),
                        )
                      else if (_supportState)
                        const Icon(Icons.fingerprint_rounded,
                            color: AppColors.paper, size: 26)
                      else
                        SizedBox(
                          height: 22,
                          width: 22,
                          child: SvgPicture.asset(
                            'assets/dots.svg',
                            colorFilter: const ColorFilter.mode(
                                AppColors.paper, BlendMode.srcIn),
                          ),
                        ),
                      const SizedBox(width: AppSpace.md - 4),
                      Text(
                        _isLoading ? 'AUTHENTICATING…' : 'UNLOCK',
                        style: AppType.cta.copyWith(color: AppColors.paper),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
