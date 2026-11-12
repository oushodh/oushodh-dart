import 'connection_exception.dart';

/// One attempt took longer than the client's timeout.
class OushodhTimeoutException extends ConnectionException {
  OushodhTimeoutException(super.message);
}
