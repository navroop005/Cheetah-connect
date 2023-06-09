import 'dart:async';
import 'dart:convert';

import 'package:cheetah_connect/control/connection.dart';
import 'package:cheetah_connect/control/details.dart';
import 'package:cheetah_connect/control/network/pair.dart';
import 'package:cheetah_connect/control/network/socket.dart';
import 'package:cheetah_connect/control/network/udp.dart';
import 'package:cheetah_connect/control/paired.dart';
import 'package:flutter/foundation.dart';

class ConnectionFinder {
  static final Future<DeviceDetail> _deviceDetails = DeviceDetail.getCurrent();
  static Timer? _pairBroadcast;
  static Timer? _connectBroadcast;
  static bool _isConnecting = false;
  static bool _isPairing = false;
  static UdpBroadcast? _broadcast;
  static List<DeviceDetail> availableDevices = [];
  static void Function()? updateAvailable;

  static Future<bool> start() async {
    PairServer.start();
    try {
      _broadcast = UdpBroadcast(8003, (await NetworkDetails.getDetails()).broadcastIP!);
      await _broadcast!.startListen(_onRecieve);
      return true;
    } catch (e) {
      debugPrint('$e');
      return false;
    }
  }

  static void startPairBroadcast() async {
    _isPairing = true;
    final map = (await _deviceDetails).broadcastData;
    map['type'] = 'pair';
    String data = jsonEncode(map);
    _pairBroadcast = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _broadcast?.sendData(data);
      },
    );
  }

  static void stopPairBroadcast() {
    availableDevices.clear();
    _isPairing = false;
    _pairBroadcast?.cancel();
  }

  static void startConnectBroadcast(PairedDevice device) async {
    if (!_isConnecting) {
      _isConnecting = true;
      MySocketServer server = await Connection.startConnecting(device);

      String data = jsonEncode({
        'type': 'connect',
        'name': (await _deviceDetails).name,
        'IPv6': (await NetworkDetails.getDetails()).ipv6,
        'port': server.port,
      });
      debugPrint('Started Connect broadcast: $data');
      _connectBroadcast = Timer.periodic(
        const Duration(seconds: 5),
        (timer) {
          _broadcast?.sendData(data);
        },
      );
    }
  }

  static void stopConnectBroadcast() {
    _isConnecting = false;
    debugPrint('Stopped ConnectBroadcast');
    _connectBroadcast?.cancel();
  }

  static void _onRecieve(String data) async {
    try {
      Map<String, dynamic> details =
          Map<String, dynamic>.from(jsonDecode(data));
      String type = details['type']!;
      if (_isPairing && type == 'pair') {
        String name = details['name']!;
        if (name != (await _deviceDetails).name) {
          if ((availableDevices.indexWhere((e) => e.name == name) == -1) &&
              !PairedDevice.list.isPaired(name)) {
            var newDevice = DeviceDetail(details['name']!, details['IPv4'],
                details['IPv6'], details['os']!);
            availableDevices.add(newDevice);
            debugPrint('Available: $newDevice');
            updateAvailable!();
          }
        }
      } else if (type == 'connect') {
        String name = details['name']!;
        String ipv6 = details['IPv6']!;
        int port = details['port']!;
        final networkDetails = await NetworkDetails.getDetails();
        if (ipv6 != networkDetails.ipv6) {
          debugPrint(
              'name: $name IPv6 : $ipv6 port: $port interface: ${networkDetails.interface}');
          PairedDevice device = PairedDevice.list.find(name);
          if (!device.isConnected) {
            await Connection.handleConnect(
                device, '$ipv6%${networkDetails.interface}', port);
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  static Future<void> stop() async {
    PairServer.stop();
    stopPairBroadcast();
    _broadcast?.stopListen();
  }
}
