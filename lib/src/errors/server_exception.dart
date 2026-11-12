import 'oushodh_exception.dart';

/// 5xx `internal`: a fault on the API's side.
class ServerException extends OushodhException {
  ServerException(super.message, {super.status, super.code});
}
