import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class NetworkDetails {
  String? name, ipv4, ipv6, broadcastIP, interface;
  NetworkInterfaceDetails? allInterfaces;

  NetworkDetails(this.name, this.ipv4, this.ipv6, this.broadcastIP,
      this.interface, this.allInterfaces);

  static Future<NetworkDetails> getDetails() async {
    // interfaces?.printInterfaceDetails();

    if (Platform.isAndroid) {
      await Permission.locationWhenInUse.request();
    }
    final info = NetworkInfo();
    final allInterfaces = await NetworkInterfaceDetails.getInterfaces();
    final preferredInterface = allInterfaces?.prefferedInterfaces.first;

    String? ipv4;
    String? ipv6;
    String? broadcastIP;
    String? interface;

    try {
      if (allInterfaces != null) {
        ipv4 = preferredInterface?.ipv4.first;
        ipv6 = preferredInterface?.linkLocalIPv6.first;
        if (Platform.isWindows) {
          interface = preferredInterface?.id.toString();
        } else {
          interface = preferredInterface?.name;
        }
      }
      ipv4 ??= await info.getWifiIP();
      ipv6 ??= await info.getWifiIPv6();
      broadcastIP ??= await info.getWifiBroadcast();
    } catch (e) {
      debugPrint('Error getting network interfaces: $e');
    }

    return NetworkDetails(
      await info.getWifiName() ?? '(Allow location permission)',
      ipv4,
      ipv6,
      broadcastIP,
      interface,
      allInterfaces,
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

class Interface {
  String name;
  int id;
  List<String> ipv4;
  List<String> linkLocalIPv6;
  List<String> globalIPv6;

  Interface(this.name, this.id, this.ipv4, this.linkLocalIPv6, this.globalIPv6);
}

class NetworkInterfaceDetails {
  final List<NetworkInterface> allInterfaces;
  List<Interface> prefferedInterfaces = [];

  NetworkInterfaceDetails(this.allInterfaces) {
    List<NetworkInterface> linkLocalInterfaces = allInterfaces
        .where((element) => element.addresses.any((addr) => addr.isLinkLocal))
        .toList();

    if (Platform.isWindows) {
      linkLocalInterfaces = linkLocalInterfaces
          .where((element) => element.name.contains('Wi-Fi'))
          .toList();
    }

    for (var i in linkLocalInterfaces) {
      prefferedInterfaces.add(Interface(
        i.name,
        i.index,
        i.addresses
            .where((addr) => addr.type == InternetAddressType.IPv4)
            .map((addr) => addr.address)
            .toList(),
        i.addresses
            .where((addr) => addr.type == InternetAddressType.IPv6)
            .where((addr) => addr.isLinkLocal)
            .map((addr) => addr.address.split('%').first)
            .toList(),
        i.addresses
            .where((addr) => addr.type == InternetAddressType.IPv6)
            .where((addr) => !addr.isLinkLocal)
            .map((addr) => addr.address.split('%').first)
            .toList(),
      ));
    }

    for (var i in prefferedInterfaces) {
      debugPrint('Preffered interface: ${i.name}');
      debugPrint('  ID: ${i.id}');

      for (var j in i.ipv4) {
        debugPrint('  IPv4: $j');
      }
      for (var j in i.linkLocalIPv6) {
        debugPrint('  Link-local IPv6: $j');
      }
      for (var j in i.globalIPv6) {
        debugPrint('  Global IPv6: $j');
      }
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
    for (var interface in allInterfaces) {
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
      name = winInfo.computerName;
    }

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
