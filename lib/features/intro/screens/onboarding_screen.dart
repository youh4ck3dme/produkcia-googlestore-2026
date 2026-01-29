import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/onboarding_provider.dart';
import '../../auth/providers/auth_repository.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/ui/biz_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}


class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Inteligentná\nFakturácia',
      description:
          'Zabudnite na zdĺhavé vypisovanie. Vytvárajte profesionálne faktúry za pár sekúnd s automatickým prepojením na databázu firiem.',
      imagePath: 'assets/images/onboarding_invoice_clean.webp',
      accentColor: BizTheme.slovakBlue,
      isFullScreen: true,
    ),
    OnboardingContent(
      title: 'AI Účtovný\nExpert',
      description:
          'Využite silu umelej inteligencie. Automatické skenovanie bločkov, daňové predpovede a real-time finančné analýzy. Váš osobný génius v mobile.',
      imagePath: 'assets/images/onboarding_ai_clean.webp',
      accentColor: BizTheme.nationalRed,
      isFullScreen: true,
    ),
    OnboardingContent(
      title: 'Finančný\nPrehľad',
      description:
          'Dokonalý prehľad o cash-flow. Sledujte rast svojho podnikania v reálnom čase s prehľadnými grafmi a analýzami.',
      imagePath: 'assets/images/onboarding_chart_clean.webp',
      accentColor: BizTheme.slovakBlue,
      isFullScreen: true,
    ),
    OnboardingContent(
      title: 'Bezpečnosť\n& Sloboda',
      description:
          'Vaše dáta sú v bezpečí (GDPR ready). Podnikajte odkiaľkoľvek, fakturujte z mobilu a majte všetko pod kontrolou.',
      imagePath: 'assets/images/onboarding_security_clean.webp',
      accentColor: BizTheme.slovakBlue,
      isFullScreen: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logOnboardingSeen();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force light status bar for white background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 0. Global Background (Restored)
          Image.asset(
            'assets/images/background_fusion.webp',
            fit: BoxFit.cover,
          ),

          // 1. Full Screen PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _contents.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _OnboardingPage(content: _contents[index]);
            },
          ),

          // 2. Promo Badge (Launch Special) - Top Right
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "7 Dní Zdarma",
                    style: GoogleFonts.inter(
                      fontSize: 9.6, // Reduced by 20% (12 * 0.8)
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Controls & Indicators
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Indicators
                        Row(
                          children: List.generate(
                            _contents.length,
                            (index) => _AnimatedDot(
                              isActive: index == _currentPage,
                              color: _contents[_currentPage].isFullScreen
                                  ? Colors.white // White dots on dark images
                                  : _contents[_currentPage].accentColor,
                            ),
                          ),
                        ),

                        // Next Button
                        _AnimatedNextButton(
                          isLast: _currentPage == _contents.length - 1,
                          color: _contents[_currentPage].isFullScreen
                                  ? Colors.white // White button on dark images
                                  : _contents[_currentPage].accentColor,
                          onPressed: () {
                            if (_currentPage == _contents.length - 1) {
                              ref
                                  .read(onboardingProvider.notifier)
                                  .completeOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.fastOutSlowIn,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Demo Mode Button
                    TextButton(
                      onPressed: () async {
                        ref
                            .read(analyticsServiceProvider)
                            .logTryWithoutRegistration();
                        await ref
                            .read(authRepositoryProvider)
                            .signInAnonymously();
                        ref
                            .read(onboardingProvider.notifier)
                            .completeOnboarding();
                      },
                      child: Text(
                        "vyskúšať bez registrácie",
                        style: GoogleFonts.inter(
                          fontSize: 11.2, // Reduced by 20% (14 * 0.8)
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  const _OnboardingPage({required this.content});

  @override
  Widget build(BuildContext context) {
    // 1. Full Screen Image Mode
    if (content.isFullScreen && content.imagePath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            content.imagePath!,
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.center,
          ),

          // Gradient Overlay (for text readability)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.05), // Slight tint middle
                  Colors.white.withValues(alpha: 0.8), // White bottom
                ],
                stops: const [0.4, 0.6, 1.0],
              ),
            ),
          ),

          // Text Content (Bottom Aligned)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3), // Push text down but keep some flexibility
                
                Text(
                  content.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -1.0,
                    shadows: [
                       Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(0, 2),
                      ),
                    ]
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  content.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.8, // Reduced by 20% (16 * 0.8)
                    color: const Color(0xFF4B5563),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                     shadows: [
                       Shadow(
                        blurRadius: 4.0,
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(0, 1),
                      ),
                    ]
                  ),
                ),
                const SizedBox(height: 140), // Space for bottom controls
              ],
            ),
          )
        ],
      );
    }

    // 2. Standard SVG Mode (Fallback for non-image slides)
    // Uses transparent background so global background shows through
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
             // Ensure it takes full height to center content vertically
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // SVG Illustration Container
                  SizedBox(
                    height: 300,
                    width: constraints.maxWidth,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect behind SVG
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: content.accentColor.withValues(alpha: 0.1),
                            boxShadow: [
                              BoxShadow(
                                color: content.accentColor.withValues(alpha: 0.1),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        content.imagePath != null
                            ? Image.asset(
                                content.imagePath!,
                                height: 280,
                                fit: BoxFit.contain,
                              )
                            : SvgPicture.asset(
                                content.svgPath!,
                                height: 280,
                                fit: BoxFit.contain,
                                placeholderBuilder: (context) =>
                                    const Center(child: CircularProgressIndicator()),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Title
                  Text(
                    content.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    content.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.8, // Reduced by 20% (16 * 0.8)
                      height: 1.6,
                      color: const Color(0xFF4B5563),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _AnimatedDot({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        color: isActive ? color : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _AnimatedNextButton extends StatelessWidget {
  final bool isLast;
  final Color color;
  final VoidCallback onPressed;

  const _AnimatedNextButton({
    required this.isLast,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 64,
        width: isLast ? 160 : 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: isLast ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 28),
            ),
            AnimatedOpacity(
              opacity: isLast ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Začať",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.8, // Reduced by 20% (16 * 0.8)
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String? svgPath;
  final String? imagePath;
  final Color accentColor;
  final bool isFullScreen;

  OnboardingContent({
    required this.title,
    required this.description,
    this.svgPath,
    this.imagePath,
    required this.accentColor,
    this.isFullScreen = true,
  }) : assert(svgPath != null || imagePath != null);
}

