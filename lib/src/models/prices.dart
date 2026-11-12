import 'json.dart';
import 'pack_amount.dart';
import 'size_amount.dart';
import 'strip_amount.dart';
import 'unit_amount.dart';

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
  List<SizeAmount> get sizes => mapList(json['sizes']).map(SizeAmount.new).toList();

  /// The MRP of one strip, or `null` when no source states it.
  StripAmount? get strip {
    final value = json['strip'] as Map<String, dynamic>?;

    return value == null ? null : StripAmount(value);
  }

  /// The MRP of each pack or box, cheapest first. Empty when none is listed.
  List<PackAmount> get packs => mapList(json['packs']).map(PackAmount.new).toList();
}
