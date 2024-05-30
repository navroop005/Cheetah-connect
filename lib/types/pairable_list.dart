import 'package:cheetah_connect/control/details.dart';

class PairableList {
  List<DeviceDetail> devices = [];

  DeviceDetail? find(String name) {
    try {
      return devices.firstWhere((element) => element.name == name);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> toListOfMap() {
    return devices.map((e) => e.toMap()).toList();
  }

  void updateDevices(List<Map<String, dynamic>> newDevices) {
    devices = newDevices.map((e) => DeviceDetail.fromMap(e)).toList();
  }
}
