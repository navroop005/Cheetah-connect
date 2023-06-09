import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class NetworkDetails {
  String? name, ipv4, ipv6, broadcastIP;
  String interface;
  NetworkDetails(
      this.name, this.ipv4, this.ipv6, this.broadcastIP, this.interface);

  static Future<NetworkDetails> getDetails() async {
    if (Platform.isAndroid) {
      await Permission.locationWhenInUse.request();
    }
    final info = NetworkInfo();

    String interface = '';
    final interfaces = await NetworkInterface.list();
    for (var i in interfaces) {
      if (i.name.startsWith('wl')) {
        interface = i.name;
        break;
      }
    }
    return NetworkDetails(
      await info.getWifiName() ?? '(Allow location permission)',
      await info.getWifiIP(),
      await info.getWifiIPv6(),
      await info.getWifiBroadcast(),
      interface,
    );
  }

  @override
  String toString() {
    return '''Current network:
    Name: $name
    IPv4: $ipv4
    IPv6: $ipv6
    Broadcast: $broadcastIP''';
  }
}

class DeviceDetail {
  String name, os;
  String? ipv4, ipv6;
  DeviceDetail(this.name, this.ipv4, this.ipv6, this.os);

  static Future<DeviceDetail> getCurrent() async {
    String name = 'Unknown';
    String os = Platform.operatingSystem;
    var networkDetails = await NetworkDetails.getDetails();

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      name = androidInfo.model;
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      name = linuxInfo.prettyName;
    } else if (Platform.isWindows) {
      WindowsDeviceInfo winInfo = await deviceInfo.windowsInfo;
      name = winInfo.userName;
    }

    debugPrint(name);
    return DeviceDetail(name, networkDetails.ipv4, networkDetails.ipv6, os);
  }

  Map<String, dynamic> get broadcastData => {
        'name': name,
        'os': os,
        'IPv4': ipv4,
      };

  @override
  String toString() {
    return {
      'name': name,
      'os': os,
      'IPv4': ipv4,
      'IPv6': ipv6,
    }.toString();
  }
}
