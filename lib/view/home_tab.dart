import 'dart:io';
import 'dart:ui';

import 'package:cheetah_connect/control/handle_bg.dart';
import 'package:cheetah_connect/control/paired_device.dart';
import 'package:cheetah_connect/control/paired_list.dart';
import 'package:cheetah_connect/control/utils.dart';
import 'package:cheetah_connect/view/add_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    // ConnectionBroadcast.start();
    // PairedDevice.list.load().then((value) => {setState(() {})});
    // HandleBgProcess.start();
    PairedListFg().update();

    _listener = AppLifecycleListener(
      onResume: () => HandleBgProcess.start(),
      onPause: () => HandleBgProcess.stop(),
      onExitRequested: () async {
        debugPrint('exit requested');
        HandleBgProcess.stop();
        return AppExitResponse.cancel;
      },
    );
    _checkPermissions();
  }

  void _checkPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.location.status;
      if (status.isDenied) {
        await Permission.locationAlways.request();
      }
    }
  }

  @override
  void dispose() {
    // HandleBgProcess.stop();
    debugPrint('dispose');
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ConstrainedBox(
          constraints: BoxConstraints.tight(const Size(500, 600)),
          child: Card(
            child: Column(
              children: [
                const TimeUpdate(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Paired devices",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const Divider(
                  indent: 20,
                  endIndent: 20,
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: PairedListFg(),
                    builder: (context, _) {
                      return ListView(
                        children: PairedListFg()
                            .devices
                            .map((e) => ListItem(device: e))
                            .toList(),
                      );
                    },
                  ),
                ),
                const Divider(
                  indent: 20,
                  endIndent: 20,
                  height: 0,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) => const AddDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add device'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimeUpdate extends StatefulWidget {
  const TimeUpdate({super.key});

  @override
  State<TimeUpdate> createState() => _TimeUpdateState();
}

class _TimeUpdateState extends State<TimeUpdate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FlutterBackgroundService().on('update-time'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Text('Waiting for update'));
        }
        return Text(snapshot.data!['current_date']);
      },
    );
  }
}

class ListItem extends StatelessWidget {
  const ListItem({super.key, required this.device});
  final PairedDeviceFg device;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: device,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: Icon(Utils.osIcon(device.os)),
            title: Text(device.name),
            subtitle: Text(device.isConnected ? 'Connected' : 'Not connected'),
            tileColor:
                Theme.of(context).colorScheme.secondaryContainer.withAlpha(150),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onTap: () {
              Navigator.pushNamed(context, '/device', arguments: device);
            },
          ),
        );
      },
    );
  }
}
