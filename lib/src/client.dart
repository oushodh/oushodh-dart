import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'env.dart' if (dart.library.io) 'env_io.dart';
import 'exceptions.dart';
import 'models.dart';

/// The SDK's version, sent in the `User-Agent` header.
const version = '0.1.0';

/// A client for the Oushodh API `/v1`.
class Oushodh {
  /// Builds a client from an API key.
  ///
  /// With no [apiKey], it reads the `OUSHODH_API_KEY` environment variable
  /// where the platform has one (not on the web). With no key at all, it
  /// throws an [OushodhException].
  ///
  /// [timeout] applies to each attempt. [maxRetries] counts the retries after
  /// a `429 rate_limited`, a `5xx` or a network error. Pass [httpClient] to
  /// use your own `http.Client`, for tests or a proxy; [close] then leaves it open.
  Oushodh({
    String? apiKey,
    String baseUrl = 'https://api.oushodh.dev',
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
    http.Client? httpClient,
  }) : _apiKey = apiKey ?? environmentKey() ?? '',
       baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
       _http = httpClient ?? http.Client(),
       _ownsHttp = httpClient == null {
    if (_apiKey.isEmpty) {
      throw OushodhException('No API key. Pass apiKey or set the OUSHODH_API_KEY environment variable.');
    }
  }

  final String baseUrl;
  final Duration timeout;
  final int maxRetries;
  final String _apiKey;
  final http.Client _http;
  final bool _ownsHttp;
  final _random = Random();

  /// The account the key belongs to. Use it to check that a key works.
  Future<Meta> meta() async {
    return Meta(await _json('/v1/meta', {}));
  }

  /// One page of medicines, in the order of their permanent number.
  ///
  /// [limit] is 1 to 500 (the API's default is 100). [cursor] is the `next`
  /// value from the page before. [updatedSince] keeps only medicines changed
  /// at or after that time, oldest change first. [q] keeps only medicines
  /// whose brand, generic or manufacturer starts with these words, or whose ID matches.
  Future<Page> listMedicines({int? limit, String? cursor, DateTime? updatedSince, String? q}) async {
    final query = {
      'limit': ?limit?.toString(),
      'cursor': ?cursor,
      'updated_since': ?(updatedSince == null ? null : _formatTime(updatedSince)),
      'q': ?q,
    };

    return Page(await _json('/v1/medicines', query));
  }

  /// Every medicine, page after page, following `next` to the end.
  Stream<Medicine> medicines({int? limit, String? cursor, DateTime? updatedSince, String? q}) async* {
    var next = cursor;

    while (true) {
      final page = await listMedicines(limit: limit, cursor: next, updatedSince: updatedSince, q: q);

      for (final medicine in page.items) {
        yield medicine;
      }

      if (page.next == null) {
        return;
      }

      next = page.next;
    }
  }

  /// The best matches for a person typing a name, best match first. [limit] is 1 to 50.
  Future<SearchResult> search(String q, {int? limit}) async {
    return SearchResult(await _json('/v1/medicines/search', {'q': q, 'limit': ?limit?.toString()}));
  }

  /// One medicine by its ID in any profile, an old ID, or its UUID.
  Future<MedicineDetail> getMedicine(String ref) async {
    return MedicineDetail(await _json('/v1/medicines/${Uri.encodeComponent(ref)}', {}));
  }

  /// The address of a picture, from its file name. It needs no key.
  String imageUrl(String file) {
    return '$baseUrl/v1/images/${Uri.encodeComponent(file)}';
  }

  /// The bytes of a picture, from its file name. The request carries no key.
  Future<Uint8List> getImage(String file) async {
    final response = await _request(Uri.parse(imageUrl(file)), auth: false);

    return response.bodyBytes;
  }

  /// Closes the HTTP client the SDK made. A client you passed in stays open.
  void close() {
    if (_ownsHttp) {
      _http.close();
    }
  }

  Future<Map<String, dynamic>> _json(String path, Map<String, String> query) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _request(query.isEmpty ? uri : uri.replace(queryParameters: query), auth: true);

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<http.Response> _request(Uri uri, {required bool auth}) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _send(uri, auth: auth);
      } on OushodhException catch (error) {
        final delay = _retryDelay(error, attempt);

        if (delay == null) {
          rethrow;
        }

        await Future<void>.delayed(delay);
      }
    }
  }

  Future<http.Response> _send(Uri uri, {required bool auth}) async {
    final headers = {'User-Agent': 'oushodh-dart/$version', if (auth) 'Authorization': 'Bearer $_apiKey'};
    final http.Response response;

    try {
      // shortcut: a timed-out request is abandoned, not aborted; use http's AbortableRequest if that ever matters.
      response = await _http.get(uri, headers: headers).timeout(timeout);
    } on TimeoutException {
      throw OushodhTimeoutException('The request timed out after ${timeout.inMilliseconds} ms');
    } on http.ClientException {
      throw ConnectionException('The request could not reach the Oushodh API');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    Object? body;

    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      body = null;
    }

    throw exceptionFor(response.statusCode, body, int.tryParse(response.headers['retry-after'] ?? ''));
  }

  Duration? _retryDelay(OushodhException error, int attempt) {
    if (attempt >= maxRetries) {
      return null;
    }

    if (error is RateLimitException) {
      // quota_exceeded's Retry-After runs to the next month, so waiting is never right.
      if (error.code != 'rate_limited') {
        return null;
      }

      final retryAfter = error.retryAfter;

      return retryAfter == null ? _backoff(attempt) : Duration(seconds: retryAfter);
    }

    if (error is ServerException || error is ConnectionException) {
      return _backoff(attempt);
    }

    return null;
  }

  Duration _backoff(int attempt) {
    final base = min(8000, 500 * pow(2, attempt).toInt());

    return Duration(milliseconds: base ~/ 2 + _random.nextInt(base ~/ 2 + 1));
  }
}

String _formatTime(DateTime time) {
  final utc = time.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');

  return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-${two(utc.day)}'
      'T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}Z';
}
