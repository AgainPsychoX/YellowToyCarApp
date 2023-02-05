import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yellow_toy_car/api.dart';

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
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 200));
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/connection');
              }
            },
          ),
          ListTile(
            enabled: Provider.of<CarController>(context).isConnected,
            leading: const Icon(Icons.videogame_asset_rounded),
            title: const Text('Basic controls'),
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 200));
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/controls/basic');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About'),
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 200));
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/about');
              }
            },
          ),
        ],
      ),
    );
  }
}
