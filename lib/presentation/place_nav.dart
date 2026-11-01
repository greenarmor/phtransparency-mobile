import '../data/models/place.dart';

const regionAllKey = 'all';

String placePath(PlaceSelection place, {String? fallbackRegionKey}) {
  switch (place) {
    case NationalPlace():
      return '/';
    case RegionPlace():
      return '/region/${place.key}';
    case DistrictPlace():
      return '/region/${place.regionKey ?? fallbackRegionKey ?? regionAllKey}';
    case NamedPlace():
      return '/region/${fallbackRegionKey ?? regionAllKey}';
  }
}
