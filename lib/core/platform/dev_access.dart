import 'dart:io';

const _eacces = 13, _eperm = 1;

/// The /dev node exists, but the user cannot open it for reading and
/// writing? (missing udev rule/`uaccess`). Opens and closes without sending anything.
bool isPermissionDenied(String devPath) {
  try {
    File(devPath).openSync(mode: FileMode.append).closeSync();
    return false;
  } on FileSystemException catch (e) {
    final code = e.osError?.errorCode;
    return code == _eacces || code == _eperm;
  }
}
