import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../errors/connection_exception.dart';
import '../errors/oushodh_exception.dart';
import '../errors/rate_limit_exception.dart';
import '../errors/server_exception.dart';
import '../errors/timeout_exception.dart';
import '../version.dart';
import 'exception_for.dart';

/// Sends GET requests with the key, the timeout and the retries.
class Transport {
  Transport({required this.apiKey, required this.timeout, required this.maxRetries, required this.httpClient});

  final String apiKey;
  final Duration timeout;
  final int maxRetries;
  final http.Client httpClient;
  final _random = Random();

  Future<http.Response> get(Uri uri, {required bool auth}) async {
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
    final headers = {'User-Agent': 'oushodh-dart/$version', if (auth) 'Authorization': 'Bearer $apiKey'};
    final http.Response response;

    try {
      // shortcut: a timed-out request is abandoned, not aborted; use http's AbortableRequest if that ever matters.
      response = await httpClient.get(uri, headers: headers).timeout(timeout);
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
