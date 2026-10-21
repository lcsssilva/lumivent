// Licenses of bundled third-party files that are not Dart packages (Flutter
// already collects those): the Inter font and the QuickJS engine inside the
// flutter_js native library. They show up in the about/licenses page.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bundled asset with the license text, per package name.
const bundledLicenses = {
  'Inter (fonte)': 'assets/fonts/inter/LICENSE.txt',
  'QuickJS': 'assets/licenses/quickjs.txt',
};

/// Adds [bundledLicenses] to the [LicenseRegistry]. Read lazily, only when the
/// licenses page is opened.
void registerBundledLicenses([AssetBundle? bundle]) {
  LicenseRegistry.addLicense(() async* {
    final assets = bundle ?? rootBundle;
    for (final MapEntry(key: package, value: path) in bundledLicenses.entries) {
      yield LicenseEntryWithLineBreaks([
        package,
      ], await assets.loadString(path));
    }
  });
}
