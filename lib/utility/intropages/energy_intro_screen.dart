import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/atomic_icon.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// One-time feature tour for Atomic Energy, Atomic Coins, and the long-press
/// sync popup. Shown once from the home screen (flagged in `authBox`), and
/// replayable from the Atomic Energy screen's "How it works" link.
///
/// Pushed on top of the home screen: it pops back when finished, rather than
/// replacing the route, so it works both as the auto-shown intro and as a
/// manual replay.
class EnergyIntroScreen extends StatefulWidget {
  const EnergyIntroScreen({super.key});

  /// authBox flag: has this device seen the energy tour yet.
  static const String seenFlag = 'hasSeenEnergyIntro';

  @override
  State<EnergyIntroScreen> createState() => _EnergyIntroScreenState();
}

class _EnergyIntroScreenState extends State<EnergyIntroScreen> {
  final PageController _controller = PageController();
  bool _onLastPage = false;

  late final List<_EnergySlide> _slides = [
    _EnergySlide(
      art: _gif('atom-formation.gif'),
      eyebrow: 'ATOMIC ENERGY',
      title: 'Energy powers\nyour sync.',
      body: 'You get +20 Atomic Energy free every 24 hours, up to 120. Local '
          'note-taking is always free — energy only powers cloud sync.',
    ),
    _EnergySlide(
      art: _mark('atom', '2.5D'),
      eyebrow: 'QUICK PEEK',
      title: 'Long-press\nthe sync button.',
      body: 'Press and hold the sync button in the top bar to peek at your '
          'Atomic Energy and Coins without leaving your notes. Tap it as usual '
          'to sync.',
    ),
    _EnergySlide(
      art: _gif('atom-to-coin.gif'),
      eyebrow: 'ATOMIC COINS',
      title: 'Coins top up\nyour energy.',
      body: '1 Atomic Coin converts to 40 energy, and new accounts start with '
          '5 coins. Convert whenever you like from the Atomic Energy screen.',
    ),
    _EnergySlide(
      art: _mark('atomic-coin', 'Without-label'),
      eyebrow: 'SYNC COSTS',
      title: 'Instant or\nstandard.',
      body: 'Instant sync costs 10 energy; standard background sync costs 5, at '
          'most once an hour. Run low? Your notes stay safe on the device and '
          'sync once energy returns.',
    ),
  ];

  static Widget _gif(String name) => Image.asset(
        'assets/Atomic Icons/$name',
        height: 150,
        fit: BoxFit.contain,
      );

  static Widget _mark(String name, String variant) => AtomicIcon(
        name,
        size: 110,
        set: variant == '2.5D'
            ? 'Icons-Without-label-2.5D'
            : 'Icons-Without-label',
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      await Hive.box<bool>('authBox').put(EnergyIntroScreen.seenFlag, true);
    } catch (_) {
      // Non-fatal: worst case the tour shows again next launch.
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (v) =>
                    setState(() => _onLastPage = v == _slides.length - 1),
                itemBuilder: (context, i) => _EnergyIntroPage(
                  slide: _slides[i],
                  index: i,
                  total: _slides.length,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenMargin, 0,
                  AppSpace.screenMargin, AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HairRule(color: AppColors.ink),
                  const SizedBox(height: AppSpace.md),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _finish,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: AppSpace.sm, horizontal: 2),
                          child: MonoLabel('SKIP'),
                        ),
                      ),
                      const Spacer(),
                      SmoothPageIndicator(
                        controller: _controller,
                        count: _slides.length,
                        effect: const WormEffect(
                          dotHeight: 6,
                          dotWidth: 6,
                          spacing: 6,
                          dotColor: AppColors.outlineVariant,
                          activeDotColor: AppColors.signal,
                        ),
                      ),
                      const Spacer(),
                      _onLastPage
                          ? InkActionButton(
                              label: 'Got it',
                              expand: false,
                              signal: true,
                              onTap: _finish,
                            )
                          : InkActionButton(
                              label: 'Next',
                              expand: false,
                              onTap: () => _controller.nextPage(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergySlide {
  final Widget art;
  final String eyebrow;
  final String title;
  final String body;
  const _EnergySlide({
    required this.art,
    required this.eyebrow,
    required this.title,
    required this.body,
  });
}

class _EnergyIntroPage extends StatelessWidget {
  final _EnergySlide slide;
  final int index;
  final int total;
  const _EnergyIntroPage(
      {required this.slide, required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    final step = '${(index + 1).toString().padLeft(2, '0')} / '
        '${total.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.screenMargin, vertical: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: MonoLabel(slide.eyebrow, color: AppColors.signal)),
              MonoLabel(step, small: true),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          const HairRule(color: AppColors.ink),
          const SizedBox(height: AppSpace.lg),
          EditorialModule(
            fill: AppColors.surfaceLow,
            padding: const EdgeInsets.all(AppSpace.lg),
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: Center(child: slide.art),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          EditorialHeading(slide.title, style: AppType.displayLg),
          const SizedBox(height: AppSpace.sm),
          Text(
            slide.body,
            style: AppType.bodyLg.copyWith(color: AppColors.slateData),
          ),
          const SizedBox(height: AppSpace.md),
        ],
      ),
    );
  }
}
