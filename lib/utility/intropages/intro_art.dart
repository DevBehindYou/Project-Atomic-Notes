import 'dart:math' as math;

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Onboarding illustrations, drawn rather than shipped as PNGs.
///
/// The old intro screens were six full-bleed 1920px photographs of a dark UI —
/// they looked wrong on the Paper canvas, cost ~1MB of APK, and said nothing.
/// These are built from the design system's own vocabulary (hairline grids,
/// Ink blocks, Signal accents), so they scale to any screen for free and stay
/// on-brand automatically if the tokens change.
enum IntroArtKind { grid, editor, sync, lock }

class IntroArt extends StatelessWidget {
  final IntroArtKind kind;
  const IntroArt(this.kind, {super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: AppRadius.std,
          border:
              Border.all(color: AppColors.ink, width: AppStroke.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _IntroPainter(kind),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _IntroPainter extends CustomPainter {
  final IntroArtKind kind;
  _IntroPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    _grid(canvas, size);
    switch (kind) {
      case IntroArtKind.grid:
        _paintGrid(canvas, size);
      case IntroArtKind.editor:
        _paintEditor(canvas, size);
      case IntroArtKind.sync:
        _paintSync(canvas, size);
      case IntroArtKind.lock:
        _paintLock(canvas, size);
    }
  }

  /// Faint engineering grid behind everything — the "technical journal" ground.
  void _grid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 0.6;
    const step = 22.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  Paint get _ink => Paint()
    ..color = AppColors.ink
    ..style = PaintingStyle.fill;

  Paint get _stroke => Paint()
    ..color = AppColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  Paint get _signal => Paint()
    ..color = AppColors.signal
    ..style = PaintingStyle.fill;

  void _card(Canvas canvas, Rect r, {bool filled = false, bool accent = false}) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
    canvas.drawRRect(
        rr,
        Paint()
          ..color = filled ? AppColors.ink : AppColors.surfaceLowest
          ..style = PaintingStyle.fill);
    canvas.drawRRect(rr, accent ? (_stroke..color = AppColors.signal) : _stroke);
  }

  void _line(Canvas canvas, double x, double y, double w,
      {double h = 4, Color? color}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(2)),
      Paint()..color = color ?? AppColors.outlineVariant,
    );
  }

  /// 1 — a masonry wall of note cards.
  void _paintGrid(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final colW = w * 0.36;
    final heights = [
      [h * 0.30, h * 0.22, h * 0.26],
      [h * 0.22, h * 0.32, h * 0.24],
    ];
    for (int col = 0; col < 2; col++) {
      double y = h * 0.10;
      final x = w * (col == 0 ? 0.12 : 0.52);
      for (int i = 0; i < heights[col].length; i++) {
        final ch = heights[col][i];
        if (y + ch > h * 0.92) break;
        final accent = col == 1 && i == 1;
        _card(canvas, Rect.fromLTWH(x, y, colW, ch), accent: accent);
        _line(canvas, x + 8, y + 9, colW * 0.5, h: 3);
        _line(canvas, x + 8, y + 20, colW * 0.72, h: 5,
            color: AppColors.ink);
        _line(canvas, x + 8, y + 32, colW * 0.62);
        if (ch > h * 0.25) _line(canvas, x + 8, y + 41, colW * 0.4);
        y += ch + h * 0.035;
      }
    }
  }

  /// 2 — the editor: title rule, body lines, a checklist forming.
  void _paintEditor(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.76, h * 0.76);
    _card(canvas, r);

    final x = r.left + 14;
    _line(canvas, x, r.top + 14, r.width * 0.34, h: 3);
    canvas.drawLine(Offset(x, r.top + 28), Offset(r.right - 14, r.top + 28),
        Paint()
          ..color = AppColors.ink
          ..strokeWidth = 1);
    _line(canvas, x, r.top + 38, r.width * 0.6, h: 8, color: AppColors.ink);

