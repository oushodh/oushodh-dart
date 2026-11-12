import 'json.dart';
import 'medicine.dart';

/// One page of medicines from [Oushodh.listMedicines].
class Page {
  Page(this.json);

  final Map<String, dynamic> json;

  /// The medicines on this page.
  List<Medicine> get items => mapList(json['items']).map(Medicine.new).toList();

  /// Pass it back as `cursor` for the next page. `null` on the last page.
  String? get next => json['next'] as String?;

  /// How many medicines match, across all pages.
  int get total => json['total'] as int;
}
