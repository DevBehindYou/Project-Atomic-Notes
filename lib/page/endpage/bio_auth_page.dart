// ignore_for_file: use_build_context_synchronously

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/my_appbar.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:local_auth/local_auth.dart';

class BiomPage extends StatefulWidget {
  const BiomPage({super.key});

  @override
  State<BiomPage> createState() => _BiomPageState();
}

class _BiomPageState extends State<BiomPage> {
  // Plain nullable, NOT `late final`: this is assigned from an async callback
  // that can lose the race against dispose(), and reading an unassigned
  // `late final` throws LateInitializationError.
  Box<bool>? _authBox;
  late final LocalAuthentication auth;
  bool isAuthOn = false;
  bool _supportState = false;

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
    _initAuthHive();
    super.initState();
  }

  Future<void> _initAuthHive() async {
    final box = await Hive.openBox<bool>('authBox');
    if (!mounted) return;
    setState(() {
      _authBox = box;
      isAuthOn = box.get('isAuthOn', defaultValue: false) ?? false;
    });
  }

  Future<bool> _checkCapability() async {
    try {
      bool authenticated = await auth.authenticate(
          localizedReason: "Checking Device Capability",
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ));

      if (authenticated) {
        return true;
      }
      return false;
    } on PlatformException catch (_) {
      // The biometric prompt can sit open for a while — the user may have
      // left this screen by the time it fails.
      if (!mounted) return false;
      const MySnackBar(
        text: "Error Establishing Biometric Auth",
        sec: 2000,
      ).showMySnackBar(context);
      return false;
    }
  }

  // NOTE: deliberately no `_authBox.close()` here. 'authBox' is a process-wide
  // box opened once in main(); closing it from one screen's dispose() tore it
  // down for every other screen that reads it.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const MyAppBar(text: "Security"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.md, AppSpace.lg, AppSpace.md, AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              'DEVICE LOCK',
              trailing: DataChip(
                isAuthOn ? 'ARMED' : 'OFF',
                active: true,
                activeColor: isAuthOn ? AppColors.signal : AppColors.outline,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            EditorialModule(
              accent: isAuthOn,
              padding: const EdgeInsets.all(AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EditorialHeading('Biometric unlock',
                            style: AppType.headlineSm),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          _supportState
                              ? "Require a fingerprint or face check before "
                                  "opening Atomic."
                              : "This device doesn't report biometric support.",
                          style: AppType.bodySm,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  CupertinoSwitch(
                value: isAuthOn,
                // activeColor was deprecated after Flutter 3.24.
                activeTrackColor: AppColors.signal,
                onChanged: (bool value) async {
                  final box = _authBox;
                  // Nothing to persist to yet — the box is still opening.
                  if (box == null) return;
                  if (_supportState && await _checkCapability()) {
                    if (!mounted) return;
                    // The write is awaited outside setState: setState's
                    // callback is for mutating state, not for I/O.
                    await box.put('isAuthOn', value);
                    if (!mounted) return;
                    setState(() {
                      isAuthOn = value;
                    });
                    MySnackBar(
                      text: value
                          ? "Biometric Authentication On"
                          : "Biometric Authentication Off",
                      sec: 2000,
                    ).showMySnackBar(context);
                  }
                },
              ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            // Prerequisites, framed as a warning module rather than a wall of
            // grey body text.
            EditorialModule(
              fill: AppColors.errorContainer,
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MonoLabel('REQUIREMENTS',
                      color: AppColors.onErrorContainer),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    "The device needs a lock-screen credential and a "
                    "fingerprint sensor for this to work. If you remove the "
                    "lock-screen password while this is on, unlocking Atomic "
                    "may fail.",
                    style: AppType.bodySm
                        .copyWith(color: AppColors.onErrorContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
