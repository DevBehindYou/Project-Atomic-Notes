// ignore_for_file: use_build_context_synchronously, use_super_parameters


import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:atomic_notes/authentication/auth_services/auth_service.dart';
import 'package:atomic_notes/database/energy_service.dart';
import 'package:atomic_notes/database/notification_service.dart';
import 'package:atomic_notes/database/notes_repository.dart';
import 'package:atomic_notes/database/sync_status.dart';
import 'package:atomic_notes/page/home_page.dart';
import 'package:atomic_notes/page/settings_page.dart';
import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/intropages/energy_intro_screen.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:atomic_notes/utility/component/cloud_button.dart';
import 'package:atomic_notes/utility/component/energy_popup.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final supabase = Supabase.instance.client;
  final AuthServices serve = AuthServices();
  final NotesRepository repo = NotesRepository.instance;
  String? username = "@atomicuser";
  bool _isLoading = false;
  bool _isLoading2 = false;
  int currentIndex = 0;

  // Explicitly List<Widget>. As a bare `List` this is List<dynamic>, which the
  // old `body: _pages[currentIndex]` accepted (dynamic -> Widget is an
  // implicit downcast) but IndexedStack's `children` does not — so switching
  // to IndexedStack turned this into a hard compile error.
  final List<Widget> _pages = [
    // home page
    const HomePage(),

    // settings page
    const SettingsPage(),
  ];

  @override
  void initState() {
    // Sign-out handling lives in SessionGuard now, not per screen — the shell
    // used to push a replacement route here, which left itself alive underneath
    // the login page so Back walked straight back into the authenticated app.
    _getUserName();
    super.initState();
    _maybeShowEnergyIntro();
  }

  /// Show the Atomic Energy feature tour once, the first time the home screen
  /// is reached after this update. This is the universal post-auth landing
  /// (biometric/vault gates route here too), so hooking it here covers every
  /// entry path. Pushed (not replaced) so it pops back to the notes screen.
  void _maybeShowEnergyIntro() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      bool seen;
      try {
        seen = Hive.box<bool>('authBox')
                .get(EnergyIntroScreen.seenFlag, defaultValue: false) ??
            false;
      } catch (_) {
        seen = true; // if the box isn't ready, don't nag; skip this launch
      }
      if (!seen && mounted) {
        Navigator.of(context).pushNamed('/energyintro');
      }
    });
  }

  // get the user name
  Future<void> _getUserName() async {
    if (!mounted) return;
    setState(() {
      _isLoading2 = true;
    });

    try {
      username = await serve.getUserInfo();
    } catch (e) {
      // error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading2 = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isLoading = false;
    _isLoading2 = false;
    super.dispose();
  }

  // sync notes data to cloud
  Future<void> _syncData() async {
    // Read the flag at point of use rather than caching it in initState.
    // The cached copy went stale as soon as the user toggled cloud sync on
    // the settings screen, which is why that screen used to kill the process
    // with exit(0) to force a "restart".
    if (SyncStatusHelper.isSyncOn) {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      if (connectivityResult.contains(ConnectivityResult.none)) {
        const MySnackBar(
          text: "No Internet Connection!",
          sec: 1000,
        ).showMySnackBar(context);
      } else {
        // Manual button = INSTANT sync (10 energy). The energy gate lives inside
        // syncNow: it charges only when there are changes to upload, and refuses
        // when the balance is short. Automatic/background syncs go through the
        // same gate at the standard cost (5).
        final hadPending = repo.pendingCount > 0;
        final ok = await repo.syncNow(instant: true);
        if (!mounted) return;
        MySnackBar(
          text: ok
              ? (hadPending
                  ? "Instant sync  ·  -${EnergyService.syncInstantCost} energy"
                  : "Already up to date")
              : (repo.lastError ??
                  "Sync failed — changes are still only on this device"),
          sec: ok ? 1600 : 3000,
        ).showMySnackBar(context);
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } else {
      const MySnackBar(sec: 1000, text: "Cloud Synchronization is Off")
          .showMySnackBar(context);
    }
  }

  void goToPage(index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: AppSpace.md,
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Masthead: avatar in an Ink frame, mono account line. Tap to refresh
        // the username, same as before.
        title: GestureDetector(
          onTap: () {
            _getUserName();
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 34,
                width: 34,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: AppRadius.std,
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.sm,
                  child: Image.asset('assets/photo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: AppSpace.sm + 2),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                ),
                child: _isLoading2
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 8,
                            width: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceHighest,
                              borderRadius: AppRadius.sm,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 11,
                            width: 88,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceHighest,
                              borderRadius: AppRadius.sm,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MonoLabel('ATOMIC', small: true),
                          Text(
                            username!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.headlineSm.copyWith(height: 1.1),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        actions: [
          const _NotificationBell(),
          const SizedBox(width: AppSpace.sm),
          // Tap = sync (unchanged). Long-press = Atomic Energy popup.
          GestureDetector(
            onLongPress: () => showEnergyPopup(context),
            child: CloudButton(
              ico: "assets/sync.svg",
              action: _syncData,
              clr: 0xff5F5EF7,
              isLoading: _isLoading,
            ),
          ),
          const SizedBox(width: AppSpace.md),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(AppStroke.rule),
          child: HairRule(color: AppColors.ink),
        ),
      ),
      // pages to show in body — IndexedStack keeps both pages'
      // State alive (scroll position, loaded notes list) instead of
      // destroying and rebuilding them every time the tab changes.
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),

      // bottom Navigation bar section — the active tab becomes a solid Ink
      // block, which is how the reference marks the current nav item.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(
            top: BorderSide(color: AppColors.ink, width: AppStroke.rule),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md, vertical: AppSpace.sm + 2),
            child: GNav(
              mainAxisAlignment: MainAxisAlignment.center,
              onTabChange: (index) => goToPage(index),
              backgroundColor: AppColors.paper,
              color: AppColors.slateData,
              activeColor: AppColors.paper,
              tabBackgroundColor: AppColors.ink,
              rippleColor: AppColors.surfaceHighest,
              hoverColor: AppColors.surfaceHigh,
              iconSize: 18,
              gap: AppSpace.sm,
              tabBorderRadius: 4,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md, vertical: 12),
              tabs: const [
                GButton(
                  icon: Icons.article_outlined,
                  text: 'NOTES',
                  textStyle: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.9,
                    color: AppColors.paper,
                  ),
                ),
                GButton(
                  icon: Icons.tune,
                  text: 'SETTINGS',
                  textStyle: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.9,
                    color: AppColors.paper,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App-bar bell with an unread badge; opens the Notification Center. Rebuilds
/// with the feed so the badge stays live.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NotificationService.instance,
      builder: (context, _) {
        final count = NotificationService.instance.unreadCount;
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/notifications'),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 38,
                width: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: AppRadius.std,
                  border:
                      Border.all(color: AppColors.ink, width: AppStroke.rule),
                ),
                child: const Icon(Icons.notifications_none,
                    size: 20, color: AppColors.ink),
              ),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: AppColors.signal,
                      borderRadius: AppRadius.chip,
                      border: Border.all(
                          color: AppColors.paper, width: AppStroke.rule),
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      textAlign: TextAlign.center,
                      style: AppType.labelMonoSm
                          .copyWith(color: Colors.white, height: 1.1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
