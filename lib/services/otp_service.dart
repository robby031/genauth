import 'package:genotp_flutter/genotp_flutter.dart';
import 'package:genauth/models/otp_account.dart';

class OtpService {
  static Future<String> generateCode(OtpAccount account) async {
    if (account.isHotp) {
      return GenotpFlutter.generateHotp(
        secretB32: account.secretB32,
        counter: account.counter,
        algorithm: account.algorithmInt,
        digits: account.digits,
      );
    }
    return GenotpFlutter.generateTotp(
      secretB32: account.secretB32,
      algorithm: account.algorithmInt,
      digits: account.digits,
      period: account.period,
    );
  }

  static Future<String> generateSecret() => GenotpFlutter.generateSecret();

  static int periodCounter(int period) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now ~/ period;
  }

  static int remainingSeconds(int period) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return period - (now % period);
  }

  static double progress(int period) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return 1.0 - ((now % period) / period);
  }
}
