import 'dart:io';

extension IsAddressHostNumeric on InternetAddress {
  bool get isHostNumeric {
    return address == host;
  }
}
