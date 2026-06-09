import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/providers/google_account_provider.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

final googleProfileProvider =
    AsyncNotifierProvider<GoogleProfileNotifier, GoogleProfile?>(
      GoogleProfileNotifier.new,
    );

class GoogleProfileNotifier extends AsyncNotifier<GoogleProfile?> {
  @override
  Future<GoogleProfile?> build() async {
    ref.listen<GoogleSignInAccount?>(googleAccountUserProvider, (prev, next) {
      if (prev?.id != next?.id) {
        unawaited(reload());
      }
    });

    return _loadProfile();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadProfile);
  }

  Future<GoogleProfile?> _loadProfile() {
    return StorageService.instance.getGoogleProfile();
  }
}
