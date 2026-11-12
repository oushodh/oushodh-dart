import 'oushodh_exception.dart';

/// 401 `unauthorized`: no key, an unknown key or a revoked key.
class AuthenticationException extends OushodhException {
  AuthenticationException(super.message, {super.status, super.code});
}
