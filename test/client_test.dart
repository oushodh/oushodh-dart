import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oushodh/oushodh.dart';
import 'package:test/test.dart';

const key = 'oush_test_123';

Map<String, dynamic> medicine(String id) {
  return {
    'id': id,
    'uuid': '01a1ba6f-f4d6-7143-ac84-9376f520eef8',
    'brand': 'Napa',
    'category': null,
    'product_name': 'Napa 500 mg Tablet',
    'product_image': null,
    'images': <String>[],
    'unit': 'Strip',
    'size': '10 Tablets',
    'price': 1.2,
    'price_per': 'unit',
    'price_source': 'dgda_price',
    'unit_prices': [
      {'size': null, 'price': 1},
    ],
    'prices': {
      'currency': 'BDT',
      'unit': {'amount': 1.2, 'source': 'dgda_price'},
      'sizes': <Object>[],
      'strip': {'amount': 12, 'units': 10, 'source': 'dgda_price'},
      'packs': [
        {'amount': 360, 'units': null, 'label': "30's pack", 'source': 'dgda_price'},
      ],
    },
    'description_en': null,
    'description_bn': null,
    'dosage_form': 'Tablet',
    'strength': '500 mg',
    'generic_name': 'Paracetamol',
    'manufacturer': null,
    'source_url': null,
    'last_updated': '2026-11-09T15:27:34Z',
    'dgda_listed': true,
    'medicine_type': 'allopathic',
    'new_field': 'kept',
  };
}

http.Response json(Object body, {int status = 200, Map<String, String> headers = const {}}) {
  return http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...headers});
}

http.Response error(int status, String code, {Map<String, String> headers = const {}}) {
  return json(
    {
      'error': {'code': code, 'message': 'Message for people'},
    },
    status: status,
    headers: headers,
  );
}

/// A client whose every request goes to [handler], with the requests kept in [requests].
(Oushodh, List<http.Request>) client(Future<http.Response> Function(http.Request) handler, {int maxRetries = 2}) {
  final requests = <http.Request>[];
  final mock = MockClient((request) {
    requests.add(request);

    return handler(request);
  });

  return (Oushodh(apiKey: key, baseUrl: 'http://api.test/', maxRetries: maxRetries, httpClient: mock), requests);
}

