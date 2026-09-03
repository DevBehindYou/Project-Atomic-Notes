// ignore_for_file: use_build_context_synchronously

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:atomic_notes/database/notes_repository.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:atomic_notes/utility/component/my_appbar.dart';
import 'package:atomic_notes/utility/component/logout_dialogbox.dart';
import 'package:flutter/material.dart';

class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key});

  @override
  State<DatabasePage> createState() => _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {
  final NotesRepository repo = NotesRepository.instance;
  int localNotesNum = 0;
  String cloudNotes = '-';
  bool _mounted = true;
  String synctime = '-';

  @override
  void initState() {
    _getDBLocalNum();
    super.initState();
  }

  Future<void> _getData() async {
    if (!_mounted) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (!_mounted) return; // Check again before updating state
    // (There was a `setState(() { connectivityResult; })` here — an empty
    // rebuild triggered by an expression statement that did nothing.)
    if (connectivityResult.contains(ConnectivityResult.none)) {
      const MySnackBar(
        text: "No Internet Connection!",
        sec: 1000,
      ).showMySnackBar(context);
    } else {
      // Per-note rows now, so this is a real count rather than "is there a
      // blob: yes/no".
      await repo.syncNow();
      final remote = await repo.remoteCount();
      if (!_mounted) return;
      setState(() {
        cloudNotes = remote.toString();
        localNotesNum = repo.count;
        synctime = repo.lastSyncedAt == null
            ? 'Never'
            : _stamp(repo.lastSyncedAt!);
      });
    }
  }

  void _getDBLocalNum() {
    if (_mounted) {
      setState(() {
        localNotesNum = repo.count;
      });
    }
  }

  static String _stamp(DateTime d) {
    final l = d.toLocal();
    String p(int v) => v.toString().padLeft(2, '0');
    return '${l.year}-${p(l.month)}-${p(l.day)} ${p(l.hour)}:${p(l.minute)}';
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

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const MyAppBar(text: "Database"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.lg,
            AppSpace.md, AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('STORAGE REPORT'),
            const SizedBox(height: AppSpace.md),

            // Stat modules: big Bebas numeral, mono caption. The reference's
            // "bento stats" pattern.
            Row(
              children: [
                Expanded(
                  child: _StatModule(
                    value: localNotesNum.toString(),
                    caption: 'NOTES ON DEVICE',
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: _StatModule(
                    value: cloudNotes,
                    caption: 'NOTES IN CLOUD',
                    accent: cloudNotes != '-' && cloudNotes != '0',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            EditorialModule(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: MonoLabel('LAST BACKUP')),
                  Flexible(
                    child: Text(
                      synctime,
                      textAlign: TextAlign.right,
                      style: AppType.bodyMedium15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),

            InkActionButton(
              label: 'Reload data',
              icon: Icons.refresh,
              onTap: () => _showPopUp(
                txt: "Count how many notes are stored in the cloud database.",
                func: _getData,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            const HairRule(),
            const SizedBox(height: AppSpace.md),
            const Text(
              "This will provide you details about the notes that are stored "
              "in both your app's local storage and the cloud database. Tap on "
              "the reload button to refresh the data.",
              style: AppType.bodySm,
            ),
          ],
        ),
      ),
    );
  }
}

/// Big numeral + mono caption in a thin-bordered module.
class _StatModule extends StatelessWidget {
  final String value;
  final String caption;
  final bool accent;
  const _StatModule({
    required this.value,
    required this.caption,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return EditorialModule(
      padding: const EdgeInsets.all(AppSpace.md),
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppType.statNumber.copyWith(
              color: accent ? AppColors.signal : AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          MonoLabel(caption, small: true),
        ],
      ),
    );
  }
}
