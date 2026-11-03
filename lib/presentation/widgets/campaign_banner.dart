import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/campaign_providers.dart';

class CampaignBanner extends StatelessWidget {
  const CampaignBanner({super.key, this.summary});

  final CampaignSummary? summary;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(child: _RedactedLines()),
        const Positioned(
          top: -6,
          right: -28,
          child: _Fist(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 56, bottom: 2),
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
                    _Word('WE ARE', color: colors.ink, size: 42),
                    _Word('NOT', color: colors.accent, size: 56),
                    _Word('IGNORANT', color: colors.ink, size: 42),
                  ],
                ),
              ),
              if (summary != null) ...[
                const SizedBox(height: 12),
                _Lead(summary: summary!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Word extends StatelessWidget {
  const _Word(this.text, {required this.color, required this.size});

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
        height: 0.98,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _Lead extends StatelessWidget {
  const _Lead({required this.summary});

  final CampaignSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final count = summary.addedRows + summary.raisedRows + summary.loweredRows;
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 14.5,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: colors.ink,
        ),
        children: [
          TextSpan(
            text: NumberFormat.decimalPattern().format(count),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: colors.ink,
            ),
          ),
          const TextSpan(
            text:
                ' inserted and adjusted projects in the 2027 House budget '
                'bill. We read every single one.',
          ),
        ],
      ),
    );
  }
}

class _RedactedLines extends StatelessWidget {
  const _RedactedLines();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RedactedLinesPainter(AppColors.of(context).ink),
    );
  }
}

class _RedactedLinesPainter extends CustomPainter {
  _RedactedLinesPainter(this.ink);

  final Color ink;
  static const _rowHeight = 13.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = ink.withValues(alpha: 0.07);
    var y = 10.0;
    var row = 0;
    while (y < size.height - 6) {
      var x = 0.0;
      var column = 0;
      while (x < size.width - 10) {
        final seed = (row * 31 + column * 17) % 13;
        final width = 8.0 + (seed % 4) * 5.0;
        if (seed % 5 != 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, width, 2.6), paint);
        }
        x += width + 6;
        column++;
      }
      y += _rowHeight;
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant _RedactedLinesPainter oldDelegate) =>
      oldDelegate.ink != ink;
}

class _Fist extends StatelessWidget {
  const _Fist();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 168,
      child: Image.asset(
        'assets/images/campaign_fist.webp',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Image.network(
          AppConfig.campaignFistUrl,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const _FistFallback(),
        ),
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
    final origin = Offset(size.width * 0.94, size.height * 0.10);
    final rayPaint = Paint()
      ..color = const Color(0xFFC8262C)
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
      ..color = const Color(0xFF1B2A4A)
      ..style = PaintingStyle.fill;
    final bandPaint = Paint()
      ..color = const Color(0xFFC8262C)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width * 0.52, size.height * 0.30);
    for (final angle in [-0.42, -0.18, 0.06]) {
      canvas.save();
      canvas.rotate(angle);
      canvas.drawRect(Rect.fromLTWH(-30, -40, 62, 84), paperPaint);
      canvas.restore();
    }
    canvas.drawRect(Rect.fromLTWH(-34, 6, 70, 9), bandPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FistFallbackPainter oldDelegate) => false;
}
