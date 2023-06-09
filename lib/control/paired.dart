import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cheetah_connect/control/connection_finder.dart';
import 'package:cheetah_connect/control/sharing/share.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PairedDevicesList with ChangeNotifier {
  final List<PairedDevice> _pairedDevices = [];
  List<PairedDevice> get devices {
    return List.unmodifiable(_pairedDevices);
  }

  void addPaired(PairedDevice device) async {
    _pairedDevices.add(device);
    save();
    notifyListeners();
  }

  void removePaired(PairedDevice device) async {
    _pairedDevices.remove(device);
    save();
    notifyListeners();
  }

  PairedDevice find(String name) {
    return _pairedDevices.firstWhere((element) => element.name == name);
  }

  bool isPaired(String name) {
    return _pairedDevices.indexWhere((element) => element.name == name) != -1;
  }

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getInstance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> load() async {
    _pairedDevices.clear();
    List<String>? list = (await _getInstance()).getStringList("paired_devices");
    if (list != null) {
      for (var e in list) {
        Map<String, String> data = Map<String, String>.from(jsonDecode(e));
        _pairedDevices.add(PairedDevice(
          data['name']!,
          data['os']!,
          data['passKey']!,
        ));
      }
    }
  }

  void save() async {
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

class PairedDevice with ChangeNotifier {
  static PairedDevicesList list = PairedDevicesList();

  String name;
  String os;
  String passKey;
  late ShareHandler shareHandler;
  SocketConnection? _socketConnection;

  set socket(Socket? sock) {
    if (sock == null) {
      _socketConnection = null;
      ConnectionFinder.startConnectBroadcast(this);
    } else {
      _socketConnection = SocketConnection(
        this,
        sock,
        shareHandler.handleData,
      );
      shareHandler.setConnection(_socketConnection!);
    }
    notifyListeners();
  }

  bool get isConnected => _socketConnection != null;

  PairedDevice(this.name, this.os, this.passKey) {
    shareHandler = ShareHandler(this);
    ConnectionFinder.startConnectBroadcast(this);
  }
}

class SocketConnection {
  final Socket _socket;
  final PairedDevice _device;
  final void Function(Map<String, String> data) onData;
  SocketConnection(this._device, this._socket, this.onData) {
    _socket.listen(
      handleData,
      onDone: closeConnection,
      onError: (error) => debugPrint('Error: $error'),
    );
  }

  void closeConnection() {
    _device.socket = null;
  }

  Future<void> send(Map<String, String> data) async {
    String dataStr = jsonEncode(data);
    _socket.write(dataStr);
    await _socket.flush();
  }

  List<int> buffer = [];

  void handleData(Uint8List data) {
    try {
      buffer.addAll(data);
      String dataStr = String.fromCharCodes(buffer);
      final request = Map<String, String>.from(jsonDecode(dataStr));
      buffer.clear();
      onData(request);
    } catch (_) {}
  }
}
