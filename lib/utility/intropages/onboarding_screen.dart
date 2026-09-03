import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/intropages/intro_art.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// First-run tour.
///
/// Replaces the six screenshot-only screens: each page now leads with a
/// drawn illustration and actually says what the app does. Four pages rather
/// than six — the old deck had nothing to read, so length was the only thing
/// it communicated.
class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  // controller to keep track of pages
  final PageController _controller = PageController();
  bool onLastPage = false;

  static const List<_IntroSlide> _slides = [
    _IntroSlide(
      kind: IntroArtKind.grid,
      eyebrow: 'EVERYTHING IN ONE PLACE',
      title: 'Your notes,\nat a glance.',
      body: 'Notes land in a grid you can scan in one look — newest first, '
          'with the date on every card.',
    ),
    _IntroSlide(
      kind: IntroArtKind.editor,
      eyebrow: 'WRITE OR TICK OFF',
      title: 'Plain notes\nand checklists.',
      body: 'Write freely, or switch to a checklist when you need something '
          'you can tick off.',
    ),
    _IntroSlide(
      kind: IntroArtKind.sync,
      eyebrow: 'ACROSS YOUR DEVICES',
      title: 'Sync that\nkeeps up.',
      body: 'Sign in anywhere and your notes follow. Edits made on one device '
          'show up on the others.',
    ),
    _IntroSlide(
      kind: IntroArtKind.lock,
      eyebrow: 'YOURS ALONE',
      title: 'Local first,\nlocked down.',
      body: 'Notes live on your device and sync only to your account. Add a '
          'fingerprint lock in Settings.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => Navigator.of(context).pushReplacementNamed('/mainpage');

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
                onPageChanged: (value) {
                  setState(() {
                    onLastPage = (value == _slides.length - 1);
                  });
                },
                itemBuilder: (context, i) => _IntroPage(
                  slide: _slides[i],
                  index: i,
                  total: _slides.length,
                ),
              ),
            ),

            // Controls
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
                      onLastPage
                          ? InkActionButton(
                              label: 'Start',
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

class _IntroSlide {
  final IntroArtKind kind;
  final String eyebrow;
  final String title;
  final String body;
  const _IntroSlide({
    required this.kind,
    required this.eyebrow,
    required this.title,
    required this.body,
  });
}

class _IntroPage extends StatelessWidget {
  final _IntroSlide slide;
  final int index;
  final int total;
  const _IntroPage(
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
          IntroArt(slide.kind),
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
