import 'package:flutter/material.dart';
import 'learn_screen.dart';
import 'camera_inference_screen.dart';
import 'profile_screen.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'dart:async';


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const LearnScreen(),
    const CameraInferenceScreen(),
    const ProfileScreen(),
  ];

  late StreamSubscription<bool> keyboardSubscription;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    keyboardSubscription = KeyboardVisibilityController().onChange.listen((isVisible) {
      setState(() {
        _isKeyboardVisible = isVisible;
      });
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(
                  icon: Icons.book,
                  label: 'Learn',
                  index: 0,
                ),
                const SizedBox(width: 40), // Space for FAB
                _buildTabItem(
                  icon: Icons.person,
                  label: 'Profile',
                  index: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _isKeyboardVisible ? null : FloatingActionButton(
        onPressed: () => _onItemTapped(1),
        backgroundColor: const Color.fromARGB(255, 75, 167, 481),
        child: const Icon(Icons.camera_alt, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color.fromARGB(255, 75, 167, 481) : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color.fromARGB(255, 75, 167, 481) : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
