import 'json.dart';

/// The MRP of one pack or box, from [Prices.packs].
class PackAmount {
  PackAmount(this.json);

  final Map<String, dynamic> json;

  /// MRP in BDT.
  double get amount => toDouble(json['amount']);

  /// How many units the pack holds, or `null` when the source does not say.
  double? get units => doubleOrNull(json['units']);

  /// The pack as the source names it.
  String get label => json['label'] as String;

  /// The source that states this price.
  String get source => json['source'] as String;
}
