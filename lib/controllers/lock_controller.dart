import 'package:flutter/foundation.dart';
import 'package:genauth/services/auth_service.dart';
import 'package:genauth/services/audit_log_service.dart';

class LockController extends ChangeNotifier {
  bool _authenticating = false;
  bool _hasError = false;

  bool get authenticating => _authenticating;
  bool get hasError => _hasError;

  void clearError() {
    if (!_hasError) return;
    _hasError = false;
    notifyListeners();
  }

  Future<bool> authenticate({bool reportFailure = true}) async {
    if (_authenticating) return false;

    await AuditLogService.instance.log('auth_biometric_attempt');

    _authenticating = true;
    _hasError = false;
    notifyListeners();

    final ok = await AuthService.authenticate();

    _authenticating = false;
    _hasError = reportFailure && !ok;
    notifyListeners();

    await AuditLogService.instance.log(
      'auth_biometric_result',
      status: ok ? 'success' : 'failed',
    );

    return ok;
  }
}
