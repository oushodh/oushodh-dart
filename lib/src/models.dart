// Every model wraps the JSON the API sent. Typed getters read from [json], and
// fields the SDK does not know yet stay in it.

double _double(Object? value) => (value as num).toDouble();

double? _doubleOrNull(Object? value) => (value as num?)?.toDouble();

List<Map<String, dynamic>> _maps(Object? value) => (value as List).cast<Map<String, dynamic>>();

/// One medicine: one brand in one strength and dosage form.
///
/// A value no source gives is `null`, never a blank, a zero or an estimate.
class Medicine {
  Medicine(this.json);

  /// The JSON object as the API sent it, unknown fields included.
  final Map<String, dynamic> json;

  /// The medicine's ID in your account's ID profile. It never changes and is never reused.
  String get id => json['id'] as String;

  /// The key that never changes. Store it to match a medicine across syncs.
  String get uuid => json['uuid'] as String;

  String get brand => json['brand'] as String;

  /// Reserved for a symptom category. `null` for every medicine today.
  String? get category => json['category'] as String?;

  /// Brand, strength and dosage form together.
  String get productName => json['product_name'] as String;

  /// The address of the medicine's picture, or `null` when there is none.
  String? get productImage => json['product_image'] as String?;

  /// Every picture of the medicine, [productImage] first.
  List<String> get images => (json['images'] as List).cast<String>();

  /// The pack's unit, such as `Strip` or `Bottle`.
  String? get unit => json['unit'] as String?;

  /// The pack's size, such as `10 Tablets` or `200 ml`.
  String? get size => json['size'] as String?;

  /// MRP in BDT of what [pricePer] names. Kept for older clients: read [prices].
  double? get price => _doubleOrNull(json['price']);

  /// What [price] buys. Kept for older clients: read [prices].
  String? get pricePer => json['price_per'] as String?;

  /// Where the price comes from.
  String? get priceSource => json['price_source'] as String?;

  /// The unit price in each pack size. Kept for older clients: read [Prices.sizes].
  List<UnitPrice> get unitPrices => _maps(json['unit_prices']).map(UnitPrice.new).toList();

  /// Every MRP the sources state for the medicine.
  Prices get prices => Prices(json['prices'] as Map<String, dynamic>);

  String? get descriptionEn => json['description_en'] as String?;

  String? get descriptionBn => json['description_bn'] as String?;

  String? get dosageForm => json['dosage_form'] as String?;

  String? get strength => json['strength'] as String?;

  String? get genericName => json['generic_name'] as String?;

  String? get manufacturer => json['manufacturer'] as String?;

  /// The page the record was read from.
  String? get sourceUrl => json['source_url'] as String?;

  /// When any field of this record last changed. Sync uses it.
  DateTime get lastUpdated => DateTime.parse(json['last_updated'] as String);

  /// `true` when a DGDA registration (DAR number) links to the medicine.
  bool get dgdaListed => json['dgda_listed'] as bool;

  /// The DGDA register that lists it: `allopathic`, `homoeopathic`, `herbal`,
  /// `ayurvedic` or `unani`. `null` when no register lists it.
  String? get medicineType => json['medicine_type'] as String?;
}

/// One medicine, with its medical text. Only [Oushodh.getMedicine] returns it.
class MedicineDetail extends Medicine {
  MedicineDetail(super.json);

  /// `null` when no source gives the medicine any text.
  Monograph? get monograph {
    final value = json['monograph'] as Map<String, dynamic>?;

    return value == null ? null : Monograph(value);
  }
}

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

/// A unit price in one pack size, from [Medicine.unitPrices].
class UnitPrice {
  UnitPrice(this.json);

  final Map<String, dynamic> json;

  /// The pack size as the source names it, or `null`.
  String? get size => json['size'] as String?;

  /// MRP in BDT of one unit in that size.
  double get price => _double(json['price']);
}

/// Every MRP the sources state for a medicine: per unit, per strip and per pack.
class Prices {
  Prices(this.json);

  final Map<String, dynamic> json;

  /// Always `BDT`.
  String get currency => json['currency'] as String;

  /// The MRP of one unit, or `null` when no source states it or it differs by pack size.
  UnitAmount? get unit {
    final value = json['unit'] as Map<String, dynamic>?;

    return value == null ? null : UnitAmount(value);
  }

  /// The unit price in each pack size, cheapest first. Empty otherwise.
  List<SizeAmount> get sizes => _maps(json['sizes']).map(SizeAmount.new).toList();

  /// The MRP of one strip, or `null` when no source states it.
  StripAmount? get strip {
    final value = json['strip'] as Map<String, dynamic>?;

    return value == null ? null : StripAmount(value);
  }

  /// The MRP of each pack or box, cheapest first. Empty when none is listed.
  List<PackAmount> get packs => _maps(json['packs']).map(PackAmount.new).toList();
}

/// The MRP of one unit, from [Prices.unit].
class UnitAmount {
  UnitAmount(this.json);

  final Map<String, dynamic> json;

  /// MRP in BDT.
  double get amount => _double(json['amount']);

  /// The source that states this price.
  String get source => json['source'] as String;
}

/// The unit price in one pack size, from [Prices.sizes].
class SizeAmount {
  SizeAmount(this.json);

  final Map<String, dynamic> json;

  /// The pack size as the source names it, or `null`.
  String? get size => json['size'] as String?;

  /// MRP in BDT.
  double get amount => _double(json['amount']);

  /// The source that states this price.
  String get source => json['source'] as String;
}

/// The MRP of one strip, from [Prices.strip].
class StripAmount {
  StripAmount(this.json);

  final Map<String, dynamic> json;

  /// MRP in BDT.
  double get amount => _double(json['amount']);

  /// How many units the strip holds, or `null` when the source does not say.
  double? get units => _doubleOrNull(json['units']);

  /// The source that states this price.
  String get source => json['source'] as String;
}

/// The MRP of one pack or box, from [Prices.packs].
class PackAmount {
  PackAmount(this.json);

  final Map<String, dynamic> json;

  /// MRP in BDT.
  double get amount => _double(json['amount']);

  /// How many units the pack holds, or `null` when the source does not say.
  double? get units => _doubleOrNull(json['units']);

  /// The pack as the source names it.
  String get label => json['label'] as String;

  /// The source that states this price.
  String get source => json['source'] as String;
}

/// One page of medicines from [Oushodh.listMedicines].
class Page {
  Page(this.json);

  final Map<String, dynamic> json;

  /// The medicines on this page.
  List<Medicine> get items => _maps(json['items']).map(Medicine.new).toList();

  /// Pass it back as `cursor` for the next page. `null` on the last page.
  String? get next => json['next'] as String?;

  /// How many medicines match, across all pages.
  int get total => json['total'] as int;
}

/// The answer of [Oushodh.search].
class SearchResult {
  SearchResult(this.json);

  final Map<String, dynamic> json;

  /// The best matches first, at most `limit`.
  List<Medicine> get items => _maps(json['items']).map(Medicine.new).toList();

  /// How many medicines match, including those past `limit`.
  int get total => json['total'] as int;
}

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
