import 'package:intl/intl.dart';

const dash = '-';

String compactPeso(int? amount) {
  if (amount == null) return dash;
  final abs = amount.abs();
  if (abs >= 1000000000) {
    return '₱${(amount / 1000000000).toStringAsFixed(2)}B';
  }
  if (abs >= 1000000) {
    return '₱${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (abs >= 1000) {
    return '₱${(amount / 1000).toStringAsFixed(0)}K';
  }
  return '₱${NumberFormat.decimalPattern().format(amount)}';
}

String fullPeso(int? amount) =>
    amount == null ? dash : '₱${NumberFormat.decimalPattern().format(amount)}';

String signedCompactPeso(int? amount) {
  if (amount == null) return dash;
  if (amount == 0) return '₱0';
  final sign = amount > 0 ? '+' : '−';
  return '$sign${compactPeso(amount.abs())}';
}

String plural(int count, String one, [String? many]) =>
    '$count ${count == 1 ? one : (many ?? '${one}s')}';

String titleCasePlace(String value) => value
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map(
      (word) => word.length == 1
          ? word.toUpperCase()
          : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

String shortDate(String? iso) {
  if (iso == null) return dash;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return dash;
  return DateFormat('d MMM yyyy').format(parsed.toLocal());
}

const groupTitles = <String, String>{
  'house_only': 'In the House bill only',
  'nep_only': 'In the NEP only',
  'unchanged': 'Same amount in both',
  'increased': 'Higher in the House bill',
  'decreased': 'Lower in the House bill',
  'scope_review': 'Different stretch',
};

const groupShort = <String, String>{
  'house_only': 'House only',
  'nep_only': 'NEP only',
  'unchanged': 'Same',
  'increased': 'Higher',
  'decreased': 'Lower',
  'scope_review': 'Scope review',
};

const groupOrder = <String>[
  'house_only',
  'nep_only',
  'unchanged',
  'increased',
  'decreased',
  'scope_review',
];
