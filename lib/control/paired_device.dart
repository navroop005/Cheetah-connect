import 'package:cheetah_connect/types/paired_device.dart';
import 'package:flutter/foundation.dart';

final class PairedDeviceFg extends PairedDevice with ChangeNotifier {
  PairedDeviceFg(super.name, super.os, super.passKey);

  bool _isConnected = false;

  @override
  set isConnected(bool value) {
    _isConnected = value;
    notifyListeners();
  }

  @override
  bool get isConnected => _isConnected;

  PairedDeviceFg.fromPairedDevice(PairedDevice device)
      : super(device.name, device.os, device.passKey);
}
