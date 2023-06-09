import 'package:cheetah_connect/view/home_tab.dart';
import 'package:cheetah_connect/view/settings_tab.dart';
import 'package:flutter/material.dart';

class TabLayout extends StatefulWidget {
  const TabLayout({super.key});

  @override
  State<TabLayout> createState() => _TabLayoutState();
}

class _TabLayoutState extends State<TabLayout> {
  late bool showSideNavigation;
  late bool extendedSideNavigation;
  int screenIndex = 0;

  void setIndex(int index) {
    setState(() {
      screenIndex = index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showSideNavigation = MediaQuery.of(context).size.width >= 750;
    extendedSideNavigation = MediaQuery.of(context).size.width >= 900;
  }

  @override
  Widget build(BuildContext context) {
    return showSideNavigation
        ? buildSidebarScaffold()
        : buildBottomBarScaffold();
  }

  Widget buildSidebarScaffold() {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: <Widget>[
            NavigationRail(
              extended: extendedSideNavigation,
              labelType:
                  extendedSideNavigation ? null : NavigationRailLabelType.all,
              minWidth: 50,
              destinations: destinations.map(
                (Destination destination) {
                  return NavigationRailDestination(
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        destination.label,
                        style: extendedSideNavigation
                            ? const TextStyle(fontSize: 16)
                            : null,
                      ),
                    ),
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                  );
                },
              ).toList(),
              selectedIndex: screenIndex,
              onDestinationSelected: setIndex,
              elevation: 10,
            ),
            Expanded(child: destinations[screenIndex].body),
          ],
        ),
      ),
    );
  }

  Widget buildBottomBarScaffold() {
    return Scaffold(
      body: destinations[screenIndex].body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: screenIndex,
        onDestinationSelected: setIndex,
        destinations: destinations.map(
          (Destination destination) {
            return NavigationDestination(
              label: destination.label,
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
              tooltip: destination.label,
            );
          },
        ).toList(),
        height: 70,
      ),
    );
  }
}

class Destination {
  const Destination(this.label, this.icon, this.selectedIcon, this.body);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final Widget body;
}

const List<Destination> destinations = <Destination>[
  Destination(
    'Home',
    Icon(Icons.home_outlined),
    Icon(Icons.home),
    HomeTab(),
  ),
  Destination(
    'Settings',
    Icon(Icons.settings_outlined),
    Icon(Icons.settings),
    SettingsTab(),
  ),
];
