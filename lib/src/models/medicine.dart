import 'json.dart';
import 'prices.dart';
import 'unit_price.dart';

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
  double? get price => doubleOrNull(json['price']);

  /// What [price] buys. Kept for older clients: read [prices].
  String? get pricePer => json['price_per'] as String?;

  /// Where the price comes from.
  String? get priceSource => json['price_source'] as String?;

  /// The unit price in each pack size. Kept for older clients: read [Prices.sizes].
  List<UnitPrice> get unitPrices => mapList(json['unit_prices']).map(UnitPrice.new).toList();

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
