import 'package:cheetah_connect/control/connection_finder.dart';
import 'package:cheetah_connect/control/details.dart';
import 'package:cheetah_connect/control/network/pair.dart';
import 'package:cheetah_connect/control/network/socket.dart';
import 'package:cheetah_connect/control/paired.dart';
import 'package:cheetah_connect/control/utils.dart';
import 'package:cheetah_connect/view/add_request.dart';
import 'package:flutter/foundation.dart';

class Connection {
  static Future<bool> initiatePair(DeviceDetail detailOther) async {
    String passKey = Utils.getRandomString(30);

    bool accepted = await PairRequest.pair(
      detailOther.ipv4!,
      await DeviceDetail.getCurrent(),
      passKey,
    );

    if (accepted) {
      var pair = PairedDevice(
        detailOther.name,
        detailOther.os,
        passKey,
      );
      PairedDevice.list.addPaired(pair);
    }
    return accepted;
  }

  static Future<bool> handlePair(
      DeviceDetail detailOther, String passKey) async {
    bool accepted = await Utils.showPopupDialog(
      AddRequest(details: detailOther),
    );
    debugPrint('Accepted: $detailOther');
    if (accepted) {
      var pair = PairedDevice(
        detailOther.name,
        detailOther.os,
        passKey,
      );
      PairedDevice.list.addPaired(pair);
      return true;
    } else {
      return false;
    }
  }

  static Future<MySocketServer> startConnecting(PairedDevice device) async {
    MySocketServer server = await MySocketServer.start((client) {
      device.socket = client;
      ConnectionFinder.stopConnectBroadcast();
      debugPrint('Connected as server');
    });
    return server;
  }

  static Future<void> handleConnect(
      PairedDevice device, String ip, int port) async {
    try {
      MySocketClient client = await MySocketClient.connect(ip, port);
      device.socket = client.socket;
      ConnectionFinder.stopConnectBroadcast();
      debugPrint('Connected as client');
    } catch (e) {
      debugPrint('Error connecting: $e');
    }
  }
}
