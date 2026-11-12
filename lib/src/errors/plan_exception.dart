import 'oushodh_exception.dart';

/// 403 `plan_expired` or `plan_limit`.
class PlanException extends OushodhException {
  PlanException(super.message, {super.status, super.code});
}
