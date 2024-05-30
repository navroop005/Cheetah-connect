import 'package:cheetah_connect/control/paired_device.dart';
import 'package:cheetah_connect/types/paired_list.dart';
import 'package:flutter/foundation.dart';

final class PairedListFg extends PairedList with ChangeNotifier {
  static final PairedListFg _instance = PairedListFg._internal();

  factory PairedListFg() {
    return _instance;
  }

  PairedListFg._internal();

  @override
  List<PairedDeviceFg> get devices => super.devices.cast();

  void update() async {
    await super.load();
    notifyListeners();
  }

  void updateConnected(String name, bool isConnected) {
    find(name).isConnected = isConnected;
  }
}
