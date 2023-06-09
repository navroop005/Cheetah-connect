import 'dart:io';

import 'package:cheetah_connect/control/details.dart';

class MySocketServer {
  late int port;
  late ServerSocket _server;

  MySocketServer();

  static Future<MySocketServer> start(void Function(Socket)? onClient) async {
    final instance = MySocketServer();
    instance._server = await ServerSocket.bind(InternetAddress.anyIPv6, 0);
    instance.port = instance._server.port;
    instance._server.listen(onClient);
    return instance;
  }

  void close() async {
    await Future.delayed(const Duration(seconds: 2));
    _server.close();
  }
}

class MySocketClient {
  late Socket socket;

  static Future<MySocketClient> connect(String ip, int port) async {
    MySocketClient instance = MySocketClient();
    String interface = await NetworkDetails.getInterface();
    instance.socket = await Socket.connect(
      InternetAddress('$ip%$interface', type: InternetAddressType.IPv6),
      port,
    );

    return instance;
  }
}
