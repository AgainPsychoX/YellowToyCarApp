import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.home_rounded),
            title: const Text('Home page'),
            onTap: () => Navigator.pushNamed(context, '/home'),
          ),
        ],
      ),
    );
  }
}
