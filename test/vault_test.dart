import 'dart:convert';

import 'package:atomic_notes/security/seed_phrase.dart';
import 'package:atomic_notes/security/vault_crypto.dart';
import 'package:atomic_notes/security/wordlist.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the primitives behind end-to-end encryption.
/// Run with: flutter test test/vault_test.dart
///
/// KDF parameters here are deliberately tiny so the suite stays fast; the app
/// uses the strong parameters in [Vault].
const int _mem = 1024;
const int _iter = 1;
const int _par = 1;

Future<SecretKey> _key(String phrase, String userId) async {
  final salt = await VaultCrypto.saltForUser(userId);
  return VaultCrypto.deriveKey(phrase, salt,
      memory: _mem, iterations: _iter, parallelism: _par);
}

void main() {
  group('content encryption', () {
    test('a note seals and re-opens', () async {
      final key = await VaultCrypto.aes.newSecretKey();
      final content = {
        'title': 'Bank login',
        'body': 'the body has a secret: hunter2',
        'items': [
          {'t': 'rotate password', 'd': true},
        ],
      };

      final sealed = await VaultCrypto.sealJson(content, key);
      expect(sealed.contains('hunter2'), isFalse);
      expect(sealed.contains('Bank login'), isFalse);

      final opened = await VaultCrypto.openJson(sealed, key);
      expect(opened['title'], 'Bank login');
      expect(opened['body'], 'the body has a secret: hunter2');
      expect((opened['items'] as List).first['d'], true);
    });

    test('a wrong key fails authentication instead of returning garbage',
        () async {
      final key = await VaultCrypto.aes.newSecretKey();
      final other = await VaultCrypto.aes.newSecretKey();
      final sealed = await VaultCrypto.seal(utf8.encode('secret'), key);

      expect(() => VaultCrypto.open(sealed, other),
          throwsA(isA<SecretBoxAuthenticationError>()));
    });

    test('every seal uses a fresh nonce', () async {
      final key = await VaultCrypto.aes.newSecretKey();
      final a = await VaultCrypto.seal(utf8.encode('same input'), key);
      final b = await VaultCrypto.seal(utf8.encode('same input'), key);
      expect(a, isNot(equals(b)));
    });
  });

  group('key derivation', () {
    // The regression test for the multi-device bug. The old design generated a
    // random key at setup and only shared a wrapped copy, so running setup on a
    // second device produced a DIFFERENT key for the same phrase and each
    // device could read only its own notes. Derivation is now a pure function
    // of (phrase, account id), so this must hold.
    test('the same phrase and account derive the same key on any device',
        () async {
      const phrase = 'ocean tiger maple copper';
      const user = '2b9d4e6a-0000-4000-8000-1234567890ab';

      final deviceA = await _key(phrase, user);
      final deviceB = await _key(phrase, user);

      expect(await deviceA.extractBytes(), await deviceB.extractBytes());
    });

    test('a note sealed on one device opens on another', () async {
      const phrase = 'ocean tiger maple copper';
      const user = '2b9d4e6a-0000-4000-8000-1234567890ab';

      final sealed = await VaultCrypto.sealJson(
          {'title': 'from phone one', 'body': 'hello', 'items': const []},
          await _key(phrase, user));

      final opened =
          await VaultCrypto.openJson(sealed, await _key(phrase, user));
      expect(opened['title'], 'from phone one');
    });

    test('a different account derives a different key', () async {
      const phrase = 'ocean tiger maple copper';
      final a = await _key(phrase, 'aaaaaaaa-0000-4000-8000-000000000001');
      final b = await _key(phrase, 'bbbbbbbb-0000-4000-8000-000000000002');
      expect(await a.extractBytes(), isNot(equals(await b.extractBytes())));
    });

    test('a different phrase derives a different key', () async {
      const user = '2b9d4e6a-0000-4000-8000-1234567890ab';
      final a = await _key('ocean tiger maple copper', user);
      final b = await _key('ocean tiger maple silver', user);
      expect(await a.extractBytes(), isNot(equals(await b.extractBytes())));
    });

    test('the salt is stable for an account and unique across accounts',
        () async {
      final a1 = await VaultCrypto.saltForUser('user-one');
      final a2 = await VaultCrypto.saltForUser('user-one');
      final b = await VaultCrypto.saltForUser('user-two');
      expect(a1, equals(a2));
      expect(a1, isNot(equals(b)));
      expect(a1.length, 32);
    });
  });

  group('verifier', () {
    test('the right phrase verifies and a wrong one does not', () async {
      const user = '2b9d4e6a-0000-4000-8000-1234567890ab';
      final real = await _key('ocean tiger maple copper', user);
      final verifier = await VaultCrypto.makeVerifier(real);

      expect(await VaultCrypto.checkVerifier(verifier, real), isTrue);

      final wrong = await _key('ocean tiger maple walnut', user);
      expect(await VaultCrypto.checkVerifier(verifier, wrong), isFalse);
    });

    test('the verifier does not leak the phrase or the key', () async {
      const phrase = 'ocean tiger maple copper';
      final key = await _key(phrase, 'u1');
      final verifier = await VaultCrypto.makeVerifier(key);
      for (final w in phrase.split(' ')) {
        expect(verifier.contains(w), isFalse);
      }
      expect(verifier.contains(VaultCrypto.verifierPlaintext), isFalse);
    });
  });

  group('recovery phrase', () {
    test('the word list is exactly 1024 unique lowercase words', () {
      expect(kWordList.length, 1024);
      expect(kWordList.toSet().length, 1024);
      for (final w in kWordList) {
        expect(RegExp(r'^[a-z]{3,12}$').hasMatch(w), isTrue,
            reason: 'bad word: $w');
      }
    });

    test('a generated phrase has the right length and only listed words', () {
      final p = SeedPhrase.generate();
      expect(p.length, SeedPhrase.wordCount);
      expect(SeedPhrase.unknownWords(p), isEmpty);
    });

    test('generation is random, not a fixed phrase', () {
      final seen = <String>{};
      for (var i = 0; i < 20; i++) {
        seen.add(SeedPhrase.canonical(SeedPhrase.generate()));
      }
      expect(seen.length, greaterThan(1));
    });

    test('typing is forgiving about case and spacing', () {
      const typed = '  Ocean   TIGER  maple copper ';
      expect(SeedPhrase.canonical(SeedPhrase.split(typed)),
          'ocean tiger maple copper');
      expect(
          SeedPhrase.matches(
              SeedPhrase.split(typed), ['ocean', 'tiger', 'maple', 'copper']),
          isTrue);
    });

    test('a phrase typed with different spacing derives the same key',
        () async {
      const user = 'u1';
      final a = await _key(
          SeedPhrase.canonical(SeedPhrase.split('  Ocean TIGER  maple copper')),
          user);
      final b = await _key(
          SeedPhrase.canonical(['ocean', 'tiger', 'maple', 'copper']), user);
      expect(await a.extractBytes(), await b.extractBytes());
    });

    test('misspelled words are reported', () {
      final bad = SeedPhrase.unknownWords(['ocean', 'tigerr', 'maple', 'zzzz']);
      expect(bad, containsAll(<String>['tigerr', 'zzzz']));
      expect(bad.contains('ocean'), isFalse);
    });

    test('the phrase carries the advertised entropy', () {
      expect(kBitsPerWord, 10);
      expect(SeedPhrase.entropyBits, SeedPhrase.wordCount * 10);
    });
  });
}
