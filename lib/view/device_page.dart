import 'package:cheetah_connect/control/paired.dart';
import 'package:cheetah_connect/control/sharing/chat.dart';
import 'package:flutter/material.dart';

class DevicePage extends StatelessWidget {
  final PairedDevice device;
  const DevicePage({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: [
          IconButton(
            onPressed: () {
              PairedDevice.list.removePaired(device);
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: ChatView(
        handler: device.shareHandler.chatHandler,
      ),
    );
  }
}

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.handler});
  final ChatHandler handler;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        ChatMessages(handler: widget.handler),
        InputMessage(handler: widget.handler),
      ],
    );
  }
}

class InputMessage extends StatefulWidget {
  const InputMessage({super.key, required this.handler});
  final ChatHandler handler;

  @override
  State<InputMessage> createState() => _InputMessageState();
}

class _InputMessageState extends State<InputMessage> {
  late final _typedMessage = TextEditingController()
    ..addListener(() {
      setState(() {});
    });
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    _typedMessage.dispose();
    super.dispose();
  }

  void sendText() async {
    final message = _typedMessage.text.trim();
    if (message.isNotEmpty) {
      widget.handler.sendText(message);
      setState(() {
        _typedMessage.text = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.loose(
        const Size(double.infinity, 200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 5, 5),
        child: Row(
          children: [
            Flexible(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _typedMessage,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Type message',
                    ),
                    onSubmitted: (value) {
                      sendText();
                      _focusNode.requestFocus();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            ElevatedButton(
              onPressed: widget.handler.sendFile,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                elevation: 2,
                shape: const CircleBorder(),
                fixedSize: const Size(50, 50),
              ),
              child: const Icon(Icons.attach_file),
            ),
            if (_typedMessage.text.isNotEmpty)
              ElevatedButton(
                onPressed: sendText,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  elevation: 2,
                  shape: const CircleBorder(),
                  fixedSize: const Size(50, 50),
                ),
                child: const Icon(Icons.send),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key, required this.handler});
  final ChatHandler handler;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: handler,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              reverse: true,
              children: handler.messages
                  .map<Widget>((e) => MessageContainer(data: e))
                  .toList()
                ..insert(0, const SizedBox(height: 70)),
            ),
          );
        });
  }
}

class MessageContainer extends StatelessWidget {
  const MessageContainer({super.key, required this.data});
  final MessageDetail data;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
        animation: data,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Align(
              alignment:
                  data.byCurrent ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints.loose(
                  Size(width * 0.80, double.infinity),
                ),
                child: Material(
                  elevation: 2,
                  color: data.byCurrent
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data.fileName != null)
                          const Icon(
                            Icons.file_present_rounded,
                            size: 30,
                          ),
                        if (data.fileName != null) const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            data.text,
                            style: TextStyle(
                              color: data.byCurrent
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (data.isTransfered) const Icon(Icons.done),
                        if (data.isFailed) const Icon(Icons.error),
                        if (!data.isTransfered && !data.isFailed)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              value: data.progress,
                              strokeWidth: 3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }
}
