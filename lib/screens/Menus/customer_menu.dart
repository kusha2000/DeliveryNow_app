import 'package:delivery_now_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class CustomerMenu extends StatefulWidget {
  const CustomerMenu({super.key});

  @override
  State<CustomerMenu> createState() => _CustomerMenuState();
}

class _CustomerMenuState extends State<CustomerMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customer menu"),
      ),
      body: ElevatedButton(
          onPressed: () {
            AuthService().signOut();
          },
          child: Text("Sign Out")),
    );
  }
}
