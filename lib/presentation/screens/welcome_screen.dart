import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/theme_providers.dart';
import '../widgets/app_logo.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: colors.paper,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.paper, colors.paper2],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -140,
                right: -110,
                child: _Glow(size: 340, opacity: 0.9),
              ),
              Positioned(
                bottom: -160,
                left: -110,
                child: _Glow(size: 300, opacity: 0.55),
              ),
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 52,
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
            ],
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
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: AppLogo(
            asset: 'assets/images/welcome_logo.png',
            darkAsset: 'assets/images/welcome_logo_dark.png',
            size: 165,
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Text(
            'BetterGovPH',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: colors.ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'A community-run portal for the Philippines',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: colors.ink3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'FY ${AppConfig.fiscalYear} · NEP vs House bill',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: colors.accent,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome. See what every place in the Philippines gets: its FY 2027 '
          'projects in the NEP and in the House bill side by side, the page '
          'each figure sits on, and what has been enacted for it since 2020.',
          style: TextStyle(fontSize: 14, height: 1.5, color: colors.ink2),
        ),
        const SizedBox(height: 20),
        const _ThemeChooser(),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
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

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.accentSoft.withValues(alpha: opacity),
            colors.accentSoft.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.countdown});

  final Animation<double> countdown;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                backgroundColor: colors.accentSoft,
                valueColor: AlwaysStoppedAnimation(colors.accent),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              remaining == 0
                  ? 'Opening the budget…'
                  : 'Opening the budget automatically in $remaining s',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.ink3),
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
    final colors = context.colors;
    final mode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: colors.ink,
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
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onSelectionChanged: (value) =>
                ref.read(themeModeProvider.notifier).select(value.first),
          ),
        ),
      ],
    );
  }
}
