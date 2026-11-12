import 'oushodh_exception.dart';

/// The request did not reach the API, or no answer came back.
class ConnectionException extends OushodhException {
  ConnectionException(super.message);
}
