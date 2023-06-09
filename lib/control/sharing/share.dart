import 'package:cheetah_connect/control/paired.dart';
import 'package:cheetah_connect/control/sharing/chat.dart';
import 'package:flutter/foundation.dart';

class ShareHandler {
  ShareHandler(this.device);
  SocketConnection? _connection;
  void setConnection(SocketConnection conn) {
    _connection = conn;
  }

  final PairedDevice device;
  late final ChatHandler chatHandler = ChatHandler(this);

  Future<bool> sendData(Map<String, String> data) async {
    try {
      await _connection!.send(data);
      return true;
    } catch (e) {
      debugPrint('Error: $e');
      return false;
    }
  }

  void handleData(Map<String, String> data) {
    // debugPrint('$data');
    try {
      String request = data['request']!;
      switch (request) {
        case 'chat-text':
          chatHandler.receiveText(data['text']!);
          break;
        case 'chat-file':
          chatHandler.receiveFile(
            data['fileName']!,
            int.parse(data['fileSize']!),
            data['IPv6']!,
            int.parse(data['port']!),
          );
          break;
        default:
          debugPrint('Invalid request: $request');
      }
    } catch (e) {
      debugPrint('Error: $e');
      debugPrint('data: $data');
    }
  }
}
