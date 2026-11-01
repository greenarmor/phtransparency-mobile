import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

class CircleMenuButton extends StatefulWidget {
  const CircleMenuButton({super.key, required this.onOpen});

  final Future<void> Function() onOpen;

  @override
  State<CircleMenuButton> createState() => _CircleMenuButtonState();
}

class _CircleMenuButtonState extends State<CircleMenuButton>
    with TickerProviderStateMixin {
  static const _spinDuration = Duration(milliseconds: 300);
  static const _sheetLeadIn = Duration(milliseconds: 90);

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 70),
    reverseDuration: const Duration(milliseconds: 90),
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: _spinDuration,
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.88, end: 1)
      .animate(
        CurvedAnimation(
          parent: _enter,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        ),
      );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );
  late final Animation<double> _turn = Tween<double>(
    begin: 0,
    end: 0.5,
  ).animate(CurvedAnimation(parent: _spin, curve: Curves.easeInOutCubic));
  late final Animation<double> _bump = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.12,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 45,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.12,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 55,
    ),
  ]).animate(_spin);

  bool _open = false;
  bool _busy = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
    } else {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _press.dispose();
    _spin.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_busy) return;
    _busy = true;
    HapticFeedback.lightImpact();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    setState(() => _open = true);

    if (!reduceMotion) {
      unawaited(_press.forward());
      unawaited(_spin.forward());
      await Future<void>.delayed(_sheetLeadIn);
    }

    if (!mounted) return;
    await widget.onOpen();

    if (!mounted) return;
    setState(() => _open = false);
    _busy = false;
    if (!reduceMotion) {
      unawaited(_press.reverse());
      unawaited(_spin.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: 'Choose a place',
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_press, _spin]),
          builder: (context, child) {
            final pressScale = 1 - 0.07 * _press.value;
            final bump = reduceMotion ? 1.0 : _bump.value;
            return Transform.scale(scale: pressScale * bump, child: child);
          },
          child: FadeTransition(
            opacity: reduceMotion ? const AlwaysStoppedAnimation(1) : _fade,
            child: ScaleTransition(
              scale: reduceMotion ? const AlwaysStoppedAnimation(1) : _scale,
              child: Material(
                color: colors.accent,
                elevation: 12,
                shadowColor: colors.accent.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _tap,
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(
                      child: RotationTransition(
                        turns: reduceMotion
                            ? const AlwaysStoppedAnimation(0.0)
                            : _turn,
                        child: AnimatedSwitcher(
                          duration: Duration(
                            milliseconds: reduceMotion ? 0 : 180,
                          ),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                          child: Icon(
                            _open ? Icons.close : Icons.travel_explore,
                            key: ValueKey(_open),
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
