// ignore_for_file: use_build_context_synchronously, prefer_final_fields, deprecated_member_use

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/authentication/auth_services/auth_service.dart';
import 'package:atomic_notes/database/notes_repository.dart';
import 'package:atomic_notes/database/sync_status.dart';
import 'package:atomic_notes/security/vault.dart';
import 'package:atomic_notes/utility/component/logo_container.dart';
import 'package:atomic_notes/utility/component/logout_dialogbox.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:atomic_notes/utility/component/profile_container.dart';
import 'package:atomic_notes/utility/app_info.dart';
import 'package:atomic_notes/utility/component/settings_tiles.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String? userId = supabase.auth.currentUser!.email;
  final supabase = Supabase.instance.client;
  final AuthServices serve = AuthServices();
  final NotesRepository repo = NotesRepository.instance;
  bool _isLoading = false;
  String? username = "@atomicuser";
  bool _isMounted = true;

  @override
  void dispose() {
    _isMounted = false;
    _isLoading = false;
    super.dispose();
  }

  _showPopUp({required String txt, required Function func}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return DialogBoxLogout(
          action: func,
          text: txt,
        );
      },
    );
  }

  //logout function
  Future<void> _logOut() async {
    if (!_isMounted) return;

    setState(() {
      _isLoading = true;
    });
    try {
      // Flush anything unpushed BEFORE wiping the local cache. Logout clears
      // the device copy, so an unsynced note would otherwise be gone for good.
      if (repo.pendingCount > 0) {
        if (!SyncStatusHelper.isSyncOn) {
          // Don't push their notes to a cloud they explicitly opted out of —
          // but don't erase them either. Refusing with an actionable message
          // is the only option here that can't lose data.
          if (!_isMounted) return;
          const MySnackBar(
            text: "Turn on Cloud Synchronization and sync first — "
                "logging out erases the notes on this device",
            sec: 4000,
          ).showMySnackBar(context);
          return;
        }
        final synced = await repo.syncNow();
        if (!synced) {
          if (!_isMounted) return;
          const MySnackBar(
            text: "Logout cancelled — your notes could not be backed up",
            sec: 3000,
          ).showMySnackBar(context);
          return;
        }
      }
      await repo.stop();
      await repo.clearLocal();
      final authBox = await Hive.openBox<bool>('authBox');
      await authBox.put('isAuthOn', false);
      await SyncStatusHelper.setSyncStatus(true);
      // Wipe the encryption key from this device before the session ends.
      await Vault.instance.clearLocal();
      // End the session. Logout must never be blocked by the network: if the
      // server can't be reached, still sign out locally so the app cannot stay
      // authenticated. Either path emits signedOut, and SessionGuard is what
      // tears down remaining state and resets the stack to the login screen.
      try {
        await supabase.auth.signOut();
      } catch (_) {
        await supabase.auth.signOut(scope: SignOutScope.local);
      }
    } catch (error) {
      if (!_isMounted) return;
      const MySnackBar(
        text: "Unable to logout",
        sec: 2000,
      ).showMySnackBar(context);
    } finally {
      if (_isMounted) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EditorialHeading('Settings', style: AppType.headlineLg),
            const SizedBox(height: AppSpace.xs),
            // The signed-in address, as mono metadata rather than a pill.
            MonoLabel(userId ?? '—'),
            const SizedBox(height: AppSpace.md),
            const HairRule(color: AppColors.ink),
            const SizedBox(height: AppSpace.md),

            // logout button section
            ProConatainer(
              isLoading: _isLoading,
              logout: () => _showPopUp(
                  txt:
                      "Are you sure you want to log out? Before you log out, make sure to backup or sync your notes data to the cloud by tapping on cloud sync button",
                  func: _logOut),
            ),
            const SizedBox(height: AppSpace.lg),
            const SectionHeader('MANAGE'),

            // profile page section
            SettingsTiles(
              action: () {
                Navigator.pushNamed(context, '/editprofilepage');
              },
              text: "Profile",
            ),

            // notes database section
            SettingsTiles(
              action: () {
                Navigator.pushNamed(context, '/databasepage');
              },
              text: "Notes Database",
            ),

            // clous sync switch
            SettingsTiles(
              action: () {
                Navigator.pushNamed(context, '/cloudsyncpage');
              },
              text: "Cloud Synchronization",
            ),

            // bio auth switch
            SettingsTiles(
              action: () {
                Navigator.pushNamed(context, '/biompage');
              },
              text: "Security",
            ),

            // end-to-end encryption
            SettingsTiles(
              action: () {
                Navigator.pushNamed(context, '/encryptionpage');
              },
              text: "Encryption",
            ),

            // atomic energy + coins
            SettingsTiles(
              action: () {
                Navigator.pushNamed(context, '/energypage');
              },
              text: "Atomic Energy",
            ),

            // develpoper option section
            SettingsTiles(
              action: () {
                Navigator.pushNamed(context, '/devoption');
              },
              text: "More Options",
            ),
            const SizedBox(height: AppSpace.xl),

            //logo section
            const LogoContainer(),
            const SizedBox(height: AppSpace.xl),

            // Colophon: inverted module, the system's way of closing a page.
            EditorialModule(
              inverted: true,
              padding: const EdgeInsets.all(AppSpace.md + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MonoLabel('ABOUT ATOMIC', color: AppColors.signal),
                  const SizedBox(height: AppSpace.sm),
                  EditorialHeading(
                    'Local-first notes',
                    style: AppType.headlineMd.copyWith(color: AppColors.paper),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    AppInfoText.versionLabel,
                    style: AppType.labelMonoSm
                        .copyWith(color: AppColors.outlineVariant),
                  ),
                  Text(
                    AppInfoText.copyright,
                    style: AppType.labelMonoSm
                        .copyWith(color: AppColors.outlineVariant),
                  ),
                  const SizedBox(height: AppSpace.md),
                  ArrowLink(
                    'App info',
                    onTap: () => Navigator.pushNamed(context, '/appinfo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),
          ],
        ),
      ),
    );
  }
}
