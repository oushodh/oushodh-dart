import 'oushodh_exception.dart';

/// 404 `not_found`.
class NotFoundException extends OushodhException {
  NotFoundException(super.message, {super.status, super.code});
}
