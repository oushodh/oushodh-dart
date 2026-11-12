import 'json.dart';

/// The unit price in one pack size, from [Prices.sizes].
class SizeAmount {
  SizeAmount(this.json);

  final Map<String, dynamic> json;

  /// The pack size as the source names it, or `null`.
  String? get size => json['size'] as String?;

  /// MRP in BDT.
  double get amount => toDouble(json['amount']);

  /// The source that states this price.
  String get source => json['source'] as String;
}
