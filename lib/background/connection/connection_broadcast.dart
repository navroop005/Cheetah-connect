import 'dart:async';
import 'dart:convert';

import 'package:cheetah_connect/background/connection/connection_maker.dart';
import 'package:cheetah_connect/background/connection/network/pair_server.dart';
import 'package:cheetah_connect/background/connection/network/socket.dart';
import 'package:cheetah_connect/background/connection/network/udp.dart';
import 'package:cheetah_connect/background/connection/paired/pairable_list.dart';
import 'package:cheetah_connect/background/connection/paired/paired_device.dart';
import 'package:cheetah_connect/background/connection/paired/paired_list.dart';
import 'package:cheetah_connect/control/details.dart';
import 'package:flutter/foundation.dart';

class ConnectionBroadcast {
  static bool _isConnecting = false;
  static bool _isPairing = false;
  static UdpBroadcast? _broadcast;

  static Future<bool> start() async {
    PairServer.start();
    try {
      String? broadcastIP = (await NetworkDetails.getDetails()).broadcastIP;
      debugPrint("Broadcast IP: $broadcastIP");
      _broadcast = UdpBroadcast(8003, broadcastIP);
      await _broadcast!.startListen(_onRecieve);
      return true;
    } catch (e) {
      debugPrint('Error ConnectionFinder start: $e');
      return false;
    }
  }

  static void startPairBroadcast() async {
    _isPairing = true;
    final map = (await DeviceDetail.getCurrent()).broadcastData;
    map['type'] = 'pair';
    String data = jsonEncode(map);
    debugPrint('Started Pair broadcast: $data');

    if (_broadcast == null) {
      debugPrint('Error startPairBroadcast: _broadcast == null');
    } else {
      _broadcast!.startPeriodicBroadcast(
        'pair',
        data,
        const Duration(seconds: 1),
      );
    }
  }

  static void stopPairBroadcast() {
    // availableDevices.clear();
    _isPairing = false;
    _broadcast?.stopPeriodicBroadcast('pair');
    debugPrint('Stopped PairBroadcast');
  }

  static void startConnectBroadcast(PairedDeviceBg device) async {
    if (!_isConnecting) {
      _isConnecting = true;
      MySocketServer server = await ConnectionMaker.startConnecting(device);

      String data = jsonEncode({
        'type': 'connect',
        'name': (await DeviceDetail.getCurrent()).name,
        'IPv6': (await NetworkDetails.getDetails()).ipv6,
        'port': server.port,
      });
      debugPrint('Started Connect broadcast: $data');

      _broadcast!
          .startPeriodicBroadcast('connect', data, const Duration(seconds: 5));
    }
  }

  static void stopConnectBroadcast() {
    _isConnecting = false;
    _broadcast?.stopPeriodicBroadcast('connect');

    debugPrint('Stopped ConnectBroadcast');
  }

  static void _onRecieve(String data) async {
    // debugPrint('Recieved broadcast: $data');
    try {
      Map<String, dynamic> details =
          Map<String, dynamic>.from(jsonDecode(data));
      String type = details['type']!;
      if (_isPairing && type == 'pair') {
        PairableListBg().onNewDevice(details);
      } else if (type == 'connect') {
        PairedListBg().handleConnect(details);
      }
    } catch (e) {
      debugPrint('Error ConnectionBroadcast _onRecieve: $e');
    }
  }

  static Future<void> stop() async {
    PairServer.stop();
    stopPairBroadcast();
    _broadcast?.stopAll();
    _broadcast?.stopListen();
  }
}
