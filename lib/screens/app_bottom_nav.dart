import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 80, // 👈 fixed height
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: onTap,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                "assets/messages.png",
                height: 45, // 👈 reduce size
                width: 45,
                color: selectedIndex == 0 ? Colors.green : Colors.black54,
              ),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                "assets/calls.png",
                height: 35,
                width: 35,
                color: selectedIndex == 1 ? Colors.green : Colors.black54,
              ),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                "assets/contacts.png",
                height: 45,
                width: 45,
                color: selectedIndex == 2 ? Colors.green : Colors.black54,
              ),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                "assets/settings.png",
                height: 45,
                width: 45,
                color: selectedIndex == 3 ? Colors.green : Colors.black54,
              ),
              label: "",
            ),
          ],
        ),
      ),
    );
  }
}

