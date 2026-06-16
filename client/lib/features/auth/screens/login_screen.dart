import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/ambient_particles.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Path> _parsedPaths = [];

  // Staggered Animations
  late Animation<double> _drawingProgress;
  late Animation<double> _titleScale;
  late Animation<Alignment> _titleAlignment;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _loginOpacity;
  late Animation<double> _loginSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Pacifico Marker SVG Paths (from FONT_DATA.pacifico in the HTML)
    const markerPaths = [
      "M802 178Q802 139 783 116Q727 49 674.5 22.0Q622 -5 548 -5Q496 -5 452.0 8.0Q408 21 345 47Q288 72 235 88Q184 -5 82 -5Q26 -5 -7.5 20.5Q-41 46 -41 86Q-41 135 6.0 167.5Q53 200 131 200H144L162 491Q168 591 198.0 656.0Q228 721 281 767Q327 807 386.0 827.5Q445 848 511 848Q619 848 677.0 792.0Q735 736 735 646Q735 585 713.0 547.5Q691 510 652 510Q624 510 608.0 523.5Q592 537 592 562Q592 571 596 595Q602 623 602 645Q602 687 577.5 711.5Q553 736 503 736Q415 736 367.0 678.5Q319 621 306 498L283 271Q278 223 270 188Q334 177 430 153Q486 139 516.0 133.0Q546 127 569 127Q627 127 668.5 146.5Q710 166 747 209Q759 223 774 223Q787 223 794.5 211.0Q802 199 802 178Z",
      "M721 140Q721 215 731.0 277.5Q741 340 764 410Q774 440 792.0 453.0Q810 466 849 466Q871 466 879.5 459.0Q888 452 888 438Q888 430 877 384Q867 347 861 317Q841 212 841 177Q841 156 846.0 147.5Q851 139 862 139Q877 139 899.5 169.0Q922 199 947.5 260.0Q973 321 997 410Q1005 440 1021.5 453.0Q1038 466 1071 466Q1094 466 1103.0 460.5Q1112 455 1112 440Q1112 415 1087 303Q1059 175 1059 145Q1059 126 1067.0 115.5Q1075 105 1088 105Q1108 105 1135.5 129.5Q1163 154 1209 209Q1221 223 1236 223Q1249 223 1256.5 211.0Q1264 199 1264 178Q1264 138 1245 116Q1202 63 1152.5 29.0Q1103 -5 1040 -5Q992 -5 969.5 32.0Q947 69 947 136Q930 68 896.0 31.5Q862 -5 823 -5Q778 -5 749.5 36.5Q721 78 721 140Z",
      "M1185 163Q1185 293 1222 410Q1231 439 1251.5 452.5Q1272 466 1309 466Q1329 466 1337.0 461.0Q1345 456 1345 442Q1345 426 1330 370Q1320 330 1314.0 300.5Q1308 271 1304 227Q1331 305 1368.5 359.0Q1406 413 1445.5 439.5Q1485 466 1520 466Q1555 466 1569.5 450.0Q1584 434 1584 401Q1584 369 1565 285Q1557 249 1554 231Q1604 354 1665.0 410.0Q1726 466 1779 466Q1844 466 1844 401Q1844 362 1822 260Q1803 173 1803 145Q1803 105 1832 105Q1852 105 1879.5 129.5Q1907 154 1953 209Q1965 223 1980 223Q1993 223 2000.5 211.0Q2008 199 2008 178Q2008 138 1989 116Q1946 63 1896.5 29.0Q1847 -5 1784 -5Q1733 -5 1707.0 24.5Q1681 54 1681 110Q1681 138 1695 210Q1708 273 1708 297Q1708 313 1697 313Q1684 313 1660.0 279.5Q1636 246 1612.0 191.0Q1588 136 1573 75Q1562 27 1547.5 11.0Q1533 -5 1501 -5Q1468 -5 1451.5 26.5Q1435 58 1435 103Q1435 141 1445 213Q1453 277 1453 297Q1453 313 1442 313Q1427 313 1404.0 277.0Q1381 241 1359.5 185.0Q1338 129 1325 75Q1314 28 1299.5 11.5Q1285 -5 1254 -5Q1216 -5 1200.5 35.0Q1185 75 1185 163Z",
      "M1974 606Q1974 641 2001.5 664.5Q2029 688 2070 688Q2107 688 2130.0 670.0Q2153 652 2153 619Q2153 579 2127.0 555.5Q2101 532 2058 532Q2016 532 1995.0 551.5Q1974 571 1974 606ZM1926 163Q1926 208 1937.5 278.5Q1949 349 1967 410Q1976 442 1991.0 454.0Q2006 466 2039 466Q2090 466 2090 432Q2090 407 2071 316Q2047 206 2047 167Q2047 137 2055.0 121.0Q2063 105 2082 105Q2100 105 2127.0 130.0Q2154 155 2199 209Q2211 223 2226 223Q2239 223 2246.5 211.0Q2254 199 2254 178Q2254 138 2254 178Z",
      "M2175 163Q2175 293 2212 410Q2221 439 2241.5 452.5Q2262 466 2299 466Q2319 466 2327.0 461.0Q2335 456 2335 442Q2335 426 2320 370Q2310 330 2304.0 300.0Q2298 270 2294 226Q2327 312 2368.0 366.0Q2409 420 2448.5 443.0Q2488 466 2521 466Q2586 466 2586 401Q2586 362 2564 260Q2545 173 2545 145Q2545 105 2574 105Q2594 105 2621.5 129.5Q2649 154 2695 209Q2707 223 2722 223Q2735 223 2742.5 211.0Q2750 199 2750 178Q2750 138 2731 116Q2688 63 2638.5 29.0Q2589 -5 2526 -5Q2475 -5 2449.0 24.5Q2423 54 2423 110Q2423 138 2437 210Q2450 273 2450 297Q2450 313 2439 313Q2426 313 2402.5 279.5Q2379 246 2354.5 191.0Q2330 136 2315 75Q2304 28 2289.5 11.5Q2275 -5 2244 -5Q2206 -5 2190.5 35.0Q2175 75 2175 163Z",
      "M2656 158Q2656 238 2693.0 309.5Q2730 381 2791.5 424.5Q2853 468 2922 468Q2944 468 2951.5 459.5Q2959 451 2964 429Q2983 433 3006 433Q3030 433 3043.0 421.0Q3056 409 3056 387Q3056 364 3046 307Q3035 246 3029.0 190.5Q3023 135 3023 66Q3023 28 3007.5 11.5Q2992 -5 2957 -5Q2923 -5 2906.5 11.5Q2890 28 2890 65L2891 81Q2860 -5 2784 -5Q2727 -5 2691.5 40.0Q2656 85 2656 158ZM2915 274 2934 375Q2893 374 2858.0 343.5Q2823 313 2802.0 263.0Q2781 213 2781 157Q2781 127 2781 157Q2781 127 2792.5 111.5Q2804 96 2823 96Q2851 96 2874.0 135.0Q2897 174 2915 274Z"
    ];

    _parsedPaths = markerPaths.map(parseSvgPathData).toList();

    // 1. Handwriting drawing phase (0.05 to 0.65 of total controller time)
    _drawingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.65, curve: Curves.easeInOut),
      ),
    );

    // 2. Initial title scale in center
    _titleScale = Tween<double>(begin: 0.85, end: 1.02).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Title slides up from center to header position
    _titleAlignment = AlignmentTween(
      begin: Alignment.center,
      end: const Alignment(0, -0.65),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.82, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Subtitle fades in under the header
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 0.92, curve: Curves.easeIn),
      ),
    );

    // 5. Login controls slide/fade up from below
    _loginOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.82, 1.0, curve: Curves.easeIn),
      ),
    );

    _loginSlide = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.82, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Start boot sequence
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Ink color: soft cream (#f5f3ee) for premium hello aesthetic, charcoal (#0b0c14) for high-contrast light mode
    final inkColor = isDarkMode ? const Color(0xFFF5F3EE) : LuminaColors.textPrimary;
    final primaryTextColor = isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary;
    final secondaryTextColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary;

    return Scaffold(
      body: Stack(
        children: [
          // Background Color Base: Linear Gradient matching Apple Hello HTML Page
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B0C14),
                  Color(0xFF1A1530),
                ],
              ),
            ),
          ),

          // Radial Glow Layer A (upper-left side)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.4, -0.4),
                  radius: 1.2,
                  colors: [
                    Color(0x503A1F3D),
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Radial Glow Layer B (lower-right side)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.5, 0.4),
                  radius: 1.1,
                  colors: [
                    Color(0x5016314A),
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Stellar Ambient Particles Layer
          const Positioned.fill(
            child: AmbientParticles(count: 35),
          ),

          // Animated Brand Header Area (Cursive drawing + subtitle)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Align(
                alignment: _titleAlignment.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Title (iOS hello cursive handwriting animation using Pacifico Marker paths)
                    Transform.scale(
                      scale: _titleScale.value,
                      child: SizedBox(
                        width: 300,
                        height: 171, // Matches 3079 x 1756 aspect ratio of the Pacifico viewBox
                        child: CustomPaint(
                          painter: CursiveLuminaPainter(
                            paths: _parsedPaths,
                            progress: _drawingProgress.value,
                            color: inkColor,
                            strokeWidth: 22.0, // Matches data.strokeWidth of Pacifico in HTML
                          ),
                        ),
                      ),
                    ),

                    // Brand Subtitle
                    Opacity(
                      opacity: _subtitleOpacity.value,
                      child: Padding(
                        padding: const EdgeInsets.only(top: LuminaSpacing.xs),
                        child: Text(
                          'Someone to talk to. Always.',
                          style: GoogleFonts.dmSans(
                            fontSize: LuminaTypography.sizeBody,
                            color: secondaryTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Animated Bottom Login Options
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _loginOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _loginSlide.value),
                    child: child,
                  ),
                );
              },
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: LuminaSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Auth state error text
                      if (authState.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: LuminaSpacing.md),
                          child: Text(
                            authState.errorMessage!,
                            style: GoogleFonts.dmSans(
                              color: LuminaColors.accentRed,
                              fontSize: LuminaTypography.sizeBody,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Continue with Google Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  try {
                                    await ref.read(authProvider.notifier).signInWithGoogle();
                                  } catch (e) {
                                    debugPrint("Google login exception: $e");
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: LuminaColors.textPrimary,
                            elevation: 1,
                            shadowColor: const Color(0x18000000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(LuminaRadius.button),
                              side: const BorderSide(color: LuminaColors.divider, width: 0.8),
                            ),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(LuminaColors.textPrimary),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/google_logo.svg',
                                      width: 20,
                                      height: 20,
                                    ),
                                    const SizedBox(width: LuminaSpacing.md),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w500,
                                        fontSize: LuminaTypography.sizeBody,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: LuminaSpacing.md),

                      // Continue as Guest Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  try {
                                    await ref.read(authProvider.notifier).signInAsGuest();
                                  } catch (e) {
                                    debugPrint("Guest login exception: $e");
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryTextColor,
                            side: BorderSide(
                              color: isDarkMode
                                  ? LuminaColors.divider.withValues(alpha: 0.5)
                                  : LuminaColors.divider,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(LuminaRadius.button),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                                color: primaryTextColor,
                              ),
                              const SizedBox(width: LuminaSpacing.md),
                              Text(
                                'Continue as Guest',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: LuminaTypography.sizeBody,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: LuminaSpacing.xxl),

                      // Cozy Footer Terms
                      Padding(
                        padding: const EdgeInsets.only(bottom: LuminaSpacing.lg),
                        child: Text(
                          'By logging in, you agree to Lumina\'s cozy terms & privacy guidelines.',
                          style: GoogleFonts.dmSans(
                            fontSize: LuminaTypography.sizeCaption,
                            color: isDarkMode ? LuminaColors.textSecDark : LuminaColors.textTimestamp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CursiveLuminaPainter extends CustomPainter {
  final List<Path> paths;
  final double progress; // Overall drawing progress from 0.0 to 1.0 (corresponds to _drawingProgress.value)
  final Color color;
  final double strokeWidth;

  CursiveLuminaPainter({
    required this.paths,
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (paths.isEmpty) return;

    // viewBox: 0 0 3079 1756
    final scaleX = size.width / 3079;
    final scaleY = size.height / 1756;

    canvas.save();
    // Recreate transform: translate(0, 1303) scale(1, -1)
    canvas.scale(scaleX, scaleY);
    canvas.translate(0, 1303);
    canvas.scale(1, -1);

    // Timing parameters:
    // Tracing runs from traceProgress = 0.0 to 1.0 (75% of drawing timeline)
    // Solid fill runs from fillProgress = 0.0 to 1.0 (remaining 25% of timeline)
    double traceProgress = (progress / 0.75).clamp(0.0, 1.0);
    double fillProgress = progress >= 0.75 ? ((progress - 0.75) / 0.25).clamp(0.0, 1.0) : 0.0;

    final n = paths.length;
    final slot = 1.0 / n;
    const overlap = 1.7;

    final paintStroke = Paint()
      ..color = color.withValues(alpha: 1.0 - fillProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()
      ..color = color.withValues(alpha: fillProgress)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final path = paths[i];

      // Delay formula matching CSS: i * slot * 0.55
      final delay = i * slot * 0.55;
      final dur = slot * overlap;

      double letterProgress = 0.0;
      if (traceProgress > delay) {
        letterProgress = ((traceProgress - delay) / dur).clamp(0.0, 1.0);
      }

      // 1. Draw outline trace stroke
      if (letterProgress > 0.0 && fillProgress < 1.0) {
        final activePath = Path();
        for (final metric in path.computeMetrics()) {
          final metricLength = metric.length;
          final drawLength = metricLength * letterProgress;
          activePath.addPath(metric.extractPath(0, drawLength), Offset.zero);
        }
        canvas.drawPath(activePath, paintStroke);
      }

      // 2. Draw solid fill shapes
      if (fillProgress > 0.0) {
        canvas.drawPath(path, paintFill);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CursiveLuminaPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// Robust custom SVG path string to Flutter Path converter
Path parseSvgPathData(String pathData) {
  final Path path = Path();
  final RegExp regExp = RegExp(r'([MmLlHhVvCcSsQqTtAaZz])|([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)');
  final matches = regExp.allMatches(pathData).toList();

  int index = 0;
  String currentCommand = '';
  double lastX = 0;
  double lastY = 0;

  List<double> getArgs(int count) {
    final args = <double>[];
    while (args.length < count && index < matches.length) {
      final match = matches[index];
      final val = double.tryParse(match.group(0) ?? '');
      if (val != null) {
        args.add(val);
        index++;
      } else {
        break;
      }
    }
    return args;
  }

  while (index < matches.length) {
    final match = matches[index];
    final group = match.group(0) ?? '';
    final isCommand = RegExp(r'[MmLlHhVvCcSsQqTtAaZz]').hasMatch(group);

    if (isCommand) {
      currentCommand = group;
      index++;
    }

    if (currentCommand == 'M') {
      final args = getArgs(2);
      if (args.length == 2) {
        lastX = args[0];
        lastY = args[1];
        path.moveTo(lastX, lastY);
      }
    } else if (currentCommand == 'm') {
      final args = getArgs(2);
      if (args.length == 2) {
        lastX += args[0];
        lastY += args[1];
        path.moveTo(lastX, lastY);
      }
    } else if (currentCommand == 'L') {
      final args = getArgs(2);
      if (args.length == 2) {
        lastX = args[0];
        lastY = args[1];
        path.lineTo(lastX, lastY);
      }
    } else if (currentCommand == 'l') {
      final args = getArgs(2);
      if (args.length == 2) {
        lastX += args[0];
        lastY += args[1];
        path.lineTo(lastX, lastY);
      }
    } else if (currentCommand == 'H') {
      final args = getArgs(1);
      if (args.length == 1) {
        lastX = args[0];
        path.lineTo(lastX, lastY);
      }
    } else if (currentCommand == 'h') {
      final args = getArgs(1);
      if (args.length == 1) {
        lastX += args[0];
        path.lineTo(lastX, lastY);
      }
    } else if (currentCommand == 'V') {
      final args = getArgs(1);
      if (args.length == 1) {
        lastY = args[0];
        path.lineTo(lastX, lastY);
      }
    } else if (currentCommand == 'v') {
      final args = getArgs(1);
      if (args.length == 1) {
        lastY += args[0];
        path.lineTo(lastX, lastY);
      }
    } else if (currentCommand == 'Q') {
      final args = getArgs(4);
      if (args.length == 4) {
        path.quadraticBezierTo(args[0], args[1], args[2], args[3]);
        lastX = args[2];
        lastY = args[3];
      }
    } else if (currentCommand == 'q') {
      final args = getArgs(4);
      if (args.length == 4) {
        path.quadraticBezierTo(lastX + args[0], lastY + args[1], lastX + args[2], lastY + args[3]);
        lastX += args[2];
        lastY += args[3];
      }
    } else if (currentCommand == 'Z' || currentCommand == 'z') {
      path.close();
    } else {
      index++;
    }
  }
  return path;
}
