import 'dart:async';

import 'package:cheetah_connect/background/bg_process.dart';
import 'package:cheetah_connect/background/connection/connection_broadcast.dart';
import 'package:cheetah_connect/background/connection/network/pair_server.dart';
import 'package:cheetah_connect/background/connection/network/socket.dart';
import 'package:cheetah_connect/background/connection/paired/paired_device.dart';
import 'package:cheetah_connect/background/connection/paired/paired_list.dart';
import 'package:cheetah_connect/control/details.dart';
import 'package:cheetah_connect/control/utils.dart';
import 'package:flutter/foundation.dart';

class ConnectionMaker {
  static final Map<String, Completer<bool>> _pairCompleters = {};

  static Future<bool> initiatePair(DeviceDetail detailOther) async {
    String passKey = Utils.getRandomString(30);

    bool accepted = await PairRequest.pair(
      detailOther.ipv4!,
      await DeviceDetail.getCurrent(),
      passKey,
    );

    if (accepted) {
      var pair = PairedDeviceBg(
        detailOther.name,
        detailOther.os,
        passKey,
      );
      PairedListBg().addPaired(pair);
    }
    return accepted;
  }

  static void completePair(String name, bool accepted) {
    if (_pairCompleters.containsKey(name)) {
      _pairCompleters[name]!.complete(accepted);
      _pairCompleters.remove(name);
    }
  }

  static Future<bool> handlePair(
      DeviceDetail detailOther, String passKey) async {
    bool accepted = false;

    await BackgroundProcess().checkForeground();

    if (BackgroundProcess().isForeground) {
      // accepted = await Utils.showPopupDialog(
      //   AddRequest(details: detailOther),
      // );

      _pairCompleters[detailOther.name] = Completer();

      // TODO: add timeout

      BackgroundProcess().handlePair(detailOther.toMap());

      accepted = await _pairCompleters[detailOther.name]!.future;
    } else {
      // reject if not in foreground
      accepted = false;
      // stop broadcasting that may be left running
      ConnectionBroadcast.stopPairBroadcast();
      debugPrint(
          'Error ConnectionMaker handlePair: pair request received in background');
    }

    debugPrint('Accepted: $detailOther');
    if (accepted) {
      var pair = PairedDeviceBg(
        detailOther.name,
        detailOther.os,
        passKey,
      );
      PairedListBg().addPaired(pair);
      return true;
    } else {
      return false;
    }
  }

  static Future<MySocketServer> startConnecting(PairedDeviceBg device) async {
    MySocketServer server = await MySocketServer.start((client) {
      device.socket = client;
      ConnectionBroadcast.stopConnectBroadcast();
      debugPrint('Connected as server');
    });
    return server;
  }

  static Future<void> handleConnect(
      PairedDeviceBg device, String ip, int port) async {
    try {
      MySocketClient client = await MySocketClient.connect(ip, port);
      device.socket = client.socket;
      ConnectionBroadcast.stopConnectBroadcast();
      debugPrint('Connected as client');
    } catch (e) {
      debugPrint('Error connecting: $e');
    }
  }
}
