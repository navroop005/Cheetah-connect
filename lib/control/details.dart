import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class NetworkDetails {
  String? name, ipv4, ipv6, broadcastIP, interface;

  NetworkDetails(
      this.name, this.ipv4, this.ipv6, this.broadcastIP, this.interface);

  static Future<NetworkDetails> getDetails() async {
    // interfaces?.printInterfaceDetails();

    if (Platform.isAndroid) {
      await Permission.locationWhenInUse.request();
    }
    final info = NetworkInfo();
    final interfaces = await NetworkInterfaceDetails.getInterfaces();

    String? ipv4 = await info.getWifiIP();
    String? ipv6 = await info.getWifiIPv6();
    String? broadcastIP = await info.getWifiBroadcast();
    String? interface;

    try {
      if (interfaces != null) {
        ipv4 = interfaces.prefferedIPv4.first;
        ipv6 = interfaces.linkLocalIPv6.first;
        interface = interfaces.linkLocalInterfaces.first.name;
      }
    } catch (e) {
      debugPrint('Error getting network interfaces: $e');
    }

    broadcastIP ??= '${ipv4?.split('.').take(3).join('.')}.255';

    return NetworkDetails(
      await info.getWifiName() ?? '(Allow location permission)',
      ipv4,
      ipv6,
      broadcastIP,
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

class NetworkInterfaceDetails {
  final List<NetworkInterface> interfaces;
  List<NetworkInterface> linkLocalInterfaces = [];
  List<String> linkLocalIPv6 = [];
  List<String> globalIPv6 = [];
  List<String> prefferedIPv4 = [];

  NetworkInterfaceDetails(this.interfaces) {
    linkLocalInterfaces = interfaces
        .where((element) => element.addresses.any((addr) => addr.isLinkLocal))
        .toList();

    for (var i in linkLocalInterfaces) {
      for (var addr in i.addresses) {
        if (addr.type == InternetAddressType.IPv6) {
          String address = addr.address.split('%').first;
          if (addr.isLinkLocal) {
            linkLocalIPv6.add(address);
          } else {
            globalIPv6.add(address);
          }
        } else if (addr.type == InternetAddressType.IPv4) {
          prefferedIPv4.add(addr.address);
        }
      }
    }

    for (var i in prefferedIPv4) {
      debugPrint('Preffered IPv4: $i');
    }
    for (var i in linkLocalIPv6) {
      debugPrint('Link-local IPv6: $i');
    }
    for (var i in globalIPv6) {
      debugPrint('Global IPv6: $i');
    }
    for (var i in linkLocalInterfaces) {
      debugPrint('Link-local interface: ${i.name}');
    }
  }

  static Future<NetworkInterfaceDetails?> getInterfaces() async {
    debugPrint('Getting network interfaces');
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: true,
        type: InternetAddressType.any,
      );
      return NetworkInterfaceDetails(interfaces);
    } catch (e) {
      debugPrint('Error getting network interfaces: $e');
      return null;
    }
  }

  void printInterfaceDetails() {
    for (var interface in interfaces) {
      debugPrint('Interface: ${interface.name}');
      for (var address in interface.addresses) {
        debugPrint('  Address: ${address.address}');
        debugPrint('  Link-local: ${address.isLinkLocal}');
        debugPrint('  Loopback: ${address.isLoopback}');
        debugPrint('  Multicast: ${address.isMulticast}');
        debugPrint('  is IPv6: ${address.type == InternetAddressType.IPv6}');
        debugPrint('');
      }
      debugPrint('');
    }
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
