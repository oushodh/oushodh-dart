// Every model wraps the JSON the API sent. Typed getters read from `json`, and
// fields the SDK does not know yet stay in it.

double toDouble(Object? value) => (value as num).toDouble();

double? doubleOrNull(Object? value) => (value as num?)?.toDouble();

List<Map<String, dynamic>> mapList(Object? value) => (value as List).cast<Map<String, dynamic>>();
