// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:atomic_notes/database/notes_repository.dart';
import 'package:atomic_notes/utility/component/danger_tiles.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/my_appbar.dart';
import 'package:flutter/material.dart';

class DevPage extends StatelessWidget {
  const DevPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = NotesRepository.instance;

    // dev options function
    Future<void> forceFetchNotes() async {
      final ok = await repo.syncNow();
      if (context.mounted) {
        MySnackBar(
          text: ok
              ? "Synced with the cloud"
              : "Sync failed — check your connection",
          sec: 2000,
        ).showMySnackBar(context);
      }
    }

    // dev options function
    Future<void> deleteLocalData() async {
      await repo.clearLocal();
      if (context.mounted) {
        const MySnackBar(
          text: "Local data deleted successfully",
          sec: 2000,
        ).showMySnackBar(context);
      }
    }

    // dev options function
    Future<void> deleteCloudData() async {
      String response = await repo.wipeRemote();
      if (context.mounted) {
        MySnackBar(
          text: response,
          sec: 2000,
        ).showMySnackBar(context);
      }
    }

    return Scaffold(
      appBar: const MyAppBar(text: "Developer Options"),
      backgroundColor: AppColors.paper,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.md, AppSpace.lg, AppSpace.md, AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Danger zone, marked by an error-coloured border rather than a
            // black slab — the one place the system allows a loud outline.
            const SectionHeader('DANGER ZONE'),
            const SizedBox(height: AppSpace.sm),
            Text(
              'These actions run immediately and cannot be undone.',
              style: AppType.bodySm.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpace.md),
            Container(
              padding: const EdgeInsets.all(AppSpace.sm + 2),
              decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: AppRadius.std,
                  border: Border.all(
                      width: AppStroke.hairline, color: AppColors.error)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // fetch data
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: DangerTile(
                      func: forceFetchNotes,
                      text: "SYNC WITH CLOUD",
                      txt:
                          "Push local changes and pull everything this account has in the cloud.",
                    ),
                  ),
                  // delete data
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: DangerTile(
                      func: deleteCloudData,
                      text: "DELETE CLOUD DATA",
                      txt:
                          "Are you sure you want to delete your notes stored in the cloud?\nWarning: By doing so, it will empty your notes data in the cloud",
                    ),
                  ),

                  // destroy local data
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: DangerTile(
                      func: deleteLocalData,
                      text: "DELETE LOCAL DATA",
                      txt:
                          "Are you sure you want to delete notes from local storage?\nWarning: By doing so, it will delete all notes stored in the local data storage.",
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
