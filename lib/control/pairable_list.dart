import 'package:cheetah_connect/control/details.dart';
import 'package:cheetah_connect/control/handle_bg.dart';
import 'package:cheetah_connect/control/utils.dart';
import 'package:cheetah_connect/types/pairable_list.dart';
import 'package:cheetah_connect/view/add_request.dart';
import 'package:flutter/foundation.dart';

class PairableListFg extends PairableList with ChangeNotifier {
  static PairableListFg? _instance;

  factory PairableListFg() {
    return _instance ??= PairableListFg._internal();
  }

  PairableListFg._internal();

  @override
  void updateDevices(List<Map<String, dynamic>> newDevices) {
    super.updateDevices(newDevices);
    notifyListeners();
  }

  void findDevices() {
    HandleBgProcess.startPairBroadcast();
  }

  void stopFindDevices() {
    HandleBgProcess.stopPairBroadcast();
    devices.clear();
  }

  void pair(DeviceDetail device) {
    Map<String, dynamic> details = {
      'name': device.name,
      'IPv4': device.ipv4,
      'IPv6': device.ipv6,
      'os': device.os,
    };
    HandleBgProcess.pairDevice(details);
  }

  void handlePair(Map<String, dynamic> details) async {
    DeviceDetail device = DeviceDetail.fromMap(details);
    // devices.add(device);

    bool accepted = await Utils.showPopupDialog(
      AddRequest(details: device),
    );

    HandleBgProcess.acceptPair(device.name, accepted);

    // if (accepted) {
    //   devices.add(device);
    //   notifyListeners();
    // }
  }
}
