import 'package:flutter/foundation.dart';
import 'package:genauth/services/auth_service.dart';

class LockController extends ChangeNotifier {
  bool _authenticating = false;
  bool _hasError = false;

  bool get authenticating => _authenticating;
  bool get hasError => _hasError;

  Future<bool> authenticate() async {
    if (_authenticating) return false;

    _authenticating = true;
    _hasError = false;
    notifyListeners();

    final ok = await AuthService.authenticate();

    _authenticating = false;
    _hasError = !ok;
    notifyListeners();

    return ok;
  }
}
