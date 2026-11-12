import 'json.dart';

/// The MRP of one unit, from [Prices.unit].
class UnitAmount {
  UnitAmount(this.json);

  final Map<String, dynamic> json;

  /// MRP in BDT.
  double get amount => toDouble(json['amount']);

  /// The source that states this price.
  String get source => json['source'] as String;
}
