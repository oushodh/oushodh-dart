/// The medical text of a medicine, as its source wrote it, in English.
///
/// It is information for professionals, not medical advice. Some text holds HTML tags.
class Monograph {
  Monograph(this.json);

  final Map<String, dynamic> json;

  String get source => json['source'] as String;

  String? get indications => json['indications'] as String?;

  String? get composition => json['composition'] as String?;

  String? get pharmacology => json['pharmacology'] as String?;

  String? get dosage => json['dosage'] as String?;

  String? get interactions => json['interactions'] as String?;

  String? get contraindications => json['contraindications'] as String?;

  String? get sideEffects => json['side_effects'] as String?;

  String? get pregnancyLactation => json['pregnancy_lactation'] as String?;

  String? get precautions => json['precautions'] as String?;

  String? get overdose => json['overdose'] as String?;

  String? get storage => json['storage'] as String?;
}