void main() {
  group('routes', () {
    test('meta sends the key and the user agent', () async {
      final (oushodh, requests) = client(
        (_) async => json({'client': 'Test', 'id_profile': 'default', 'medicines': 3, 'last_import': null}),
      );
      final meta = await oushodh.meta();

      expect(requests.single.url.toString(), 'http://api.test/v1/meta');
      expect(requests.single.method, 'GET');
      expect(requests.single.headers['Authorization'], 'Bearer $key');
      expect(requests.single.headers['User-Agent'], 'oushodh-dart/$version');
      expect(meta.client, 'Test');
      expect(meta.idProfile, 'default');
      expect(meta.medicines, 3);
      expect(meta.lastImport, isNull);
    });

    test('listMedicines sends every parameter and reads the page', () async {
      final (oushodh, requests) = client(
        (_) async => json({
          'items': [medicine('MED-000001')],
          'next': 'abc',
          'total': 9,
        }),
      );
      final page = await oushodh.listMedicines(
        limit: 500,
        cursor: 'xyz',
        updatedSince: DateTime.utc(2026, 11, 8, 9, 30, 0, 123),
        q: 'napa 500',
      );

      expect(requests.single.url.path, '/v1/medicines');
      expect(requests.single.url.queryParameters, {
        'limit': '500',
        'cursor': 'xyz',
        'updated_since': '2026-11-08T09:30:00Z',
        'q': 'napa 500',
      });
      expect(page.total, 9);
      expect(page.next, 'abc');

      final napa = page.items.single;

      expect(napa.id, 'MED-000001');
      expect(napa.productName, 'Napa 500 mg Tablet');
      expect(napa.price, 1.2);
      expect(napa.unitPrices.single.price, 1.0);
      expect(napa.prices.unit?.amount, 1.2);
      expect(napa.prices.strip?.units, 10);
      expect(napa.prices.packs.single.units, isNull);
      expect(napa.prices.sizes, isEmpty);
      expect(napa.lastUpdated, DateTime.utc(2026, 11, 9, 15, 27, 34));
      expect(napa.dgdaListed, isTrue);
      expect(napa.medicineType, 'allopathic');
      expect(napa.json['new_field'], 'kept');
    });

    test('updatedSince is sent in UTC', () async {
      final (oushodh, requests) = client((_) async => json({'items': <Object>[], 'next': null, 'total': 0}));

      await oushodh.listMedicines(updatedSince: DateTime.parse('2026-11-08T15:30:00+06:00'));

      expect(requests.single.url.queryParameters['updated_since'], '2026-11-08T09:30:00Z');
    });

    test('listMedicines with no parameters sends no query', () async {
      final (oushodh, requests) = client((_) async => json({'items': <Object>[], 'next': null, 'total': 0}));

      await oushodh.listMedicines();

      expect(requests.single.url.toString(), 'http://api.test/v1/medicines');
    });

    test('search sends q and limit', () async {
      final (oushodh, requests) = client(
        (_) async => json({
          'items': [medicine('MED-000001')],
          'total': 40,
        }),
      );
      final hits = await oushodh.search('napa', limit: 10);

      expect(requests.single.url.path, '/v1/medicines/search');
      expect(requests.single.url.queryParameters, {'q': 'napa', 'limit': '10'});
      expect(hits.total, 40);
      expect(hits.items.single.brand, 'Napa');
    });

    test('getMedicine escapes the ref and reads the monograph', () async {
      final (oushodh, requests) = client(
        (_) async => json({
          ...medicine('MED-012933'),
          'monograph': {
            'source': 'label',
            'indications': 'Fever',
            'composition': null,
            'pharmacology': null,
            'dosage': null,
            'interactions': null,
            'contraindications': null,
            'side_effects': null,
            'pregnancy_lactation': null,
            'precautions': null,
            'overdose': null,
            'storage': null,
          },
        }),
      );
      final detail = await oushodh.getMedicine('MED/1 ?');

      expect(requests.single.url.toString(), 'http://api.test/v1/medicines/MED%2F1%20%3F');
      expect(detail.monograph?.indications, 'Fever');
      expect(detail.monograph?.sideEffects, isNull);
    });

    test('a medicine with no monograph', () async {
      final (oushodh, _) = client((_) async => json({...medicine('MED-000001'), 'monograph': null}));

      expect((await oushodh.getMedicine('MED-000001')).monograph, isNull);
    });
  });

  test('medicines pages to the end', () async {
    final (oushodh, requests) = client((request) async {
      final cursor = request.url.queryParameters['cursor'];

      if (cursor == null) {
        return json({
          'items': [medicine('MED-000001'), medicine('MED-000002')],
          'next': 'page2',
          'total': 3,
        });
      }

      return json({
        'items': [medicine('MED-000003')],
        'next': null,
        'total': 3,
      });
    });
    final ids = await oushodh.medicines(limit: 2, q: 'napa').map((m) => m.id).toList();

    expect(ids, ['MED-000001', 'MED-000002', 'MED-000003']);
    expect(requests.map((r) => r.url.queryParameters['cursor']), [null, 'page2']);
    expect(
      requests.every((r) => r.url.queryParameters['limit'] == '2' && r.url.queryParameters['q'] == 'napa'),
      isTrue,
    );
  });

  group('images', () {
    const file = '50d858e0985ecc7f60418aaf0cc5ab587f42c2570a884095a9e8ccacd0f6545c.jpg';

    test('imageUrl builds the address', () {
      final (oushodh, _) = client((_) async => http.Response('', 200));

      expect(oushodh.imageUrl(file), 'http://api.test/v1/images/$file');
      expect(oushodh.imageUrl('a/b.jpg'), 'http://api.test/v1/images/a%2Fb.jpg');
    });

    test('getImage returns the bytes and sends no key', () async {
      final (oushodh, requests) = client((_) async => http.Response.bytes([1, 2, 3], 200));
      final bytes = await oushodh.getImage(file);

      expect(bytes, [1, 2, 3]);
      expect(requests.single.url.path, '/v1/images/$file');
      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('a missing picture throws NotFoundException', () async {
      final (oushodh, _) = client((_) async => error(404, 'not_found'));

      await expectLater(oushodh.getImage(file), throwsA(isA<NotFoundException>()));
    });
  });

  group('errors', () {
    final families = {
      400: ('bad_request', isA<BadRequestException>()),
      401: ('unauthorized', isA<AuthenticationException>()),
      403: ('plan_limit', isA<PlanException>()),
      404: ('not_found', isA<NotFoundException>()),
      429: ('quota_exceeded', isA<RateLimitException>()),
      500: ('internal', isA<ServerException>()),
    };

    for (final MapEntry(key: status, value: (code, matcher)) in families.entries) {
      test('$status throws its family with status, code and message', () async {
        final (oushodh, _) = client((_) async => error(status, code), maxRetries: 0);

        await expectLater(
          oushodh.meta(),
          throwsA(
            allOf(
              matcher,
              isA<OushodhException>()
                  .having((e) => e.status, 'status', status)
                  .having((e) => e.code, 'code', code)
                  .having((e) => e.message, 'message', 'Message for people'),
            ),
          ),
        );
      });
    }

    test('403 plan_expired is a PlanException', () async {
      final (oushodh, _) = client((_) async => error(403, 'plan_expired'));

      await expectLater(oushodh.meta(), throwsA(isA<PlanException>().having((e) => e.code, 'code', 'plan_expired')));
    });

    test('a body that is not JSON gives no code and HTTP <status>', () async {
      final (oushodh, _) = client((_) async => http.Response('<html>bad gateway</html>', 502), maxRetries: 0);

      await expectLater(
        oushodh.meta(),
        throwsA(
          isA<ServerException>()
              .having((e) => e.status, 'status', 502)
              .having((e) => e.code, 'code', isNull)
              .having((e) => e.message, 'message', 'HTTP 502'),
        ),
      );
    });

    test('a network failure throws ConnectionException', () async {
      final (oushodh, _) = client((_) async => throw http.ClientException('refused'), maxRetries: 0);

      await expectLater(oushodh.meta(), throwsA(isA<ConnectionException>().having((e) => e.status, 'status', isNull)));
    });

    test('a slow answer throws OushodhTimeoutException', () async {
      final mock = MockClient((_) => Future.delayed(const Duration(milliseconds: 200), () => http.Response('{}', 200)));
      final oushodh = Oushodh(apiKey: key, timeout: const Duration(milliseconds: 20), maxRetries: 0, httpClient: mock);

      await expectLater(oushodh.meta(), throwsA(isA<OushodhTimeoutException>()));
    });

    test('the key never appears in an error', () async {
      for (final status in [400, 401, 403, 404, 429, 500]) {
        final (oushodh, _) = client((_) async => error(status, 'x'), maxRetries: 0);

        try {
          await oushodh.meta();
          fail('expected an error');
        } on OushodhException catch (e) {
          expect(e.toString(), isNot(contains(key)));
          expect(e.message, isNot(contains(key)));
        }
      }

      final (oushodh, _) = client((_) async => throw http.ClientException('refused'), maxRetries: 0);

      await expectLater(oushodh.meta(), throwsA(predicate((Object e) => !e.toString().contains(key))));
    });

    test('no key at all throws at construction', () {
      expect(() => Oushodh(apiKey: ''), throwsA(isA<OushodhException>()));
    });
  });

  group('retries', () {
    test('429 rate_limited waits Retry-After, then retries', () async {
      var calls = 0;
      final (oushodh, requests) = client((_) async {
        calls++;

        return calls == 1
            ? error(429, 'rate_limited', headers: {'retry-after': '1'})
            : json({'client': 'Test', 'id_profile': 'default', 'medicines': 0, 'last_import': null});
      });
      final watch = Stopwatch()..start();
      final meta = await oushodh.meta();

      expect(meta.client, 'Test');
      expect(requests, hasLength(2));
      expect(watch.elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 950)));
    });

    test('429 quota_exceeded throws at once with retryAfter', () async {
      final (oushodh, requests) = client((_) async => error(429, 'quota_exceeded', headers: {'retry-after': '86400'}));

      await expectLater(
        oushodh.meta(),
        throwsA(isA<RateLimitException>().having((e) => e.retryAfter, 'retryAfter', 86400)),
      );
      expect(requests, hasLength(1));
    });

    test('a 5xx is retried, then succeeds', () async {
      var calls = 0;
      final (oushodh, requests) = client((_) async {
        calls++;

        return calls == 1
            ? error(503, 'internal')
            : json({'client': 'Test', 'id_profile': 'default', 'medicines': 0, 'last_import': null});
      });

      expect((await oushodh.meta()).client, 'Test');
      expect(requests, hasLength(2));
    });

    test('a network error is retried', () async {
      var calls = 0;
      final (oushodh, requests) = client((_) async {
        calls++;

        if (calls == 1) {
          throw http.ClientException('reset');
        }

        return json({'client': 'Test', 'id_profile': 'default', 'medicines': 0, 'last_import': null});
      });

      expect((await oushodh.meta()).client, 'Test');
      expect(requests, hasLength(2));
    });

    test('retries stop after maxRetries', () async {
      final (oushodh, requests) = client((_) async => error(500, 'internal'), maxRetries: 1);

      await expectLater(oushodh.meta(), throwsA(isA<ServerException>()));
      expect(requests, hasLength(2));
    });

    test('404 is never retried', () async {
      final (oushodh, requests) = client((_) async => error(404, 'not_found'));

      await expectLater(oushodh.getMedicine('MED-999999'), throwsA(isA<NotFoundException>()));
      expect(requests, hasLength(1));
    });
  });
}
