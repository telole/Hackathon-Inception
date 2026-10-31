import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/pk_button.dart';
import '../../../core/widgets/pk_logo.dart';
import '../../../core/widgets/stitch_painter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _stitchController;
  int _currentPage = 0;
  bool? _animationsDisabled;

  static const _pages = [
    _OnboardingPageData(
      eyebrow: 'PAKAIANMU, CERITA BARU',
      title: 'Yang layak pakai,\nlayak menemukan rumah baru.',
      description: 'Pilih pakaian yang masih nyaman, lalu teruskan ceritanya kepada yang membutuhkan.',
      icon: Icons.checkroom_rounded,
      note: 'Pilih. Rawat. Bagikan.',
    ),
    _OnboardingPageData(
      eyebrow: 'KEBAIKAN YANG SAMPAI',
      title: 'Satu donasi bisa\nmenghangatkan banyak hati.',
      description: 'Kami menghubungkan pakaianmu dengan komunitas dan keluarga yang benar-benar membutuhkannya.',
      icon: Icons.volunteer_activism_rounded,
      note: 'Diterima komunitas terverifikasi',
    ),
    _OnboardingPageData(
      eyebrow: 'LEBIH SIRKULAR, LEBIH PEDULI',
      title: 'Bersama kita kurangi\nlimbah tekstil.',
      description: 'Pantau perjalanan donasi dan lihat dampak baik yang tumbuh dari lemari kita.',
      icon: Icons.recycling_rounded,
      note: 'Setiap helai berarti',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _stitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled == disabled) return;
    _animationsDisabled = disabled;
    if (disabled) {
      _stitchController.value = 1;
    } else {
      _stitchController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stitchController.dispose();
    super.dispose();
  }

  void _selectPage(int page) {
    if (page == _currentPage) return;
    setState(() => _currentPage = page);
    if (MediaQuery.disableAnimationsOf(context)) {
      _stitchController.value = 1;
    } else {
      _stitchController.forward(from: 0);
    }
  }

  void _continue() {
    if (_currentPage < _pages.length - 1) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _pageController.jumpToPage(_currentPage + 1);
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceMd,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const PkLogo(width: 142, onDark: true),
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () => context.go('/home'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: tokens.mutedText,
                      ),
                      child: const Text('Lewati'),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  key: const ValueKey('onboarding-pages'),
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: _selectPage,
                  itemBuilder: (context, index) => _OnboardingPage(
                    data: _pages[index],
                    pageIndex: index,
                    animation: _stitchController,
                  ),
                ),
              ),
              Semantics(
                label: 'Halaman ${_currentPage + 1} dari ${_pages.length}',
                child: ExcludeSemantics(
                  child: AnimatedBuilder(
                    animation: _stitchController,
                    builder: (context, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < _pages.length; index++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: CustomPaint(
                              size: const Size(42, 4),
                              painter: StitchPainter(
                                color: index <= _currentPage
                                    ? tokens.accent
                                    : tokens.border,
                                shape: StitchShape.horizontal,
                                strokeWidth: 2,
                                dashLength: 5,
                                gapLength: 4,
                                progress: index < _currentPage
                                    ? 1
                                    : index == _currentPage
                                    ? _stitchController.value
                                    : 0,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceLg),
              PkButton(
                label: isLastPage ? 'Mulai berbagi' : 'Lanjutkan',
                icon: isLastPage ? Icons.arrow_forward_rounded : null,
                expanded: true,
                onPressed: _continue,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.pageIndex,
    required this.animation,
  });

  final _OnboardingPageData data;
  final int pageIndex;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final artworkHeight = (constraints.maxHeight * 0.46)
            .clamp(220.0, 310.0)
            .toDouble();
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: tokens.spaceSm),
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) => _OnboardingArtwork(
                    data: data,
                    pageIndex: pageIndex,
                    stitchProgress: animation.value,
                    height: artworkHeight,
                  ),
                ),
                SizedBox(height: tokens.spaceXl),
                Text(
                  data.eyebrow,
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: tokens.accentStrong,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: (textTheme.headlineMedium?.fontSize ?? 30) * 0.88,
                    height: 1.24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.mutedText,
                      height: 1.65,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingArtwork extends StatelessWidget {
  const _OnboardingArtwork({
    required this.data,
    required this.pageIndex,
    required this.stitchProgress,
    required this.height,
  });

  final _OnboardingPageData data;
  final int pageIndex;
  final double stitchProgress;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final background = pageIndex == 1
        ? tokens.deepGreen
        : tokens.accent.withValues(alpha: 0.09);
    final iconColor = pageIndex == 1 ? PkPalette.cream : tokens.accentStrong;

    return SizedBox(
      height: height,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 252,
              height: 236,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(34),
                boxShadow: [tokens.cardShadow],
              ),
              child: CustomPaint(
                foregroundPainter: StitchPainter(
                  color: pageIndex == 1
                      ? PkPalette.cream.withValues(alpha: 0.75)
                      : tokens.stitch,
                  radius: 30,
                  progress: stitchProgress,
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          color: pageIndex == 1
                              ? PkPalette.cream.withValues(alpha: 0.1)
                              : tokens.surface,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Icon(data.icon, color: iconColor, size: 86),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -8,
              bottom: 25,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.border),
                  boxShadow: [tokens.cardShadow],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: tokens.accentStrong,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      data.note,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 16,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: tokens.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.background, width: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.note,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final String note;
}
