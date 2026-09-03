// ignore_for_file: use_build_context_synchronously

import 'package:atomic_notes/database/notes_repository.dart';
import 'package:atomic_notes/security/seed_phrase.dart';
import 'package:atomic_notes/security/vault.dart';
import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/logo_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shown when the account has a vault this device cannot open yet.
///
/// Reachable two ways: the splash routes here at launch, and Settings offers it
/// explicitly. Either way the user can skip it: signing in still gives them
/// their unencrypted notes, which is the whole point of keeping the account
/// password and the recovery phrase as separate boundaries.
class VaultUnlockPage extends StatefulWidget {
  /// True when the splash sent the user here at launch, so unlocking should
  /// continue into the app rather than pop back to Settings.
  final bool fromStartup;

  const VaultUnlockPage({this.fromStartup = false, super.key});

  @override
  State<VaultUnlockPage> createState() => _VaultUnlockPageState();
}

class _VaultUnlockPageState extends State<VaultUnlockPage> {
  late List<TextEditingController> _fields;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fields =
        List.generate(SeedPhrase.wordCount, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  /// Let the user paste the whole phrase into the first field.
  void _spread(String value) {
    final parts = SeedPhrase.split(value);
    if (parts.length < 2) return;
    for (var i = 0; i < _fields.length; i++) {
      _fields[i].text = i < parts.length ? parts[i] : '';
    }
    setState(() {});
  }

  Future<void> _unlock() async {
    final typed = _fields.map((c) => c.text).toList();
    if (typed.any((w) => w.trim().isEmpty)) {
      setState(() => _error = 'Enter all ${SeedPhrase.wordCount} words.');
      return;
    }
    final unknown = SeedPhrase.unknownWords(typed);
    if (unknown.isNotEmpty) {
      setState(() => _error =
          'Not from the word list: ${unknown.join(', ')}. Check the spelling.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await Vault.instance.unlock(
        typed,
        sampleCiphertext: NotesRepository.instance.sampleCiphertext,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _loading = false;
          _error = 'That phrase did not open the vault. Check the words and '
              'their order.';
        });
        return;
      }
      // Decrypt what is already here, pull the rest, fold in plaintext notes.
      await NotesRepository.instance.reloadAfterUnlock();
      if (!mounted) return;
      if (widget.fromStartup) {
        Navigator.pushReplacementNamed(context, '/splashpage');
      } else {
        Navigator.pop(context);
      }
    } on VaultUnverifiableError {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Connect to the internet to unlock on this device the first '
            'time.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not unlock. Please try again.';
      });
    }
  }

  void _skip() {
    if (widget.fromStartup) {
      Navigator.pushReplacementNamed(context, '/mainpage');
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenMargin, AppSpace.xl,
              AppSpace.screenMargin, AppSpace.xxl),
          children: [
            const LogoContainer(showTagline: false),
            const SizedBox(height: AppSpace.xl),
            const MonoLabel('VAULT LOCKED', color: AppColors.signal),
            const SizedBox(height: AppSpace.sm),
            const HairRule(color: AppColors.ink),
            const SizedBox(height: AppSpace.lg),
            const EditorialHeading(
              'Enter your\nrecovery phrase.',
              style: AppType.displayLg,
            ),
            const SizedBox(height: AppSpace.sm),
            const Text(
              'Your encrypted notes are protected on this device. Enter the '
              '${SeedPhrase.wordCount} words you saved to unlock them. They '
              'are checked on this device and never sent anywhere.',
              style: AppType.bodyMd,
            ),
            const SizedBox(height: AppSpace.lg),
            for (var i = 0; i < _fields.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Row(
                  children: [
                    SizedBox(
                        width: 34, child: MonoLabel('${i + 1}', small: true)),
                    Expanded(
                      child: TextField(
                        controller: _fields[i],
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'[^a-zA-Z ]'))
                        ],
                        textInputAction: i == _fields.length - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        cursorColor: AppColors.signal,
                        style: AppType.bodyLg,
                        onChanged: _spread,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.only(top: 10, bottom: 10),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.ink, width: AppStroke.rule),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.signal,
                                width: AppStroke.offset),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.md),
              EditorialModule(
                fill: AppColors.errorContainer,
                padding: const EdgeInsets.all(AppSpace.md),
                child: Text(_error!,
                    style: AppType.bodySm
                        .copyWith(color: AppColors.onErrorContainer)),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            InkActionButton(
              label: 'Unlock vault',
              signal: true,
              icon: Icons.lock_open_rounded,
              loading: _loading,
              onTap: _unlock,
            ),
            const SizedBox(height: AppSpace.md),
            Center(
              child: GhostButton(
                label: widget.fromStartup ? 'Skip for now' : 'Cancel',
                expand: false,
                onTap: _loading ? null : _skip,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              'Skipping still gets you your unencrypted notes. Encrypted notes '
              'stay hidden until you enter the phrase. Nobody can reset it for '
              'you, so never share it with anyone.',
              style: AppType.bodySm.copyWith(color: AppColors.slateData),
            ),
          ],
        ),
      ),
    );
  }
}
