import 'package:cheetah_connect/control/paired.dart';
import 'package:cheetah_connect/control/utils.dart';
import 'package:cheetah_connect/view/device_page.dart';
import 'package:cheetah_connect/view/tab_layout.dart';
import 'package:flutter/material.dart';

void main() {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Utils.navigatorState = navigatorKey;
  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Cheetah Connect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      routes: {
        '/': (context) => const TabLayout(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/device') {
          final device = settings.arguments as PairedDevice;
          return MaterialPageRoute(
            builder: (context) {
              return DevicePage(device: device);
            },
          );
        }
        return null;
      },
    );
  }
}
