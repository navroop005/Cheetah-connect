import 'package:cheetah_connect/background/bg_process.dart';
import 'package:cheetah_connect/background/connection/connection_maker.dart';
import 'package:cheetah_connect/background/connection/paired/paired_device.dart';
import 'package:cheetah_connect/control/details.dart';
import 'package:cheetah_connect/types/paired_device.dart';
import 'package:cheetah_connect/types/paired_list.dart';
import 'package:flutter/foundation.dart';

final class PairedListBg extends PairedList {
  static PairedListBg? _instance;

  factory PairedListBg() {
    return _instance ??= PairedListBg._internal();
  }

  PairedListBg._internal();

  @override
  List<PairedDeviceBg> get devices {
    return super.devices as List<PairedDeviceBg>;
  }

  void updateForeground() {
    BackgroundProcess().updatePairedList();
    devices;
  }

  @override
  void addPaired(PairedDevice device) async {
    super.addPaired(device);
    updateForeground();
  }

  @override
  void removePaired(PairedDevice device) async {
    super.removePaired(device);
    updateForeground();
  }

  @override
  PairedDeviceBg find(String name) {
    return super.find(name) as PairedDeviceBg;
  }

  void handleConnect(Map<String, dynamic> details) async {
    String name = details['name']!;
    String ipv6 = details['IPv6']!;
    int port = details['port']!;

    if (name != (await DeviceDetail.getCurrent()).name) {
      debugPrint('HandleConnect name: $name IPv6 : $ipv6 port: $port');
      PairedDeviceBg device = PairedListBg().find(name);
      if (!device.isConnected) {
        await ConnectionMaker.handleConnect(device, ipv6, port);
      }
    }
  }
}
