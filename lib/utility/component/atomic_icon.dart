import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

/// Loads an icon from the bundled Atomic icon family
/// (`assets/Atomic Icons/...`), so Energy/Coin UI reuses the provided assets
/// instead of inventing a different visual style.
///
/// Available names: `atom`, `atomic-coin`, `electron`, `proton`, `neutron`,
/// `ad`. Sets: `Icons-Without-label` (default, clean glyphs),
/// `Icons-With-label`, `Icons-Without-label-2.5D` (dimensional, for heroes).
class AtomicIcon extends StatelessWidget {
  final String name;
  final double size;
  final String set;

  const AtomicIcon(
    this.name, {
    this.size = 24,
    this.set = 'Icons-Without-label',
    super.key,
  });

  /// Convenience: the Atomic Energy mark.
  const AtomicIcon.energy({double size = 24, String set = 'Icons-Without-label', Key? key})
      : this('atom', size: size, set: set, key: key);

  /// Convenience: the Atomic Coin mark.
  const AtomicIcon.coin({double size = 24, String set = 'Icons-Without-label', Key? key})
      : this('atomic-coin', size: size, set: set, key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/Atomic Icons/$set/$name.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
