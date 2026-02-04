/// Utilities for mapping colony "year" values to Firestore collection names.
///
/// Background:
/// - For legacy data, nests/eggs for year 2022 are stored in the `Nest`
///   collection instead of `2022`.

const int kLegacyNestCollectionYear = 2022;
const String kLegacyNestCollectionName = 'Nest';

String yearToNestCollectionName(int year) {
  return year == kLegacyNestCollectionYear
      ? kLegacyNestCollectionName
      : year.toString();
}

/// Accepts either an `int` year (e.g. `2026`) or a string collection name
/// (e.g. `"2026"` or `"Nest"`).
String nestCollectionNameFromYearOrName(Object? yearOrName) {
  if (yearOrName == null) {
    return yearToNestCollectionName(DateTime.now().year);
  }
  if (yearOrName is int) {
    return yearToNestCollectionName(yearOrName);
  }
  final asString = yearOrName.toString();
  final asInt = int.tryParse(asString);
  if (asInt != null) {
    return yearToNestCollectionName(asInt);
  }
  return asString;
}
