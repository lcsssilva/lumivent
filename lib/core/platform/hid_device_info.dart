class HidDeviceInfo {
  HidDeviceInfo({
    required this.path,
    required this.vendorId,
    required this.productId,
    required this.usagePage,
    required this.usage,
    required this.interfaceNumber,
    this.product,
    this.manufacturer,
    this.serial,
  });

  final String path;
  final int vendorId, productId, usagePage, usage, interfaceNumber;
  final String? product, manufacturer, serial;

  @override
  String toString() =>
      '$path ${_hex16(vendorId)}:${_hex16(productId)} if=$interfaceNumber '
      'usage=${_hex16(usagePage)}/${_hex16(usage)} "$product"';
}

String _hex16(int v) => v.toRadixString(16).padLeft(4, '0');
