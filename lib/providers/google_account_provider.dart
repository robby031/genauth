import 'package:genauth/services/google_account_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final googleAccountProvider = Provider<GoogleAccountService>((ref) {
  return GoogleAccountService.instance;
});

final googleAccountUserProvider =
    NotifierProvider<GoogleAccountUserNotifier, GoogleSignInAccount?>(
      GoogleAccountUserNotifier.new,
    );

class GoogleAccountUserNotifier extends Notifier<GoogleSignInAccount?> {
  @override
  GoogleSignInAccount? build() {
    final service = ref.read(googleAccountProvider);

    void syncFromService() {
      state = service.currentUser;
    }

    service.userNotifier.addListener(syncFromService);
    ref.onDispose(() {
      service.userNotifier.removeListener(syncFromService);
    });

    return service.currentUser;
  }
}
