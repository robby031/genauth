import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  AppInfoService._();

  static Future<String> versionLabel() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    final buildNumber = info.buildNumber.trim();

    if (buildNumber.isEmpty || buildNumber == '0') {
      return version;
    }

    return '$version+$buildNumber';
  }
}
