import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/services/auth_service.dart';
import 'package:genauth/services/storage_service.dart';

final lockProvider = AutoDisposeNotifierProvider<LockNotifier, LockState>(
  LockNotifier.new,
);

class LockState {
  const LockState({this.authenticating = false, this.hasError = false});

  final bool authenticating;
  final bool hasError;

  LockState copyWith({bool? authenticating, bool? hasError}) {
    return LockState(
      authenticating: authenticating ?? this.authenticating,
      hasError: hasError ?? this.hasError,
    );
  }
}

class LockNotifier extends AutoDisposeNotifier<LockState> {
  @override
  LockState build() {
    return const LockState();
  }

  void clearError() {
    if (!state.hasError) return;
    state = state.copyWith(hasError: false);
  }

  Future<bool> authenticate({bool reportFailure = true}) async {
    if (state.authenticating) return false;

    await AuditLogService.instance.log('auth_biometric_attempt');

    state = state.copyWith(authenticating: true, hasError: false);

    final ok = await AuthService.authenticate();

    state = state.copyWith(
      authenticating: false,
      hasError: reportFailure && !ok,
    );

    await AuditLogService.instance.log(
      'auth_biometric_result',
      status: ok ? 'success' : 'failed',
    );

    if (ok) {
      await StorageService.instance.activateRealVault();
    }

    return ok;
  }
}
