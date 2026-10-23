import 'dart:io';

/// Whether [errno] means the user lacks permission (EACCES or EPERM).
bool isPermissionDeniedErrno(int? errno) => errno == 13 || errno == 1;

/// The /dev node exists, but the user cannot open it for reading and
/// writing? (missing udev rule/`uaccess`). Opens and closes without sending anything.
bool isPermissionDenied(String devPath) {
  try {
    File(devPath).openSync(mode: FileMode.append).closeSync();
    return false;
  } on FileSystemException catch (e) {
    return isPermissionDeniedErrno(e.osError?.errorCode);
  }
}
