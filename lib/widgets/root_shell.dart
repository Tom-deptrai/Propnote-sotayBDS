import 'package:flutter/material.dart';

import '../screens/add_property/add_property_screen.dart';
import '../screens/list/list_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../theme/app_colors.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final List<Widget> _screens = const [
    MapScreen(),
    ListScreen(),
    SettingsScreen(),
  ];

  void _openAddProperty() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddPropertyScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: _index == 2
          ? null
          : FloatingActionButton(
              onPressed: _openAddProperty,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'Bản đồ'),
    (
      icon: Icons.view_list_outlined,
      activeIcon: Icons.view_list_rounded,
      label: 'Danh sách',
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Cài đặt',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              final color = selected ? AppColors.navy : AppColors.textTertiary;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color: color,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
