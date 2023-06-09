import 'dart:convert';
import 'dart:io';

import 'package:cheetah_connect/control/sharing/share.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatHandler with ChangeNotifier {
  final ShareHandler _shareHandler;
  ChatHandler(this._shareHandler);

  final List<MessageDetail> messages = [];
  void addMessage(MessageDetail message) {
    messages.insert(0, message);
    notifyListeners();
  }

  void receiveText(String text) {
    addMessage(MessageDetail(
      _shareHandler,
      text: text,
      time: DateTime.now(),
      byCurrent: false,
    ));
    debugPrint('Recieved message');
  }

  Future<void> sendText(String text) async {
    final message = MessageDetail(
      _shareHandler,
      text: text,
      byCurrent: true,
      time: DateTime.now(),
    );
    addMessage(message);
  }

  void sendFile() async {
    String? fileName;
    Uint8List? fileData;
    if (Platform.isAndroid) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);
        fileName = result.files.single.name;
        fileData = await file.readAsBytes();
      }
    } else {
      final XFile? file = await openFile();
      if (file != null) {
        fileName = file.name;
        fileData = await file.readAsBytes();
      }
    }
    if (fileName != null) {
      final message = MessageDetail(
        _shareHandler,
        text: fileName,
        time: DateTime.now(),
        byCurrent: true,
        fileName: fileName,
        fileData: fileData,
      );
      addMessage(message);
    }
  }

  void receiveFile(String fileName, String fileData) async {
    final message = MessageDetail(
      _shareHandler,
      text: fileName,
      time: DateTime.now(),
      byCurrent: false,
      fileName: fileName,
      fileData: base64Decode(fileData),
    );
    addMessage(message);
  }
}

class MessageDetail with ChangeNotifier {
  final ShareHandler _handler;
  String text;
  bool byCurrent;
  DateTime time;
  String? fileName;
  Uint8List? fileData;
  int? size;
  bool isTransfered = false;
  bool failed = false;
  double progress = 0;
  MessageDetail(
    this._handler, {
    required this.text,
    required this.time,
    required this.byCurrent,
    this.fileName,
    this.fileData,
    this.size,
  }) {
    if (byCurrent) {
      if (fileName == null) {
        _sendText();
      } else {
        _sendFile();
      }
    } else {
      if (fileName != null) {
        _receiveFile();
      }
    }
  }

  void _sendText() async {
    final data = {'request': 'chat-text', 'text': text};

    if (_handler.device.isConnected) {
      await _handler.sendData(data);
      isTransfered = true;
    } else {
      debugPrint('Not connected');
      failed = true;
    }
    notifyListeners();
  }

  void _sendFile() async {
    final data = {
      'request': 'chat-file',
      'fileName': fileName!,
      'fileData': base64.encode(fileData!),
    };

    if (_handler.device.isConnected) {
      await _handler.sendData(data);
      isTransfered = true;
    } else {
      debugPrint('Not connected');
      failed = true;
    }
    notifyListeners();
  }

  void _receiveFile() async {
    late Directory? dir;
    if (Platform.isAndroid) {
      final storagePermission =
          await Permission.manageExternalStorage.request().isGranted;
      debugPrint('$storagePermission');
    }
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0');
    } else {
      dir = await getDownloadsDirectory();
    }
    final downloadDir = Directory('${dir?.path}/RecievedFiles');
    downloadDir.createSync();
    File file = File('${downloadDir.path}/$fileName');
    await file.writeAsBytes(fileData!);
    debugPrint('Saved at: ${file.path}');
    isTransfered = true;
    notifyListeners();
  }
}

class FileShareConnection {}
