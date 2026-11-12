import 'oushodh_exception.dart';

/// 429 `rate_limited` or `quota_exceeded`.
///
/// [retryAfter] is the `Retry-After` header in seconds. For `quota_exceeded`
/// it counts the seconds to the start of next month.
class RateLimitException extends OushodhException {
  RateLimitException(super.message, {super.status, super.code, this.retryAfter});

  final int? retryAfter;
}
