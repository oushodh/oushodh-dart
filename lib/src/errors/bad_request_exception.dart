import 'oushodh_exception.dart';

/// 400 `bad_request`: a bad parameter.
class BadRequestException extends OushodhException {
  BadRequestException(super.message, {super.status, super.code});
}
