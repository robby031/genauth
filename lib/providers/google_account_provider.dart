import 'package:genauth/services/google_account_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final googleAccountProvider = Provider<GoogleAccountService>((ref) {
  return GoogleAccountService.instance;
});
