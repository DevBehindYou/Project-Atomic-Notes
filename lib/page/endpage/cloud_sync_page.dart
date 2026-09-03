import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/database/sync_status.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:atomic_notes/utility/component/my_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CloudSyncPage extends StatefulWidget {
  const CloudSyncPage({super.key});

  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  late bool isSyncOn;
  @override
  void initState() {
    super.initState();
    isSyncOn = SyncStatusHelper.isSyncOn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const MyAppBar(text: "Cloud Sync"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.md, AppSpace.lg, AppSpace.md, AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live status reads as a system state, not a decorative toggle.
            SectionHeader(
              'SYNC STATUS',
              trailing: DataChip(
                isSyncOn ? 'ON' : 'OFF',
                active: true,
                activeColor: isSyncOn ? AppColors.signal : AppColors.outline,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            EditorialModule(
              accent: isSyncOn,
              padding: const EdgeInsets.all(AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EditorialHeading('Cloud sync',
                            style: AppType.headlineSm),
                        SizedBox(height: AppSpace.xs),
                        Text(
                          "Turn this off and notes stay on this device only.",
                          style: AppType.bodySm,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  // switch
                  CupertinoSwitch(
                    value: isSyncOn,
                    // activeColor was deprecated after Flutter 3.24.
                    activeTrackColor: AppColors.signal,
                    onChanged: (bool value) async {
                      setState(() {
                        isSyncOn = value;
                      });
                      // Save sync status using the helper class
                      await SyncStatusHelper.setSyncStatus(value);
                      if (!context.mounted) return;
                      // No restart needed any more: the sync button reads this
                      // flag at the moment it's tapped. This used to show
                      // "Restarting the app in 5 sec..." and then call exit(0)
                      // — which doesn't restart anything, looks like a crash,
                      // and is an App Store rejection reason on iOS.
                      MySnackBar(
                        text: value
                            ? "Cloud Synchronization On"
                            : "Cloud Synchronization Off",
                        sec: 2000,
                      ).showMySnackBar(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            const MonoLabel('NOTE'),
            const SizedBox(height: AppSpace.sm),
            const HairRule(),
            const SizedBox(height: AppSpace.sm),
            const Text(
              "Notes data will be stored in the Atomic cloud database. "
              "This takes effect immediately — no restart needed.",
              style: AppType.bodySm,
            ),
          ],
        ),
      ),
    );
  }
}
