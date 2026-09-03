// ignore_for_file: use_build_context_synchronously

import 'package:atomic_notes/database/notes_repository.dart';
import 'package:atomic_notes/security/seed_phrase.dart';
import 'package:atomic_notes/security/vault.dart';
import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/my_appbar.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Security -> Encryption.
///
/// Runs the one-time setup: generate a recovery phrase, show it, make the user
/// prove they wrote it down, and only then create the vault. Setup is not
/// finished until the phrase is typed back correctly, because a phrase nobody
/// saved is a vault nobody can reopen.
class EncryptionPage extends StatefulWidget {
  const EncryptionPage({super.key});

  @override
  State<EncryptionPage> createState() => _EncryptionPageState();
}

enum _Step { intro, show, verify }

class _EncryptionPageState extends State<EncryptionPage> {
  _Step _step = _Step.intro;
  List<String> _phrase = const [];
  late List<TextEditingController> _fields;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fields = List.generate(SeedPhrase.wordCount, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String text) =>
      MySnackBar(text: text, sec: 2500).showMySnackBar(context);

  void _generate() {
    setState(() {
      _phrase = SeedPhrase.generate();
      _step = _Step.show;
      _error = null;
    });
  }

  Future<void> _copy() async {
    final phrase = _phrase.join(' ');
    await Clipboard.setData(ClipboardData(text: phrase));
    if (!mounted) return;
    _toast('Copied. It clears from the clipboard in 60s. Writing it down by '
        'hand is safer, since any app can read the clipboard.');
    // Shrink the exposure window: clear it later, but only if it still holds
    // the phrase, so we never wipe something the user copied in the meantime.
    // No context/setState here, so it is safe after dispose.
    Future.delayed(const Duration(seconds: 60), () async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == phrase) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  Future<void> _confirm() async {
    final typed = _fields.map((c) => c.text).toList();
    if (typed.any((w) => w.trim().isEmpty)) {
      setState(() => _error = 'Enter all ${SeedPhrase.wordCount} words.');
      return;
    }
    if (!SeedPhrase.matches(typed, _phrase)) {
      setState(() => _error = 'That does not match the phrase. Check the order.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Vault.instance.createVault(_phrase);
      // Fold every existing plaintext note into the vault.
      await NotesRepository.instance.migrateToVault();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _phrase = const [];
        _step = _Step.intro;
      });
      _toast('Encryption is on. Your notes are now end-to-end encrypted.');
    } on VaultAlreadyExistsError {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'This account already has a vault. Unlock it with your '
            'existing phrase instead of making a new one.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not turn on encryption. Check your connection.';
      });
    }
  }

  Future<void> _lockDevice() async {
    await Vault.instance.lockThisDevice();
    if (!mounted) return;
    setState(() {});
    _toast('Locked on this device. Your phrase is needed to open it here.');
  }

  Widget _pad(Widget c) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenMargin),
      child: c);

  @override
  Widget build(BuildContext context) {
    final vault = Vault.instance;
    final List<Widget> body;
    if (vault.isUnlocked) {
      body = _active();
    } else if (vault.isEnabled) {
      body = _lockedElsewhere();
    } else {
      body = switch (_step) {
        _Step.intro => _intro(),
        _Step.show => _show(),
        _Step.verify => _verify(),
      };
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const MyAppBar(text: "Encryption"),
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.xxl),
        children: [
          ...body,
          if (_error != null) ...[
            const SizedBox(height: AppSpace.md),
            _pad(EditorialModule(
              fill: AppColors.errorContainer,
              padding: const EdgeInsets.all(AppSpace.md),
              child: Text(_error!,
                  style: AppType.bodySm
                      .copyWith(color: AppColors.onErrorContainer)),
            )),
          ],
        ],
      ),
    );
  }

  // ---- vault on, open on this device ------------------------------------
  List<Widget> _active() => [
        _pad(const SectionHeader('ENCRYPTION',
            trailing:
                DataChip('ON', active: true, activeColor: AppColors.signal))),
        const SizedBox(height: AppSpace.md),
        _pad(const EditorialModule(
          accent: true,
          padding: EdgeInsets.all(AppSpace.md),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.verified_user_outlined, color: AppColors.signal),
            SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditorialHeading('Your notes are encrypted',
                      style: AppType.headlineSm),
                  SizedBox(height: AppSpace.xs),
                  Text(
                    'Every note is sealed with AES-256-GCM on this device '
                    'before it is stored or synced. The server only ever holds '
                    'ciphertext it cannot read.',
                    style: AppType.bodySm,
                  ),
                ],
              ),
            ),
          ]),
        )),
        const SizedBox(height: AppSpace.lg),
        _pad(const SectionHeader('THIS DEVICE')),
        const SizedBox(height: AppSpace.md),
        _pad(Text(
          'Locking forgets the key here. Your notes stay encrypted in the '
          'cloud and on your other devices, and this device asks for the '
          'recovery phrase again.',
          style: AppType.bodySm.copyWith(color: AppColors.slateData),
        )),
        const SizedBox(height: AppSpace.md),
        _pad(GhostButton(
            label: 'Lock on this device',
            icon: Icons.lock_outline,
            onTap: _lockDevice)),
      ];

  // ---- vault exists, this device cannot open it -------------------------
  List<Widget> _lockedElsewhere() => [
        _pad(const SectionHeader('ENCRYPTION',
            trailing: DataChip('LOCKED', active: true))),
        const SizedBox(height: AppSpace.md),
        _pad(const EditorialModule(
          padding: EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditorialHeading('Vault locked here',
                  style: AppType.headlineSm),
              SizedBox(height: AppSpace.xs),
              Text(
                'This account already has an encrypted vault. Enter your '
                'recovery phrase to open it on this device. Until then your '
                'encrypted notes stay hidden and new notes are saved '
                'unencrypted.',
                style: AppType.bodySm,
              ),
            ],
          ),
        )),
        const SizedBox(height: AppSpace.md),
        _pad(InkActionButton(
          label: 'Unlock vault',
          signal: true,
          icon: Icons.lock_open_rounded,
          onTap: () => Navigator.pushNamed(context, '/vaultunlock'),
        )),
      ];

  // ---- setup, step 1 ----------------------------------------------------
  List<Widget> _intro() => [
        _pad(const SectionHeader('ENCRYPTION',
            trailing:
                DataChip('OFF', active: true, activeColor: AppColors.outline))),
        const SizedBox(height: AppSpace.md),
        _pad(const EditorialModule(
          padding: EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditorialHeading('End-to-end encryption',
                  style: AppType.headlineSm),
              SizedBox(height: AppSpace.xs),
              Text(
                'Seal every note with AES-256-GCM before it leaves this '
                'device. You get a ${SeedPhrase.wordCount}-word recovery '
                'phrase that unlocks your notes on any device. It is the only '
                'thing that can open them, and it never leaves your device.',
                style: AppType.bodySm,
              ),
            ],
          ),
        )),
        const SizedBox(height: AppSpace.lg),
        _pad(EditorialModule(
          fill: AppColors.errorContainer,
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MonoLabel('READ THIS FIRST',
                  color: AppColors.onErrorContainer),
              const SizedBox(height: AppSpace.sm),
              Text(
                'The recovery phrase is separate from your account password. '
                'Signing in is not enough to read encrypted notes, on purpose. '
                'If you lose the phrase, nobody can recover those notes, '
                'including us. Write it down somewhere safe before you finish.',
                style:
                    AppType.bodySm.copyWith(color: AppColors.onErrorContainer),
              ),
            ],
          ),
        )),
        const SizedBox(height: AppSpace.lg),
        _pad(InkActionButton(
            label: 'Generate recovery phrase',
            signal: true,
            icon: Icons.shield_outlined,
            onTap: _generate)),
      ];

  // ---- setup, step 2 ----------------------------------------------------
  List<Widget> _show() => [
        _pad(const SectionHeader('STEP 1 OF 2 / WRITE IT DOWN')),
        const SizedBox(height: AppSpace.md),
        _pad(const Text(
          'These ${SeedPhrase.wordCount} words are your recovery phrase, in '
          'this order. Write them down now. They are shown once and cannot be '
          'shown again after setup.',
          style: AppType.bodyMd,
        )),
        const SizedBox(height: AppSpace.md),
        _pad(EditorialModule(
          inverted: true,
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _phrase.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.sm),
                    child: HairRule(color: AppColors.slateData),
                  ),
                Row(
                  children: [
                    SizedBox(
                        width: 34,
                        child: MonoLabel('${i + 1}', color: AppColors.signal)),
                    Expanded(
                      child: Text(_phrase[i],
                          style: AppType.headlineSm
                              .copyWith(color: AppColors.onInk)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        )),
        const SizedBox(height: AppSpace.md),
        _pad(GhostButton(
            label: 'Copy phrase', icon: Icons.copy_rounded, onTap: _copy)),
        const SizedBox(height: AppSpace.md),
        _pad(InkActionButton(
          label: 'I wrote it down',
          signal: true,
          onTap: () => setState(() {
            _step = _Step.verify;
            _error = null;
          }),
        )),
      ];

  // ---- setup, step 3 ----------------------------------------------------
  List<Widget> _verify() => [
        _pad(const SectionHeader('STEP 2 OF 2 / CONFIRM')),
        const SizedBox(height: AppSpace.md),
        _pad(const Text(
          'Type the ${SeedPhrase.wordCount} words in order. This confirms you '
          'saved them before encryption is switched on.',
          style: AppType.bodyMd,
        )),
        const SizedBox(height: AppSpace.md),
        for (var i = 0; i < _fields.length; i++)
          _pad(Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Row(
              children: [
                SizedBox(width: 34, child: MonoLabel('${i + 1}', small: true)),
                Expanded(
                  child: TextField(
                    controller: _fields[i],
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: i == _fields.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    cursorColor: AppColors.signal,
                    style: AppType.bodyLg,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.only(top: 10, bottom: 10),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.ink, width: AppStroke.rule),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.signal, width: AppStroke.offset),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        const SizedBox(height: AppSpace.md),
        _pad(InkActionButton(
          label: 'Turn on encryption',
          signal: true,
          icon: Icons.shield_outlined,
          loading: _loading,
          onTap: _confirm,
        )),
        const SizedBox(height: AppSpace.sm),
        _pad(Center(
          child: GhostButton(
            label: 'Back',
            expand: false,
            onTap: _loading ? null : () => setState(() => _step = _Step.show),
          ),
        )),
      ];
}
