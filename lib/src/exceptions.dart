/// The base of every error the SDK throws.
///
/// [status] is the HTTP status and [code] the API's error code. Both are
/// `null` when no answer came back. Match on the class or on [code], never on
/// [message]: the message is for people and may change.
class OushodhException implements Exception {
  OushodhException(this.message, {this.status, this.code});

  final String message;
  final int? status;
  final String? code;

  @override
  String toString() {
    final parts = [?status, ?code].join(' ');

    return parts.isEmpty ? '$runtimeType: $message' : '$runtimeType ($parts): $message';
  }
}

/// 400 `bad_request`: a bad parameter.
class BadRequestException extends OushodhException {
  BadRequestException(super.message, {super.status, super.code});
}

/// 401 `unauthorized`: no key, an unknown key or a revoked key.
class AuthenticationException extends OushodhException {
  AuthenticationException(super.message, {super.status, super.code});
}

/// 403 `plan_expired` or `plan_limit`.
class PlanException extends OushodhException {
  PlanException(super.message, {super.status, super.code});
}

/// 404 `not_found`.
class NotFoundException extends OushodhException {
  NotFoundException(super.message, {super.status, super.code});
}

/// 429 `rate_limited` or `quota_exceeded`.
///
/// [retryAfter] is the `Retry-After` header in seconds. For `quota_exceeded`
/// it counts the seconds to the start of next month.
class RateLimitException extends OushodhException {
  RateLimitException(super.message, {super.status, super.code, this.retryAfter});

  final int? retryAfter;
}

/// 5xx `internal`: a fault on the API's side.
class ServerException extends OushodhException {
  ServerException(super.message, {super.status, super.code});
}

/// The request did not reach the API, or no answer came back.
class ConnectionException extends OushodhException {
  ConnectionException(super.message);
}

/// One attempt took longer than the client's timeout.
class OushodhTimeoutException extends ConnectionException {
  OushodhTimeoutException(super.message);
}

OushodhException exceptionFor(int status, Object? body, int? retryAfter) {
  final error = body is Map ? body['error'] : null;
  final code = error is Map && error['code'] is String ? error['code'] as String : null;
  final message = error is Map && error['message'] is String ? error['message'] as String : 'HTTP $status';

  if (status == 400) {
    return BadRequestException(message, status: status, code: code);
  }

  if (status == 401) {
    return AuthenticationException(message, status: status, code: code);
  }

  if (status == 403) {
    return PlanException(message, status: status, code: code);
  }

  if (status == 404) {
    return NotFoundException(message, status: status, code: code);
  }

  if (status == 429) {
    return RateLimitException(message, status: status, code: code, retryAfter: retryAfter);
  }

  if (status >= 500) {
    return ServerException(message, status: status, code: code);
  }

  return OushodhException(message, status: status, code: code);
}
