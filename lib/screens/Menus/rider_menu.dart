import 'package:delivery_now_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class RiderMenu extends StatefulWidget {
  const RiderMenu({super.key});

  @override
  State<RiderMenu> createState() => _RiderMenuState();
}

class _RiderMenuState extends State<RiderMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rider menu"),
      ),
      body: ElevatedButton(
          onPressed: () {
            AuthService().signOut();
          },
          child: Text("Sign Out")),
    );
  }
}
