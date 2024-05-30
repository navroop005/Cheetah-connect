import 'dart:convert';

import 'package:cheetah_connect/background/connection/paired/paired_device.dart';
import 'package:cheetah_connect/background/connection/paired/paired_list.dart';
import 'package:cheetah_connect/control/paired_device.dart';
import 'package:cheetah_connect/control/paired_list.dart';
import 'package:cheetah_connect/types/paired_device.dart';
import 'package:shared_preferences/shared_preferences.dart';

base class PairedList {
  final List<PairedDevice> _pairedDevices = [];
  List<PairedDevice> get devices {
    return List.unmodifiable(_pairedDevices);
  }

  PairedDevice find(String name) {
    return _pairedDevices.firstWhere((element) => element.name == name);
  }

  void addPaired(PairedDevice device) async {
    _pairedDevices.add(device);
    _save();
  }

  void removePaired(PairedDevice device) async {
    _pairedDevices.remove(device);
    _save();
  }

  bool isPaired(String name) {
    return _pairedDevices.indexWhere((element) => element.name == name) != -1;
  }

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getInstance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> load() async {
    _pairedDevices.clear();

    var instance = await _getInstance();
    await instance.reload();

    List<String>? list = instance.getStringList("paired_devices");
    if (list != null) {
      for (var e in list) {
        Map<String, String> data = Map<String, String>.from(jsonDecode(e));
        PairedDevice device = PairedDevice(
          data['name']!,
          data['os']!,
          data['passKey']!,
        );
        if (this is PairedListBg) {
          device = PairedDeviceBg.fromPairedDevice(device);
        } else if (this is PairedListFg) {
          device = PairedDeviceFg.fromPairedDevice(device);
        }
        _pairedDevices.add(device);
      }
    }
  }

  void _save() async {
    List<String> list = [];
    for (var e in devices) {
      list.add(jsonEncode({
        'name': e.name,
        'os': e.os,
        'passKey': e.passKey,
      }));
    }
    (await _getInstance()).setStringList('paired_devices', list);
  }
}
