import 'dart:math';

import 'wordlist.dart';

/// Generation, normalisation and validation of the recovery phrase.
///
/// The phrase is the ONLY thing that can open the vault. It is generated on the
/// device, shown once, verified by the user, and never sent anywhere.
class SeedPhrase {
  SeedPhrase._();

  /// How many words a recovery phrase has.
  ///
  /// 6 words x 10 bits = 60 bits of entropy. Combined with a memory-hard key
  /// derivation (64 MB per guess, see [Vault.kdfMemory]), that puts an offline
  /// attacker who has stolen the whole database far beyond any practical brute
  /// force: they would need to buy 2^60 Argon2id evaluations at 64 MB each.
  ///
  /// Changing this number only affects phrases generated afterwards. Unlock
  /// never assumes a length, it just derives a key from whatever the user
  /// typed, so vaults created under a different word count keep working.
  static const int wordCount = 6;

  /// Bits of entropy in a generated phrase.
  static int get entropyBits => wordCount * kBitsPerWord;

  /// A fresh phrase from the cryptographically secure RNG.
  static List<String> generate() {
    final rand = Random.secure();
    return List<String>.generate(
      wordCount,
      (_) => kWordList[rand.nextInt(kWordList.length)],
    );
  }

  /// Lowercase, trimmed, whitespace-collapsed. Applied to everything the user
  /// types before it is compared or fed to the key derivation, so "  Ocean "
  /// and "ocean" are the same phrase.
  static String normalize(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// The canonical string form fed to the key derivation. Always build the key
  /// input through this so a phrase typed on one device matches another.
  static String canonical(List<String> words) =>
      normalize(words.map(normalize).join(' '));

  /// Whether a single word is in the list. Used for live field validation, so
  /// a typo is caught while typing instead of after a failed unlock.
  static bool isKnownWord(String word) =>
      kWordList.contains(normalize(word));

  /// Split what the user typed into words (accepts spaces, commas, newlines).
  static List<String> split(String raw) => normalize(raw.replaceAll(',', ' '))
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();

  /// Every word that is not in the list, for a precise error message.
  static List<String> unknownWords(List<String> words) =>
      words.where((w) => w.isNotEmpty && !isKnownWord(w)).toList();

  /// Whether two phrases are the same after normalisation.
  static bool matches(List<String> a, List<String> b) =>
      canonical(a) == canonical(b);
}
