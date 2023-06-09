import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Utils {
  static late GlobalKey<NavigatorState> navigatorState;

  static Future<bool> showPopupDialog(Widget dialog) async {
    BuildContext? context = navigatorState.currentState?.overlay?.context;
    if (context != null) {
      bool? accept = await showDialog<bool>(
        context: context,
        builder: (context) => dialog,
      );
      return accept ?? false;
    }
    return false;
  }

  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final Random _rnd = Random();

  static String getRandomString(int length) {
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ));
  }

  static IconData osIcon(String os) {
    IconData icon = Icons.device_unknown;
    if (os == 'android') {
      icon = Icons.android;
    } else if (os == 'linux' || os == 'windows') {
      icon = Icons.computer;
    }
    return icon;
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('dd/mm/yy hh:mm:ss a').format(dt);
  }
}
