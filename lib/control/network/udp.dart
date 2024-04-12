import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class UdpBroadcast {
  int port;
  String? broadcastAddress;
  UdpBroadcast(this.port, this.broadcastAddress);

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _subscription;

  Future<void> startListen(void Function(String) onReceive) async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8003);
    _socket!.broadcastEnabled = true;
    _subscription = _socket!.listen(null);
    _subscription!.onData(
      (event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = _socket!.receive();
          if (dg != null) {
            String data = utf8.decode(dg.data);
            // debugPrint('Recieved from ${dg.address.address}: $data');
            onReceive(data);
          }
        }
      },
    );
    debugPrint("Started");
  }

  void sendData(String data) async {
    if (_socket != null && broadcastAddress != null) {
      _socket!
          .send(utf8.encode(data), InternetAddress(broadcastAddress!), 8003);
    } else {
      debugPrint(
          "Cannot send data: socket: ${_socket != null}, broadcastAddress: $broadcastAddress");
    }
  }

  void stopListen() async {
    if (_socket != null) {
      _subscription?.cancel();
      _socket?.close();
      debugPrint("Stopped");
    }
  }
}
