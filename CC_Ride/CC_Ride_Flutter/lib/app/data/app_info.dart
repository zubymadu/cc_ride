import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Fetched once at app startup (see main.dart) so any screen can display the
/// real installed version/build — the account screen used to show a
/// hardcoded "v1.0.0" string that never matched the actual build number,
/// which is exactly why a build could go out to a device with no visible
/// way to tell which one was actually installed.
class AppInfo {
  static final RxString versionLabel = ''.obs;

  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      versionLabel.value = 'CC_Ride v${info.version}+${info.buildNumber}';
    } catch (_) {
      // Leave blank rather than showing a stale/fake version.
    }
  }
}
