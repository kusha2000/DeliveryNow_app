import 'package:delivery_now_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class StaffMenu extends StatefulWidget {
  const StaffMenu({super.key});

  @override
  State<StaffMenu> createState() => _StaffMenuState();
}

class _StaffMenuState extends State<StaffMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Staff menu"),
      ),
      body: ElevatedButton(
          onPressed: () {
            AuthService().signOut();
          },
          child: Text("Sign Out")),
    );
  }
}
