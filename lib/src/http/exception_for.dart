import '../errors/authentication_exception.dart';
import '../errors/bad_request_exception.dart';
import '../errors/not_found_exception.dart';
import '../errors/oushodh_exception.dart';
import '../errors/plan_exception.dart';
import '../errors/rate_limit_exception.dart';
import '../errors/server_exception.dart';

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
