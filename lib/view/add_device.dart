import 'package:cheetah_connect/control/connection.dart';
import 'package:cheetah_connect/control/connection_finder.dart';
import 'package:cheetah_connect/control/details.dart';
import 'package:cheetah_connect/control/utils.dart';
import 'package:flutter/material.dart';

class AddDialog extends StatefulWidget {
  const AddDialog({
    super.key,
  });

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      title: Text('Add device'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NetworkDetailWidget(),
          AvailableList(),
        ],
      ),
    );
  }
}

class NetworkDetailWidget extends StatefulWidget {
  const NetworkDetailWidget({super.key});

  @override
  State<NetworkDetailWidget> createState() => _NetworkDetailWidgetState();
}

class _NetworkDetailWidgetState extends State<NetworkDetailWidget> {
  Future<NetworkDetails> details = NetworkDetails.getDetails();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: details,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
              'Current Network: ${snapshot.data?.name}\nDevice IP: ${snapshot.data?.ipv4}');
        } else if (snapshot.hasError) {
          return const Text('Error');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}

class AvailableList extends StatefulWidget {
  const AvailableList({super.key});

  @override
  State<AvailableList> createState() => _AvailableListState();
}

class _AvailableListState extends State<AvailableList> {
  @override
  void initState() {
    ConnectionFinder.startPairBroadcast();
    ConnectionFinder.updateAvailable = () {
      setState(() {});
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          const Text(
            'Available devices',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(
            height: 300,
            width: 350,
            child: (ConnectionFinder.availableDevices.isEmpty)
                ? const Center(
                    child: Text('Finding devices'),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: deviceList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget deviceList() {
    return ListView(
      children: ConnectionFinder.availableDevices.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ConnectingDialog(detail: e),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 50),
            ),
            child: Row(
              children: [
                Icon(Utils.osIcon(e.os)),
                Expanded(child: Center(child: Text(e.name))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    ConnectionFinder.stopPairBroadcast();
    super.dispose();
  }
}

class ConnectingDialog extends StatefulWidget {
  const ConnectingDialog({super.key, required this.detail});
  final DeviceDetail detail;

  @override
  State<ConnectingDialog> createState() => _ConnectingDialogState();
}

class _ConnectingDialogState extends State<ConnectingDialog> {
  late final Future<bool> connected = Connection.initiatePair(widget.detail);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Connecting with ${widget.detail.name}'),
      content: SizedBox(
        width: 200,
        height: 100,
        child: Center(
          child: FutureBuilder(
            future: connected,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!) {
                  return const Text("Connected");
                } else {
                  return const Text("Unable to connect");
                }
              } else if (snapshot.hasError) {
                return const Text("Error connecting");
              }
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
