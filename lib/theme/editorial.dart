import 'package:flutter/material.dart';
import 'package:atomic_notes/theme/app_tokens.dart';

/// Reusable pieces of the Technical Editorial language.
///
/// Screens compose these instead of re-declaring borders, fills and type, so
/// the system stays consistent and a change here propagates everywhere.

/// A "bento module": thin-bordered container with a tonal fill.
/// This is the workhorse surface — stats, groups of rows, cards.
class EditorialModule extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Invert to Ink-on-Paper for high-priority modules (the design system's
  /// emphasis mechanism — there is no "raise it with a shadow" here).
  final bool inverted;

  /// Draw attention with a Signal-coloured border instead of the usual hairline.
  final bool accent;
  final Color? fill;

  const EditorialModule({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.modulePadding),
    this.margin,
    this.inverted = false,
    this.accent = false,
    this.fill,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color background =
        fill ?? (inverted ? AppColors.ink : AppColors.surfaceContainer);
    final Color border = accent
        ? AppColors.signal
        : (inverted ? AppColors.ink : AppColors.outlineVariant);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.std,
        border: Border.all(color: border, width: AppStroke.hairline),
      ),
      child: child,
    );
  }
}

/// Small uppercase monospace label — the "system status" voice used for
/// dates, counts, section eyebrows and tags.
class MonoLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final bool small;
  final TextAlign? align;

  const MonoLabel(
    this.text, {
    this.color,
    this.small = false,
    this.align,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final base = small ? AppType.labelMonoSm : AppType.labelMono;
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: color == null ? base : base.copyWith(color: color),
    );
  }
}

/// Uppercase Bebas Neue heading.
class EditorialHeading extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;

  const EditorialHeading(
    this.text, {
    this.style,
    this.color,
    this.align,
    this.maxLines,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? AppType.headlineMd;
    return Text(
      text.toUpperCase(),
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: color == null ? base : base.copyWith(color: color),
    );
  }
}

/// A 1px separator rule. Thinner and quieter than Material's Divider.
class HairRule extends StatelessWidget {
  final double indent;
  final double endIndent;
  final Color? color;

  const HairRule({this.indent = 0, this.endIndent = 0, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: Container(
        height: AppStroke.rule,
        color: color ?? AppColors.outlineVariant,
      ),
    );
  }
}

/// Section header: a mono eyebrow over a rule, as used throughout the
/// reference layouts to open a block of content.
class SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const SectionHeader(this.label, {this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: MonoLabel(label)),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        const HairRule(color: AppColors.ink),
      ],
    );
  }
}

/// Primary action: Ink fill, Paper label, with the system's "solid offset
/// print" pseudo-shadow instead of a blur.
class InkActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool expand;
  final IconData? icon;

  /// Destructive variant — error red fill.
  final bool danger;

  /// Signal variant — indigo fill, for the single most important action
  /// on a screen.
  final bool signal;

  const InkActionButton({
    required this.label,
    required this.onTap,
    this.loading = false,
    this.expand = true,
    this.icon,
    this.danger = false,
    this.signal = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color fill = danger
        ? AppColors.error
        : signal
            ? AppColors.signal
            : AppColors.ink;
    final Color label0 = danger || signal ? Colors.white : AppColors.paper;

    return GestureDetector(
      onTap: loading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: expand ? double.infinity : null,
        // The offset "print" shadow: zero blur, solid, down-right.
        decoration: const BoxDecoration(
          borderRadius: AppRadius.std,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(AppStroke.offset, AppStroke.offset),
              blurRadius: 0,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.md),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.std,
            border:
                Border.all(color: AppColors.ink, width: AppStroke.hairline),
          ),
          child: loading
              // Center a fixed square, or the full-width button stretches the
              // indicator into an ellipse.
              ? const Center(
                  heightFactor: 1,
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.paper),
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: label0),
                      const SizedBox(width: AppSpace.sm),
                    ],
                    Flexible(
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppType.cta.copyWith(color: label0),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Outlined secondary action.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool expand;
  final IconData? icon;

  const GhostButton({
    required this.label,
    required this.onTap,
    this.expand = true,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: AppSpace.md),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppRadius.std,
          border: Border.all(color: AppColors.ink, width: AppStroke.hairline),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.ink),
              const SizedBox(width: AppSpace.sm),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.cta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded status tag — deliberately the one rounded shape in the system, so
/// data chips read as distinct from structural containers.
class DataChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color? activeColor;

  const DataChip(this.label, {this.active = false, this.activeColor, super.key});

  @override
  Widget build(BuildContext context) {
    final Color fill =
        active ? (activeColor ?? AppColors.ink) : Colors.transparent;
    final Color fg = active ? AppColors.paper : AppColors.slateData;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm + 2, vertical: AppSpace.xs + 1),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.chip,
        border: Border.all(
          color: active ? fill : AppColors.outlineVariant,
          width: AppStroke.rule,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppType.labelMonoSm.copyWith(color: fg),
      ),
    );
  }
}

/// The arrow motif from the reference — used on forward-navigating links.
class ArrowLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const ArrowLink(this.label, {this.onTap, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.signal;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: AppType.labelMono.copyWith(color: c)),
          const SizedBox(width: AppSpace.xs + 2),
          Icon(Icons.arrow_forward, size: 13, color: c),
        ],
      ),
    );
  }
}

/// The app's logo mark. The source PNG is a light-on-dark atom, so on a Paper
/// canvas it is framed in an Ink block — which is exactly how the reference
/// treats logos, and avoids needing to redraw the asset.
class InkLogoMark extends StatelessWidget {
  final double size;
  const InkLogoMark({this.size = 44, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: const BoxDecoration(
        color: AppColors.ink,
        borderRadius: AppRadius.std,
      ),
      child: Image.asset('assets/logo_x.png', fit: BoxFit.contain),
    );
  }
}
