import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';

class DistrictTile extends StatelessWidget {
  const DistrictTile({
    super.key,
    required this.district,
    required this.selected,
    required this.onTap,
  });

  final DistrictSummary district;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final offices = district.offices.map((office) => office.name).join(', ');
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? colors.accent : colors.ruleSoft),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      district.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.cardTitle(context, size: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selected)
                    Icon(Icons.check_circle, size: 18, color: colors.accent),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                [
                  district.jurisdiction,
                  district.region ?? '',
                  'Tier ${district.attributionCode}',
                ].where((part) => part.isNotEmpty).join(' · '),
                style: AppTheme.meta(context, size: 11.5),
              ),
              if (district.representativeName != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Rep. ${district.representativeName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.meta(context, size: 11),
                ),
              ],
              if (offices.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  offices,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.meta(context, size: 11),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('House 2027', style: AppTheme.meta(context, size: 10.5)),
                  const SizedBox(width: 6),
                  Text(
                    compactPeso(district.house2027),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'NEP ${compactPeso(district.nep2027)}',
                    style: AppTheme.meta(context, size: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
