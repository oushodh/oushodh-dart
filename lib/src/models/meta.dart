/// The account the key belongs to, from [Oushodh.meta].
class Meta {
  Meta(this.json);

  final Map<String, dynamic> json;

  /// The account the key belongs to.
  String get client => json['client'] as String;

  /// The ID profile your medicine IDs come from.
  String get idProfile => json['id_profile'] as String;

  /// How many medicines your key reads.
  int get medicines => json['medicines'] as int;

  /// When the data was last imported.
  DateTime? get lastImport {
    final value = json['last_import'] as String?;

    return value == null ? null : DateTime.parse(value);
  }
}
