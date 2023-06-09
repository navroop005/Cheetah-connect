import 'package:cheetah_connect/control/connection_finder.dart';
import 'package:cheetah_connect/control/paired.dart';
import 'package:cheetah_connect/control/utils.dart';
import 'package:cheetah_connect/view/add_device.dart';
import 'package:flutter/material.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    ConnectionFinder.start();
    PairedDevice.list.load().then((value) => {setState(() {})});
  }

  @override
  void dispose() {
    ConnectionFinder.stop();
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
                    animation: PairedDevice.list,
                    builder: (context, _) {
                      return ListView(
                        children: PairedDevice.list.devices
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

class ListItem extends StatelessWidget {
  const ListItem({super.key, required this.device});
  final PairedDevice device;
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
