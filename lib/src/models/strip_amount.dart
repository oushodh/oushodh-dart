import 'json.dart';

/// The MRP of one strip, from [Prices.strip].
class StripAmount {
  StripAmount(this.json);

  final Map<String, dynamic> json;

  /// MRP in BDT.
  double get amount => toDouble(json['amount']);

  /// How many units the strip holds, or `null` when the source does not say.
  double? get units => doubleOrNull(json['units']);

  /// The source that states this price.
  String get source => json['source'] as String;
}
