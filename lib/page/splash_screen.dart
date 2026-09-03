// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:async';

import 'package:atomic_notes/database/energy_service.dart';
import 'package:atomic_notes/database/notification_service.dart';
import 'package:atomic_notes/database/notes_repository.dart';
import 'package:atomic_notes/security/vault.dart';
import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/app_info.dart';
import 'package:atomic_notes/utility/component/logo_container.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    try {
      // The auth box is read here rather than in a separate method racing
      // this one: the old code could reach the `isAuthOn` check before the
      // box-opening callback had assigned it.
      final authBox = await Hive.openBox<bool>('authBox');
      if (!mounted) return;
      final bool isAuthOn = authBox.get('isAuthOn', defaultValue: false) ?? false;
      final bool hasSeenOnboarding =
          authBox.get('hasSeenOnboarding', defaultValue: false) ?? false;

      final session = supabase.auth.currentSession;
      if (session == null) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/loginpage');
        return;
      }

      // Re-read the vault for THIS account now that a session exists.
      //
      // main() also calls this, but main() runs before the user has signed in:
      // on a second device the account id is still null there, so the vault
      // reads as "not configured" and stays that way for the whole session.
      // That single missing refresh is why the same recovery phrase on a
      // second phone showed no notes: the unlock screen never appeared,
      // encrypted rows were skipped as unreadable, and new notes were written
      // in the clear. The splash runs on every launch AND after every login,
      // which makes it the one place this is always correct.
      await Vault.instance.init();

      // Local-first means routing NEVER waits on the network. The cached
      // notes were already loaded from Hive in main(), so there is nothing
      // here worth blocking on — start() is deliberately not awaited.
      //
      // It used to be awaited, which meant that with no connection the app
      // sat on this screen until a socket gave up. An offline launch has to
      // be as fast as an online one.
      unawaited(NotesRepository.instance.start());

      // Load Atomic Energy/Coins for this account and apply the daily grant.
      // Non-blocking, same as sync — routing never waits on it.
      unawaited(EnergyService.instance.init());

      // Pull the notification feed for this account (also non-blocking).
      unawaited(NotificationService.instance.init());

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      // The device lock takes priority. It used to be reachable only from the
      // "has local notes" branch, so a user with biometrics on but an empty
      // local cache was routed past it into the app.
      if (isAuthOn) {
        Navigator.pushReplacementNamed(context, '/lockscreen');
        return;
      }

      // Vault gate. Only reached when the device lock is off; when it is on,
      // lock_screen routes here itself after a successful check, so the
      // biometric gate always comes first.
      if (Vault.instance.isLocked) {
        Navigator.pushReplacementNamed(context, '/vaultunlock',
            arguments: true);
        return;
      }

      // Onboarding is keyed off its own persisted flag. It used to be keyed
      // off `NOTESLIST == null`, which is only written when the user saves
      // their first note — so anyone who hadn't written a note yet got the
      // 6-page tutorial on every single launch.
      if (!hasSeenOnboarding) {
        await authBox.put('hasSeenOnboarding', true);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/onboardingscreen');
        return;
      }

      Navigator.pushReplacementNamed(context, '/mainpage');
    } catch (error) {
      // Fall back to the login page rather than sitting on the splash forever.
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/loginpage');
    }
  }

  // NOTE: deliberately no `_authBox.close()` here — see bio_auth_page.dart.
  // The splash screen is disposed on every launch, so closing the shared
  // 'authBox' here shut it down seconds into every session.

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpace.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Spacer(flex: 3),
              LogoContainer(showTagline: true),
              Spacer(flex: 4),
              // Boot status reads like a system readout rather than a
              // decorative spinner block.
              HairRule(color: AppColors.ink),
              SizedBox(height: AppSpace.md),
              Row(
                children: [
                  SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.signal,
                    ),
                  ),
                  SizedBox(width: AppSpace.md - 4),
                  Expanded(
                    child: MonoLabel('INITIALISING · CHECKING SESSION'),
                  ),
                  MonoLabel(AppInfoText.version, small: true),
                ],
              ),
              SizedBox(height: AppSpace.sm),
            ],
          ),
        ),
      ),
    );
  }
}
