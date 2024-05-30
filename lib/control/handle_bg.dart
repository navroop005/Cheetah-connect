import 'package:cheetah_connect/control/pairable_list.dart';
import 'package:cheetah_connect/control/paired_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class HandleBgProcess {
  static void start() async {
    FlutterBackgroundService().on('bg-invoke').listen(onReceiveData);
    // sendData({'connected': true});
    bool running = await FlutterBackgroundService().isRunning();
    debugPrint('Background running: $running');
    sendData({'type': 'foreground-active', 'status': true});
  }

  static void onReceiveData(Map<String, dynamic>? data) {
    if (data == null) {
      return;
    }
    debugPrint('Received data: $data');

    try {
      switch (data['type']) {
        case 'check-foreground':
          sendData({'type': 'foreground-active', 'status': true});
          break;
        case 'update-pairable':
          PairableListFg()
              .updateDevices(data['devices'].cast<Map<String, dynamic>>());
          break;
        case 'handle-pair':
          PairableListFg().handlePair(data['details']);
          break;
        case 'update-paired':
          PairedListFg().update();
          break;
        case 'update-connected':
          PairedListFg().updateConnected(data['name'], data['isConnected']);
          break;
        default:
          debugPrint('HandleBgProcess onReceiveData: Unknown data type: $data');
      }
    } catch (e) {
      debugPrint('Error HandleBgProcess onReceiveData: $e');
    }
  }

  static void sendData(Map<String, dynamic> data) {
    FlutterBackgroundService().invoke('fg-invoke', data);
  }

  static void stop() {
    debugPrint('pause');

    // sendData({'connected': false});
    sendData({'type': 'foreground-active', 'status': false});
  }

  static void startPairBroadcast() {
    sendData({'type': 'start-pair-broadcast'});
  }

  static void stopPairBroadcast() {
    sendData({'type': 'stop-pair-broadcast'});
  }

  static void pairDevice(Map<String, dynamic> details) {
    sendData({'type': 'pair-device', 'details': details});
  }

  static void acceptPair(String name, bool accepted) {
    sendData({'type': 'accept-pair', 'name': name, 'accepted': accepted});
  }
}
