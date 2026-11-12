import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oushodh/oushodh.dart';

// Run by io_test.dart with OUSHODH_API_KEY set or unset. Prints whether the key reached the header, never the key.
Future<void> main() async {
  try {
    final oushodh = Oushodh(
      httpClient: MockClient((request) async {
        final sent = request.headers['Authorization'] == 'Bearer oush_test_env';

        return http.Response(
          '{"client":"${sent ? 'ok' : 'wrong'}","id_profile":"default","medicines":0,"last_import":null}',
          200,
        );
      }),
    );

    print((await oushodh.meta()).client);
  } on OushodhException catch (e) {
    print(e.message);
  }
}
