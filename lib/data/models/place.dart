sealed class PlaceSelection {
  const PlaceSelection();

  String get title;
  String get subtitle;
  String get storageKey;

  Map<String, dynamic> toJson();

  static PlaceSelection fromJson(Map<String, dynamic> json) {
    switch (json['kind']) {
      case 'region':
        return RegionPlace(
          key: json['key'] as String? ?? '',
          label: json['label'] as String? ?? '',
          name: json['name'] as String?,
        );
      case 'district':
        return DistrictPlace(
          id: json['id'] as String? ?? '',
          label: json['label'] as String? ?? '',
          jurisdiction: json['jurisdiction'] as String? ?? '',
          regionKey: json['region_key'] as String?,
        );
      case 'named':
        return NamedPlace(
          q: json['q'] as String? ?? '',
          label: json['label'] as String? ?? '',
        );
      default:
        return const NationalPlace();
    }
  }
}

class NationalPlace extends PlaceSelection {
  const NationalPlace();

  @override
  String get title => 'All Philippines';

  @override
  String get subtitle => 'Every region, district and office';

  @override
  String get storageKey => 'national';

  @override
  Map<String, dynamic> toJson() => {'kind': 'national'};

  @override
  bool operator ==(Object other) => other is NationalPlace;

  @override
  int get hashCode => 0;
}

class RegionPlace extends PlaceSelection {
  const RegionPlace({required this.key, required this.label, this.name});

  final String key;
  final String label;
  final String? name;

  @override
  String get title => label;

  @override
  String get subtitle => name == null ? 'Region' : 'Region · $name';

  @override
  String get storageKey => 'region:$key';

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'region',
    'key': key,
    'label': label,
    'name': name,
  };

  @override
  bool operator ==(Object other) => other is RegionPlace && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

class DistrictPlace extends PlaceSelection {
  const DistrictPlace({
    required this.id,
    required this.label,
    required this.jurisdiction,
    this.regionKey,
  });

  final String id;
  final String label;
  final String jurisdiction;
  final String? regionKey;

  @override
  String get title => label;

  @override
  String get subtitle => jurisdiction;

  @override
  String get storageKey => 'district:$id';

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'district',
    'id': id,
    'label': label,
    'jurisdiction': jurisdiction,
    'region_key': regionKey,
  };

  @override
  bool operator ==(Object other) => other is DistrictPlace && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class NamedPlace extends PlaceSelection {
  const NamedPlace({required this.q, required this.label});

  final String q;
  final String label;

  @override
  String get title => label;

  @override
  String get subtitle => 'Lines whose name says "$q"';

  @override
  String get storageKey => 'named:$q';

  @override
  Map<String, dynamic> toJson() => {'kind': 'named', 'q': q, 'label': label};

  @override
  bool operator ==(Object other) => other is NamedPlace && other.q == q;

  @override
  int get hashCode => q.hashCode;
}
