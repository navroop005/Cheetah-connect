import 'package:cheetah_connect/control/details.dart';
import 'package:flutter/material.dart';

class AddRequest extends StatelessWidget {
  const AddRequest({super.key, required this.details});
  final DeviceDetail details;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connection Request'),
      content: Text(
          'Device name: ${details.name}\nOS: ${details.os} \nIP: ${details.ipv4}'),
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, true);
          },
          icon: const Icon(Icons.check),
          label: const Text('Accept'),
          style: ElevatedButton.styleFrom(foregroundColor: Colors.green),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, false);
          },
          icon: const Icon(Icons.close),
          label: const Text('Reject'),
          style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }
}
