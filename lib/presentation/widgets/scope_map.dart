import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/services/scope_service.dart';
import 'common.dart';

class ScopeMap extends StatefulWidget {
  const ScopeMap({
    super.key,
    required this.points,
    this.interactive = false,
    this.height = 300,
    this.onPointTap,
  });

  final List<ScopedProject> points;
  final bool interactive;
  final double height;
  final ValueChanged<ScopedProject>? onPointTap;

  @override
  State<ScopeMap> createState() => _ScopeMapState();
}

class _ScopeMapState extends State<ScopeMap> {
  static const _tileErrorLimit = 3;

  int _tileErrors = 0;
  ScopedProject? _selected;

  bool get _showTiles => _tileErrors < _tileErrorLimit;

  @override
  void didUpdateWidget(ScopeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selected;
    if (selected != null &&
        !widget.points.any((item) => item.key == selected.key)) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (widget.points.isEmpty) {
      return _MapShell(
        height: widget.height,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No line in this view publishes coordinates.',
              textAlign: TextAlign.center,
              style: AppTheme.meta(context),
            ),
          ),
        ),
      );
    }

    final coords = [
      for (final item in widget.points)
        LatLng(item.project.lat!, item.project.lon!),
    ];
    final bounds = LatLngBounds.fromPoints(coords);
    final largest = widget.points.fold<int>(
      0,
      (value, item) => math.max(value, _amountOf(item)),
    );
    final shown = widget.points.take(_maxMarkers).toList();

    return _MapShell(
      height: widget.height,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(30),
                maxZoom: 13,
              ),
              minZoom: 3,
              maxZoom: 17,
              backgroundColor: colors.paper2,
              interactionOptions: InteractionOptions(
                flags: widget.interactive
                    ? InteractiveFlag.all & ~InteractiveFlag.rotate
                    : InteractiveFlag.none,
              ),
              onTap: (tapPosition, point) {
                if (_selected != null) setState(() => _selected = null);
              },
            ),
            children: [
              if (_showTiles)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ph.bettergov.budget',
                  maxZoom: 18,
                  errorTileCallback: (tile, error, stackTrace) {
                    if (!mounted) return;
                    setState(() => _tileErrors++);
                  },
                ),
              MarkerLayer(
                markers: [
                  for (final item in shown)
                    if (item.key != _selected?.key)
                      Marker(
                        point: LatLng(item.project.lat!, item.project.lon!),
                        width: _hitSize(item, largest),
                        height: _hitSize(item, largest),
                        child: _dot(item, largest, context.colors),
                      ),
                  if (_selected != null)
                    Marker(
                      point: LatLng(
                        _selected!.project.lat!,
                        _selected!.project.lon!,
                      ),
                      width: _hitSize(_selected!, largest),
                      height: _hitSize(_selected!, largest),
                      child: _dot(
                        _selected!,
                        largest,
                        context.colors,
                        active: true,
                      ),
                    ),
                ],
              ),
              if (_showTiles)
                const RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
            ],
          ),
          if (!_showTiles)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: _MapNote(
                icon: Icons.cloud_off,
                text:
                    'Map tiles unavailable. The dots still show the '
                    'coordinates the documents publish.',
              ),
            ),
          if (_selected != null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: _PinCallout(
                item: _selected!,
                onClose: () => setState(() => _selected = null),
                onOpen: widget.onPointTap == null
                    ? null
                    : () => widget.onPointTap!(_selected!),
              ),
            ),
          if (shown.length < widget.points.length)
            Positioned(
              left: 8,
              top: 8,
              child: _MapNote(
                icon: Icons.layers_outlined,
                text:
                    'Showing the ${shown.length} largest of '
                    '${widget.points.length} lines with coordinates.',
              ),
            ),
        ],
      ),
    );
  }

  static const _maxMarkers = 700;

  int _amountOf(ScopedProject item) =>
      item.project.housePhp ?? item.project.nepPhp ?? 0;

  double _diameter(ScopedProject item, int largest) {
    if (largest <= 0) return 10;
    final ratio = _amountOf(item) / largest;
    return (10 + 14 * math.sqrt(ratio)).clamp(8, 26);
  }

  double _hitSize(ScopedProject item, int largest) =>
      math.max(_diameter(item, largest), _minHit);

  static const _minHit = 44.0;

  Widget _dot(
    ScopedProject item,
    int largest,
    AppColors colors, {
    bool active = false,
  }) {
    final color = StatusPill.colorFor(item.project.bridgeGroup, colors);
    final size = _diameter(item, largest) * (active ? 1.35 : 1);
    final dot = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: active ? 1 : 0.82),
          border: Border.all(color: Colors.white, width: active ? 2 : 1.4),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
      ),
    );

    return GestureDetector(
      key: ValueKey('map-dot-${item.project.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = item),
      child: Tooltip(
        message: item.project.title,
        waitDuration: const Duration(milliseconds: 300),
        child: Semantics(
          button: true,
          label:
              '${item.project.title}, '
              '${compactPeso(_amountOf(item))}',
          child: Center(child: dot),
        ),
      ),
    );
  }
}

class _MapShell extends StatelessWidget {
  const _MapShell({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.paper2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.ruleSoft),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MapNote extends StatelessWidget {
  const _MapNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.colors.paper.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.ruleSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.ink3),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: AppTheme.meta(context, size: 11))),
        ],
      ),
    );
  }
}

class _PinCallout extends StatelessWidget {
  const _PinCallout({required this.item, required this.onClose, this.onOpen});

  final ScopedProject item;
  final VoidCallback onClose;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final row = item.project;
    final amount = row.housePhp ?? row.nepPhp;
    return Material(
      color: context.colors.paper,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.cardTitle(context, size: 13.5),
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: colors.ink3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            MetaLine(children: [row.office, row.program]),
            const SizedBox(height: 8),
            Row(
              children: [
                AmountText(amount, size: 14),
                const SizedBox(width: 8),
                StatusPill(
                  group: row.bridgeGroup,
                  label: groupShort[row.bridgeGroup] ?? row.statusLabel,
                  held: row.held,
                  compact: true,
                ),
                const Spacer(),
                if (onOpen != null)
                  TextButton(
                    onPressed: onOpen,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Open line'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
