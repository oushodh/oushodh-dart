import 'json.dart';
import 'medicine.dart';

/// The answer of [Oushodh.search].
class SearchResult {
  SearchResult(this.json);

  final Map<String, dynamic> json;

  /// The best matches first, at most `limit`.
  List<Medicine> get items => mapList(json['items']).map(Medicine.new).toList();

  /// How many medicines match, including those past `limit`.
  int get total => json['total'] as int;
}
