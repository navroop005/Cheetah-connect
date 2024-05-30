// TODO: Implement

// import 'dart:async';
// import 'dart:io';

// import 'package:cheetah_connect/control/details.dart';
// import 'package:cheetah_connect/background/connection/network/socket.dart';
// import 'package:cheetah_connect/control/sharing/share.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:file_selector/file_selector.dart';
// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// class ChatHandler with ChangeNotifier {
//   final ShareHandler _shareHandler;
//   ChatHandler(this._shareHandler);

//   final List<MessageDetail> messages = [];
//   void addMessage(MessageDetail message) {
//     messages.insert(0, message);
//     notifyListeners();
//   }

//   void receiveText(String text) {
//     final message = MessageDetail(
//       _shareHandler,
//       text: text,
//       time: DateTime.now(),
//       byCurrent: false,
//     );
//     message.isTransfered = true;
//     addMessage(message);
//     debugPrint('Recieved message');
//   }

//   Future<void> sendText(String text) async {
//     final message = MessageDetail(
//       _shareHandler,
//       text: text,
//       byCurrent: true,
//       time: DateTime.now(),
//     );
//     addMessage(message);
//   }

//   void sendFile() async {
//     String? fileName;
//     String? filePath;
//     Stream<List<int>>? fileStream;
//     int? fileSize;
//     if (Platform.isAndroid) {
//       FilePickerResult? result = await FilePicker.platform.pickFiles();
//       if (result != null) {
//         fileName = result.files.single.name;
//         File file = File(result.files.single.path!);
//         fileSize = await file.length();
//         fileStream = file.openRead();
//         filePath = file.path;
//       }
//     } else {
//       final XFile? file = await openFile();
//       if (file != null) {
//         fileName = file.name;
//         fileSize = await file.length();
//         fileStream = file.openRead();
//         filePath = file.path;
//       }
//     }
//     if (fileName != null) {
//       final message = MessageDetail(
//         _shareHandler,
//         text: fileName,
//         time: DateTime.now(),
//         byCurrent: true,
//         fileName: fileName,
//         fileSize: fileSize,
//         fileStream: fileStream,
//         filePath: filePath,
//       );
//       addMessage(message);
//     }
//   }

//   void receiveFile(
//       String fileName, int fileSize, String serverIP, int port) async {
//     final message = MessageDetail(
//       _shareHandler,
//       text: fileName,
//       time: DateTime.now(),
//       byCurrent: false,
//       fileName: fileName,
//       fileSize: fileSize,
//     );
//     addMessage(message);
//     message.receiveFile(serverIP, port);
//   }
// }

// class MessageDetail with ChangeNotifier {
//   final ShareHandler _handler;
//   String text;
//   bool byCurrent;
//   DateTime time;
//   String? fileName;
//   Stream<List<int>>? fileStream;
//   int? fileSize;
//   String? filePath;
//   bool isTransfered = false;
//   bool isFailed = false;
//   double? progress;
//   MessageDetail(
//     this._handler, {
//     required this.text,
//     required this.time,
//     required this.byCurrent,
//     this.fileName,
//     this.fileStream,
//     this.fileSize,
//     this.filePath,
//   }) {
//     if (byCurrent) {
//       if (fileName == null) {
//         _sendText();
//       } else {
//         _sendFile();
//       }
//     }
//   }

//   void _sendText() async {
//     final data = {'request': 'chat-text', 'text': text};

//     if (_handler.device.isConnected) {
//       await _handler.sendData(data);
//       isTransfered = true;
//     } else {
//       debugPrint('Not connected');
//       isFailed = true;
//     }
//     notifyListeners();
//   }

//   void _sendFile() async {
//     if (_handler.device.isConnected) {
//       String ipv6 = (await NetworkDetails.getDetails()).ipv6!;

//       // Create socket to send file
//       MySocketServer server = await MySocketServer.start(onRecieverConnect);

//       // Send server details to reciever
//       final data = {
//         'request': 'chat-file',
//         'fileName': fileName!,
//         'fileSize': '$fileSize',
//         'IPv6': ipv6,
//         'port': '${server.port}',
//       };
//       await _handler.sendData(data);
//     } else {
//       debugPrint('Not connected');
//       isFailed = true;
//     }
//     notifyListeners();
//   }

//   void onRecieverConnect(Socket client) async {
//     debugPrint('Connected reciever ${DateTime.now()}');
//     int sent = 0;
//     int currentBuffer = 0;

//     // Send file
//     final stream = fileStream!.asyncMap((event) async {
//       client.add(event);
//       sent += event.length;
//       currentBuffer += event.length;
//       progress = sent / fileSize!;

//       // Flush buffer every 1 MB
//       if (currentBuffer > 1000000) {
//         await client.flush();
//         currentBuffer = 0;
//       }
//     });

//     // Update UI every 250 ms
//     Timer timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
//       notifyListeners();
//     });

//     // Wait for stream to end
//     await stream.drain();
//     await client.flush();
//     client.destroy();

//     if (sent == fileSize) {
//       debugPrint(
//           'File Sent ${DateTime.now()}, Total time: ${DateTime.now().difference(time)}');
//       isTransfered = true;
//     } else {
//       debugPrint('File send error, $progress');
//       isFailed = true;
//     }

//     timer.cancel();
//     notifyListeners();
//   }

//   Future<File> _createFile() async {
//     late Directory? dir;
//     if (Platform.isAndroid) {
//       final storagePermission =
//           await Permission.manageExternalStorage.request().isGranted;
//       debugPrint('$storagePermission');
//     }
//     if (Platform.isAndroid) {
//       dir = Directory('/storage/emulated/0');
//     } else {
//       dir = await getDownloadsDirectory();
//     }
//     final downloadDir = Directory('${dir?.path}/RecievedFiles');
//     downloadDir.createSync();
//     final file = File('${downloadDir.path}/$fileName');
//     filePath = file.path;
//     debugPrint('File created: $filePath');
//     return file;
//   }

//   void receiveFile(String ip, int port) async {
//     // Connect to sender socket
//     MySocketClient client = await MySocketClient.connect(ip, port);

//     // Create and open file to write
//     File file = await _createFile();
//     final writer = file.openWrite();

//     // Recieve file
//     int recieved = 0;
//     final stream = client.socket.listen(
//       (data) {
//         writer.add(data);
//         recieved += data.length;
//         progress = recieved / fileSize!;
//       },
//     );

//     // Update UI every 250 ms
//     Timer timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
//       notifyListeners();
//     });

//     // Wait for stream to end
//     await stream.asFuture();

//     if (recieved == fileSize) {
//       Duration timeTaken = DateTime.now().difference(time);
//       debugPrint(
//           'File recieved, time: $timeTaken, Speed: ${fileSize! / timeTaken.inMilliseconds / 1000} MBps');
//       isTransfered = true;
//     } else {
//       debugPrint('File receive error, $progress');
//       isFailed = true;
//     }

//     // Close file
//     await writer.close();

//     // Close socket
//     client.socket.destroy();

//     timer.cancel();
//     notifyListeners();
//   }
// }
