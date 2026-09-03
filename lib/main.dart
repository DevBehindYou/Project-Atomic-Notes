import 'dart:async';

import 'package:atomic_notes/authentication/auth_pages/login_page.dart';
import 'package:atomic_notes/authentication/auth_pages/reset_password_page.dart';
import 'package:atomic_notes/authentication/auth_pages/reset_verify_page.dart';
import 'package:atomic_notes/authentication/auth_pages/signup_verify_page.dart';
import 'package:atomic_notes/authentication/auth_services/cred.dart';
import 'package:atomic_notes/authentication/auth_services/session_guard.dart';
import 'package:atomic_notes/database/note_quota.dart';
import 'package:atomic_notes/database/notes_repository.dart';
import 'package:atomic_notes/database/sync_status.dart';
import 'package:atomic_notes/security/vault.dart';
import 'package:atomic_notes/page/endpage/about_us_page.dart';
import 'package:atomic_notes/page/endpage/bio_auth_page.dart';
import 'package:atomic_notes/page/endpage/cloud_sync_page.dart';
import 'package:atomic_notes/page/endpage/dev_page.dart';
import 'package:atomic_notes/page/endpage/encryption_page.dart';
import 'package:atomic_notes/page/endpage/energy_page.dart';
import 'package:atomic_notes/page/endpage/vault_unlock_page.dart';
import 'package:atomic_notes/page/endpage/edit_profile_page.dart';
import 'package:atomic_notes/page/endpage/t_and_c_page.dart';
import 'package:atomic_notes/page/home_page.dart';
import 'package:atomic_notes/page/endpage/lock_screen.dart';
import 'package:atomic_notes/page/logout_screen.dart';
import 'package:atomic_notes/page/main_page.dart';
import 'package:atomic_notes/page/endpage/notes_database_page.dart';
import 'package:atomic_notes/page/endpage/notifications_page.dart';
import 'package:atomic_notes/page/settings_page.dart';
import 'package:atomic_notes/page/splash_screen.dart';
import 'package:atomic_notes/theme/app_theme.dart';
import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/intropages/onboarding_screen.dart';
import 'package:atomic_notes/utility/intropages/energy_intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  final CredService cred = CredService();
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Bounded so startup can't hang forever. Session recovery reads local
    // storage, but an *expired* token makes it attempt a refresh — and with
    // no network that request would otherwise sit there and the app would
    // never paint. Failing visibly after 15s beats freezing on a blank screen.
    try {
      await Supabase.initialize(
        url: cred.PROJECT_URL,
        // `anonKey` is deprecated in favour of `publishableKey`. Both are sent
        // as the same `apikey` header, so the existing legacy anon JWT in
        // cred.dart keeps working unchanged.
        publishableKey: cred.API_KEY,
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      // Local-first: a slow or absent network must never block startup. The
      // client is created synchronously inside initialize; only background
      // work (session refresh) can stall. Continue so local notes always open.
      debugPrint('Supabase.initialize slow/offline; continuing local-first: $e');
    }

    await Hive.initFlutter();
    // open the Hive Boxes. These stay open for the life of the process —
    // individual screens must not close them (see splash_screen.dart).
    await Hive.openBox<bool>('authBox');
    await Hive.openBox<bool>('syncBox');
    await SyncStatusHelper.init();
    await NoteQuota.init();
    // Determine encryption state and auto-unlock from a cached key (if any)
    // before the repository loads, so encrypted notes can be decrypted on load.
    await Vault.instance.init();
    await NotesRepository.instance.init();
  } catch (error) {
    // This used to be `exit(0)`: the app vanished on launch with no message,
    // indistinguishable from a crash and impossible to report.
    runApp(StartupFailedApp(error: error.toString()));
    return;
  }

  runApp(const MyApp());
}

/// Shown when Supabase or Hive can't be initialised at all. There is no usable
/// app behind this point, so it just explains itself instead of disappearing.
class StartupFailedApp extends StatelessWidget {
  final String error;
  const StartupFailedApp({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MonoLabel('SYSTEM / STARTUP FAILED',
                      color: AppColors.error),
                  const SizedBox(height: AppSpace.sm),
                  const HairRule(color: AppColors.ink),
                  const SizedBox(height: AppSpace.lg),
                  const EditorialHeading(
                    "Atomic couldn't start",
                    style: AppType.headlineLg,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  const Text(
                    'Check your connection and reopen the app. If this keeps '
                    'happening, the details below will say why.',
                    style: AppType.bodyMd,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  EditorialModule(
                    fill: AppColors.errorContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MonoLabel('TRACE',
                            color: AppColors.onErrorContainer),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          error,
                          style: AppType.labelMonoSm
                              .copyWith(color: AppColors.onErrorContainer),
                        ),
                      ],
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Start the central auth-state guard once, for the life of the app. It
    // owns the sign-out -> reset-to-login transition from anywhere.
    SessionGuard.attach();
  }

  @override
  void dispose() {
    SessionGuard.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Shared with SessionGuard so a sign-out can reset the stack even when it
      // happens off-screen (a background token refresh failing).
      navigatorKey: SessionGuard.navigatorKey,
      initialRoute: '/splashpage',
      routes: {
        '/loginpage': (context) => const LoginPage(),
        '/homepage': (context) => const HomePage(),
        '/splashpage': (context) => const SplashPage(),
        '/loggedout': (context) => const LoggedOutScreen(),
        '/mainpage': (context) => const MainPage(),
        '/settingspage': (context) => const SettingsPage(),
        '/resetpage': (context) => const ResetPassword(),
        '/resetverify': (context) => ResetVerifyPage(
              email: ModalRoute.of(context)?.settings.arguments as String? ?? '',
            ),
        '/signupverify': (context) => SignupVerifyPage(
              email: ModalRoute.of(context)?.settings.arguments as String? ?? '',
            ),
        '/onboardingscreen': (context) => const OnBoardingScreen(),
        '/energyintro': (context) => const EnergyIntroScreen(),
        '/appinfo': (context) => const AppInfo(),
        '/lockscreen': (context) => const LockScreen(),
        '/devoption': (context) => const DevPage(),
        '/databasepage': (context) => const DatabasePage(),
        '/cloudsyncpage': (context) => const CloudSyncPage(),
        '/biompage': (context) => const BiomPage(),
        '/encryptionpage': (context) => const EncryptionPage(),
        '/energypage': (context) => const EnergyPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/vaultunlock': (context) => VaultUnlockPage(
              // `arguments: true` means the splash sent the user here at
              // launch, so unlocking continues into the app.
              fromStartup:
                  ModalRoute.of(context)?.settings.arguments == true,
            ),
        '/tcpage': (context) => const TCPage(),
        '/editprofilepage': (context) => const EditProfilePage(),
      },
    );
  }
}
