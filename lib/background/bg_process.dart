import 'dart:async';

import 'package:cheetah_connect/background/connection/connection_broadcast.dart';
import 'package:cheetah_connect/background/connection/connection_maker.dart';
import 'package:cheetah_connect/background/connection/paired/pairable_list.dart';
import 'package:cheetah_connect/background/connection/paired/paired_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundProcess {
  static BackgroundProcess? _instance;

  factory BackgroundProcess() {
    return _instance ??= BackgroundProcess._internal();
  }

  BackgroundProcess._internal();

  bool isForeground = false;
  ServiceInstance? service;

  void start(ServiceInstance s) {
    debugPrint('Background process started');
    service = s;

    BgNotification.showNotification(service!);

    PairedListBg().load();
    ConnectionBroadcast.start();
  }

  void stop() {
    debugPrint('Background process stopped');

    ConnectionBroadcast.stop();
  }

  void handleData(Map<String, dynamic>? data) {
    if (data == null) {
      debugPrint('Background process received null data');
      return;
    }
    debugPrint('Background process data: $data');

    try {
      switch (data['type']) {
        case 'foreground-active':
          isForeground = data['status'];
          debugPrint('Background process connected: $isForeground');
          break;
        case 'start-pair-broadcast':
          PairableListBg().findDevices();
          break;
        case 'stop-pair-broadcast':
          PairableListBg().stopFindDevices();
          break;
        case 'pair-device':
          PairableListBg().pair(data['details']);
          break;
        case 'accept-pair':
          ConnectionMaker.completePair(data['name'], data['accepted']);
          break;
        default:
          debugPrint('BackgroundProcess handleData: Unknown data type: $data');
      }
    } catch (e) {
      debugPrint('Error BackgroundProcess handleData: $e');
    }
  }

  void sendData(Map<String, dynamic> data) {
    debugPrint('Background process sending data: $data');
    service?.invoke('bg-invoke', data);
  }

  Future<void> checkForeground() async {
    sendData({'type': 'check-foreground'});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void updatePairable(List<Map<String, dynamic>> devices) {
    sendData({'type': 'update-pairable', 'devices': devices});
  }

  void handlePair(Map<String, dynamic> details) {
    sendData({'type': 'handle-pair', 'details': details});
  }

  void updatePairedList() {
    sendData({'type': 'update-paired'});
  }

  void updateConnected(String name, bool isConnected) {
    sendData({
      'type': 'update-connected',
      'name': name,
      'isConnected': isConnected,
    });
  }
}

class BgNotification {
  // TODO: Notification content
  static void showNotification(ServiceInstance service) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // BackgroundProcess().checkForeground();
          flutterLocalNotificationsPlugin.show(
            888,
            'Cheetah Connect',
            '${(BackgroundProcess().isForeground) ? 'Connected' : 'not connected'} ${DateTime.now()}',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'my_foreground',
                'MY FOREGROUND SERVICE',
                icon: 'ic_bg_service_small',
                ongoing: true,
              ),
            ),
          );
          service.invoke(
            "update-time",
            {
              "current_date": DateTime.now().toIso8601String(),
            },
          );
        } else {
          debugPrint("Background: 2");
        }
      }
    });
  }
}
