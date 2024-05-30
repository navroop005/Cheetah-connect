import 'package:cheetah_connect/background/bg_process.dart';
import 'package:cheetah_connect/background/connection/connection_broadcast.dart';
import 'package:cheetah_connect/background/connection/connection_maker.dart';
import 'package:cheetah_connect/background/connection/paired/paired_list.dart';
import 'package:cheetah_connect/control/details.dart';
import 'package:cheetah_connect/types/pairable_list.dart';

class PairableListBg extends PairableList {
  static PairableListBg? _instance;

  factory PairableListBg() {
    return _instance ??= PairableListBg._internal();
  }

  PairableListBg._internal();

  void updateForeground() {
    BackgroundProcess().updatePairable(toListOfMap());
  }

  void onNewDevice(Map<String, dynamic> details) async {
    String name = details['name'];
    if ((find(name) == null) &&
        (!PairedListBg().isPaired(name)) &&
        (name != (await DeviceDetail.getCurrent()).name)) {
      devices.add(DeviceDetail.fromMap(details));
      updateForeground();
    }
  }

  void findDevices() {
    ConnectionBroadcast.startPairBroadcast();
  }

  void stopFindDevices() {
    ConnectionBroadcast.stopPairBroadcast();
    devices.clear();
  }

  void pair(Map<String, dynamic> data) {
    ConnectionMaker.initiatePair(DeviceDetail.fromMap(data));
  }
}
