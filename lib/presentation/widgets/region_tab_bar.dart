import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class RegionTabBar extends StatelessWidget {
  const RegionTabBar({
    super.key,
    required this.index,
    required this.onSelected,
  });

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(top: BorderSide(color: colors.ruleSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              Expanded(
                child: _Tab(
                  key: const ValueKey('region-tab-money'),
                  label: 'Money',
                  icon: Icons.account_balance_wallet_outlined,
                  selectedIcon: Icons.account_balance_wallet,
                  selected: index == 0,
                  onTap: () => onSelected(0),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Tab(
                  key: const ValueKey('region-tab-enacted'),
                  label: 'Enacted',
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  selected: index == 1,
                  onTap: () => onSelected(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.accent : colors.ink3;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 130);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: duration,
              curve: Curves.easeOut,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: color),
                  duration: duration,
                  curve: Curves.easeOut,
                  builder: (context, value, _) => Icon(
                    selected ? selectedIcon : icon,
                    size: 22,
                    color: value ?? color,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: Curves.easeOut,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(onTap: onTap, child: const SizedBox.expand()),
            ),
          ),
        ],
      ),
    );
  }
}
