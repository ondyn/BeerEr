import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts a raw Firestore document map into a form that
/// json_serializable `fromJson` can handle.
///
/// Firestore returns `Timestamp` objects for date fields, but
/// generated `fromJson` expects ISO-8601 strings.  This helper
/// walks the top-level values and converts every [Timestamp] to a
/// `String` so the models stay free of any Firebase dependency.
Map<String, dynamic> firestoreDoc(
  String id,
  Map<String, dynamic> data,
) {
  return {
    'id': id,
    for (final e in data.entries)
      e.key: e.value is Timestamp
          ? (e.value as Timestamp).toDate().toIso8601String()
          : e.value,
  };
}
