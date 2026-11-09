import 'package:flutter/material.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // One upright card in both themes: the same shape, radius, border and
    // shadow geometry, so light and dark differ only in colour.
    // Its own semantics node, so a screen reader reads the card as one stop
    // instead of running it into the rest of the list item.
    return Semantics(container: true, child: _surface(isDark));
  }

  Widget _surface(bool isDark) {
    // Black reads as depth on navy paper; on cream it turns muddy, so the
    // light theme casts the card's own navy instead.
    final shade = isDark ? Colors.black : const Color(0xFF1B2A4A);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF121820), Color(0xFF1B2A4A), Color(0xFF2A3A5C)]
              : const [Color(0xFF1B2A4A), Color(0xFF2C4068), Color(0xFF3A5280)],
          stops: const [0, 0.55, 1],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: shade.withValues(alpha: isDark ? 0.5 : 0.24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: shade.withValues(alpha: isDark ? 0.28 : 0.16),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -50,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.1 : 0.24),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-0.8, -1),
                    end: const Alignment(0.9, 1),
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.08 : 0.22),
                      Colors.white.withValues(alpha: 0.03),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.38, 0.7],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.2 : 0.55),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF121820).withValues(alpha: 0),
                      const Color(0xFF121820).withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class HeroEyebrow extends StatelessWidget {
  const HeroEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      style: TextStyle(
        fontSize: 10.5,
        letterSpacing: 0.9,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.78),
      ),
    );
  }
}
