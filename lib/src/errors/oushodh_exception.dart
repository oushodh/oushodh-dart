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
