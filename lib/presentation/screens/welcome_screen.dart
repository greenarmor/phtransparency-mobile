import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/theme_providers.dart';
import '../widgets/app_logo.dart';

class _SplashPalette {
  static const cream = Color(0xFFF3EFE4);
  static const ink = Color(0xFF17171B);
  static const inkSoft = Color(0xFF3C3C42);
  static const red = Color(0xFFC8262C);
  static const navy = Color(0xFF1B2A4A);
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const stay = Duration(seconds: 30);

  late final AnimationController _countdown = AnimationController(
    vsync: this,
    duration: stay,
  );
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _countdown.addStatusListener((status) {
      if (status == AnimationStatus.completed) _continue();
    });
    _countdown.forward();
  }

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  void _continue() {
    if (_left || !mounted) return;
    _left = true;
    context.go('/');
  }

  /// The poster is cream whatever the app theme is, so it always reads with
  /// the light theme: dark-mode greys on cream fall to about 2:1.
  static final _posterTheme = AppTheme.light();

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Theme(data: _posterTheme, child: _scaffold(reduceMotion)),
    );
  }

  Widget _scaffold(bool reduceMotion) {
    return Scaffold(
      backgroundColor: _SplashPalette.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: reduceMotion ? 0 : 480),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _WelcomeBody(
                  countdown: _countdown,
                  onContinue: _continue,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeBody extends StatelessWidget {
  const _WelcomeBody({required this.countdown, required this.onContinue});

  final Animation<double> countdown;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SplashEyebrow(),
        const SizedBox(height: 14),
        const _SplashHero(),
        const SizedBox(height: 22),
        const _ThemeChooser(),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: _SplashPalette.ink,
              foregroundColor: _SplashPalette.cream,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            child: const Text('Continue to the budget'),
          ),
        ),
        const SizedBox(height: 16),
        _Countdown(countdown: countdown),
      ],
    );
  }
}

class _SplashEyebrow extends StatelessWidget {
  const _SplashEyebrow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AppLogo(size: 26, asset: 'assets/images/welcome_logo.png'),
        SizedBox(width: 9),
        Text(
          'BetterGov.Ph',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: _SplashPalette.ink,
          ),
        ),
      ],
    );
  }
}

class _SplashHero extends StatelessWidget {
  const _SplashHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -width * 0.06,
              right: -width * 0.14,
              child: SizedBox(
                width: width * 0.88,
                height: width * 1.12,
                child: const _FistBackground(),
              ),
            ),
            const Positioned.fill(child: _TitleScrim()),
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 4, bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SplashWord(
                          'WE ARE',
                          color: _SplashPalette.ink,
                          size: 82,
                        ),
                        _SplashWord(
                          'NOT',
                          color: _SplashPalette.red,
                          size: 118,
                        ),
                        _SplashWord(
                          'IGNORANT',
                          color: _SplashPalette.ink,
                          size: 76,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Inserted and adjusted projects in the 2027 House budget bill. '
                    'We read every single one.',
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: _SplashPalette.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TitleScrim extends StatelessWidget {
  const _TitleScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _SplashPalette.cream,
            Color(0xE6F3EFE4),
            Color(0x00F3EFE4),
          ],
          stops: [0.0, 0.38, 0.78],
        ),
      ),
    );
  }
}

class _SplashWord extends StatelessWidget {
  const _SplashWord(this.text, {required this.color, required this.size});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.anton(
        color: color,
        fontSize: size,
        height: 0.94,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _FistBackground extends StatelessWidget {
  const _FistBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/campaign_fist.webp',
      fit: BoxFit.contain,
      alignment: Alignment.centerRight,
      errorBuilder: (_, _, _) => Image.network(
        AppConfig.campaignFistUrl,
        fit: BoxFit.contain,
        alignment: Alignment.centerRight,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _FistFallback(),
      ),
    );
  }
}

class _FistFallback extends StatelessWidget {
  const _FistFallback();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FistFallbackPainter());
  }
}

class _FistFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.92, size.height * 0.08);
    final rayPaint = Paint()
      ..color = _SplashPalette.red
      ..style = PaintingStyle.fill;

    const firstAngle = 1.95;
    const step = 0.16;
    for (var i = 0; i < 7; i++) {
      final start = firstAngle + i * step;
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..arcTo(
          Rect.fromCircle(center: origin, radius: size.width * 1.7),
          start,
          0.075,
          false,
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }

    final paperPaint = Paint()
      ..color = _SplashPalette.navy
      ..style = PaintingStyle.fill;
    final bandPaint = Paint()
      ..color = _SplashPalette.red
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width * 0.52, size.height * 0.34);
    for (final angle in [-0.42, -0.18, 0.06]) {
      canvas.save();
      canvas.rotate(angle);
      canvas.drawRect(Rect.fromLTWH(-36, -48, 74, 100), paperPaint);
      canvas.restore();
    }
    canvas.drawRect(Rect.fromLTWH(-40, 8, 84, 11), bandPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FistFallbackPainter oldDelegate) => false;
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.countdown});

  final Animation<double> countdown;

  @override
  Widget build(BuildContext context) {
    final seconds = _WelcomeScreenState.stay.inSeconds;
    return AnimatedBuilder(
      animation: countdown,
      builder: (context, _) {
        final remaining = ((1 - countdown.value) * seconds).ceil().clamp(
          0,
          seconds,
        );
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: 1 - countdown.value,
                minHeight: 4,
                backgroundColor: const Color(0xFFF3D9D4),
                valueColor: const AlwaysStoppedAnimation(_SplashPalette.red),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              remaining == 0
                  ? 'Opening the budget…'
                  : 'Opening the budget automatically in $remaining s',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _SplashPalette.inkSoft),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeChooser extends ConsumerWidget {
  const _ThemeChooser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appearance',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _SplashPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined, size: 16),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 16),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 16),
                label: Text('Dark'),
              ),
            ],
            selected: {mode},
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              // The poster art runs behind this row: opaque segments keep the
              // Light and Dark labels off the red halftone.
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? null
                    : _SplashPalette.cream,
              ),
            ),
            onSelectionChanged: (value) =>
                ref.read(themeModeProvider.notifier).select(value.first),
          ),
        ),
      ],
    );
  }
}