    // Checklist rows — two ticked, one open.
    double y = r.top + 62;
    for (int i = 0; i < 3; i++) {
      final box = Rect.fromLTWH(x, y, 10, 10);
      if (i < 2) {
        canvas.drawRect(box, _signal);
        final tick = Path()
          ..moveTo(box.left + 2.5, box.top + 5)
          ..lineTo(box.left + 4.5, box.top + 7.2)
          ..lineTo(box.left + 7.8, box.top + 2.8);
        canvas.drawPath(
            tick,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6);
      } else {
        canvas.drawRect(
            box,
            Paint()
              ..color = AppColors.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
      }
      _line(canvas, x + 18, y + 3, r.width * (i == 2 ? 0.38 : 0.54),
          color: i < 2 ? AppColors.outlineVariant : AppColors.ink);
      y += 20;
    }

    // Caret.
    canvas.drawRect(
        Rect.fromLTWH(x + 18 + r.width * 0.38 + 3, y - 20, 1.5, 11), _signal);
  }

  /// 3 — two devices, one arc: the same note on both.
  void _paintSync(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final left = Rect.fromLTWH(w * 0.08, h * 0.30, w * 0.26, h * 0.42);
    final right = Rect.fromLTWH(w * 0.66, h * 0.30, w * 0.26, h * 0.42);
    _card(canvas, left, accent: true);
    _card(canvas, right, accent: true);

    for (final r in [left, right]) {
      _line(canvas, r.left + 6, r.top + 10, r.width * 0.6, h: 3);
      _line(canvas, r.left + 6, r.top + 20, r.width * 0.75, h: 5,
          color: AppColors.ink);
      _line(canvas, r.left + 6, r.top + 31, r.width * 0.5);
    }

    // The arc between them, with an arrowhead — data in flight.
    final arc = Path()
      ..moveTo(left.right, h * 0.44)
      ..cubicTo(w * 0.44, h * 0.14, w * 0.56, h * 0.14, right.left, h * 0.44);
    canvas.drawPath(
        arc,
        Paint()
          ..color = AppColors.signal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    final head = Path()
      ..moveTo(right.left, h * 0.44)
      ..lineTo(right.left - 9, h * 0.40)
      ..lineTo(right.left - 8, h * 0.475)
      ..close();
    canvas.drawPath(head, _signal);

    // Return arc, quieter.
    final back = Path()
      ..moveTo(right.left, h * 0.62)
      ..cubicTo(w * 0.56, h * 0.86, w * 0.44, h * 0.86, left.right, h * 0.62);
    canvas.drawPath(
        back,
        Paint()
          ..color = AppColors.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    final head2 = Path()
      ..moveTo(left.right, h * 0.62)
      ..lineTo(left.right + 9, h * 0.585)
      ..lineTo(left.right + 8, h * 0.66)
      ..close();
    canvas.drawPath(head2, Paint()..color = AppColors.outline);
  }

  /// 4 — a padlock built from the same square language, over a note stack.
  void _paintLock(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Stack behind.
    for (int i = 2; i >= 0; i--) {
      final inset = i * 10.0;
      _card(
          canvas,
          Rect.fromLTWH(w * 0.20 + inset, h * 0.20 + inset, w * 0.60 - inset * 2,
              h * 0.60 - inset * 2),
          filled: i == 0 && false);
    }

    // Shackle.
    final cx = w / 2;
    final shackle = Rect.fromCenter(
        center: Offset(cx, h * 0.46), width: w * 0.20, height: h * 0.22);
    canvas.drawArc(
        shackle,
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.butt);

    // Body.
    final body = Rect.fromCenter(
        center: Offset(cx, h * 0.62), width: w * 0.30, height: h * 0.20);
    canvas.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(3)), _ink);

    // Keyhole in Signal.
    canvas.drawCircle(Offset(cx, body.center.dy - 3), 4.5, _signal);
    canvas.drawRect(
        Rect.fromLTWH(cx - 1.6, body.center.dy - 1, 3.2, 10), _signal);
  }

  @override
  bool shouldRepaint(covariant _IntroPainter old) => old.kind != kind;
}
