import 'medicine.dart';
import 'monograph.dart';

/// One medicine, with its medical text. Only [Oushodh.getMedicine] returns it.
class MedicineDetail extends Medicine {
  MedicineDetail(super.json);

  /// `null` when no source gives the medicine any text.
  Monograph? get monograph {
    final value = json['monograph'] as Map<String, dynamic>?;

    return value == null ? null : Monograph(value);
  }
}
