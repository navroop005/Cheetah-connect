import 'dart:convert';
import 'dart:io';

import 'package:cheetah_connect/background/bg_process.dart';
import 'package:cheetah_connect/background/connection/connection_broadcast.dart';
import 'package:cheetah_connect/types/paired_device.dart';
import 'package:flutter/foundation.dart';

final class PairedDeviceBg extends PairedDevice {
  // static PairedDevicesList list = PairedDevicesList();
  // late ShareHandler shareHandler;
  SocketConnection? _socketConnection;

  set socket(Socket? sock) {
    if (sock == null) {
      _socketConnection = null;
      startConnecting();
    } else {
      _socketConnection = SocketConnection(
        this,
        sock,
        // shareHandler.handleData,
        (_) {},
      );
      // shareHandler.setConnection(_socketConnection!);
    }
    // notifyListeners();
    BackgroundProcess().updateConnected(name, isConnected);
  }

  @override
  bool get isConnected => _socketConnection != null;

  PairedDeviceBg(super.name, super.os, super.passKey) {
    // shareHandler = ShareHandler(this);
    // debugPrint('PairedDeviceBg');
    startConnecting();
  }

  PairedDeviceBg.fromPairedDevice(PairedDevice device)
      : super(device.name, device.os, device.passKey) {
    // debugPrint('PairedDeviceBg.fromPairedDevice');
    startConnecting();
  }

  void startConnecting() {
    if (!isConnected) {
      ConnectionBroadcast.startConnectBroadcast(this);
    }
  }
}

class SocketConnection {
  final Socket _socket;
  final PairedDeviceBg _device;
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
