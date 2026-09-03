import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Pure, side-effect-free cryptography for the vault.
///
/// No network, no storage, no Flutter bindings, so every primitive here is
/// directly unit-testable (see test/vault_test.dart). All I/O and key state
/// lives in [Vault].
///
/// A sealed blob is base64( nonce(12) ++ ciphertext ++ mac(16) ): the AES-GCM
/// output concatenated and base64-encoded.
class VaultCrypto {
  VaultCrypto._();

  static final AesGcm aes = AesGcm.with256bits();

  /// AES-GCM standard 96-bit nonce.
  static const int nonceLength = 12;

  /// AES-GCM authentication tag.
  static const int macLength = 16;

  /// Domain separator, mixed into the salt. Bumping this would invalidate every
  /// existing vault, so it is versioned rather than edited.
  static const String saltDomain = 'atomic-notes-vault-v1';

  /// The constant sealed into the server-side verifier.
  static const String verifierPlaintext = 'atomic-notes-vault-check-v1';

  /// The per-user KDF salt, derived deterministically from the account id.
  ///
  /// This is the piece that makes multi-device work: the salt is a pure
  /// function of the user id, so the SAME phrase on ANY device derives the SAME
  /// key with no server round trip and nothing to get out of sync. A salt does
  /// not need to be secret or random, only unique per user, and a per-account
  /// UUID under a domain separator satisfies that.
  static Future<Uint8List> saltForUser(String userId) async {
    final digest =
        await Sha256().hash(utf8.encode('$saltDomain|$userId'));
    return Uint8List.fromList(digest.bytes);
  }

  /// Derive the 256-bit vault key from the recovery phrase.
  ///
  /// Argon2id is memory-hard on purpose: it is what buys a short, memorable
  /// phrase its security margin against an offline attacker.
  static Future<SecretKey> deriveKey(
    String canonicalPhrase,
    List<int> salt, {
    required int memory,
    required int iterations,
    required int parallelism,
  }) {
    final argon = Argon2id(
      memory: memory,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: 32,
    );
    return argon.deriveKeyFromPassword(
        password: canonicalPhrase, nonce: salt);
  }

  /// Seal raw bytes. Returns base64( nonce ++ ciphertext ++ mac ).
  static Future<String> seal(List<int> clear, SecretKey key) async {
    final box = await aes.encrypt(clear, secretKey: key);
    return base64Encode(box.concatenation());
  }

  /// Open a sealed blob.
  ///
  /// Throws [SecretBoxAuthenticationError] if the key is wrong or the data was
  /// tampered with, which is what makes phrase verification trustworthy.
  static Future<Uint8List> open(String b64, SecretKey key) async {
    final box = SecretBox.fromConcatenation(
      base64Decode(b64),
      nonceLength: nonceLength,
      macLength: macLength,
    );
    final clear = await aes.decrypt(box, secretKey: key);
    return Uint8List.fromList(clear);
  }

  /// Seal a note's content map.
  static Future<String> sealJson(Map<String, dynamic> content, SecretKey key) =>
      seal(utf8.encode(jsonEncode(content)), key);

  /// Open a sealed content blob back into a map.
  static Future<Map<String, dynamic>> openJson(
      String b64, SecretKey key) async {
    final bytes = await open(b64, key);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  /// Seal the known constant, for storing server-side.
  static Future<String> makeVerifier(SecretKey key) =>
      seal(utf8.encode(verifierPlaintext), key);

  /// True when [key] opens [verifier] and finds the expected constant. False on
  /// a wrong key rather than throwing, since "wrong phrase" is a normal outcome.
  static Future<bool> checkVerifier(String verifier, SecretKey key) async {
    try {
      final bytes = await open(verifier, key);
      return utf8.decode(bytes) == verifierPlaintext;
    } catch (_) {
      return false;
    }
  }
}
