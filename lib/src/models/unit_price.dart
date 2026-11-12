import 'json.dart';

/// A unit price in one pack size, from [Medicine.unitPrices].
class UnitPrice {
  UnitPrice(this.json);

  final Map<String, dynamic> json;

  /// The pack size as the source names it, or `null`.
  String? get size => json['size'] as String?;

  /// MRP in BDT of one unit in that size.
  double get price => toDouble(json['price']);
}
