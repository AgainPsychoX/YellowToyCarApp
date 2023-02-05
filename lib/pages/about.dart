import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yellow_toy_car/common/drawer.dart';
import 'package:yellow_toy_car/utils/links.dart';

const authorName = 'Patryk Ludwikowski';
const authorEmail = 'patryk.ludwikowski.7+flutter@gmail.com';
const authorDiscord = 'Patryk (PsychoX)#7966';
const appSourcesUrl = 'https://github.com/AgainPsychoX/YellowToyCarApp';
const carSourcesUrl = 'https://github.com/AgainPsychoX/YellowToyCar';
const _note = '''
Aplikacja przygotowana w ramach zaliczenia przedmiotu Programowanie Urządzeń Mobilnych, Uniwersytet Rzeszowski 2023.
''';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('mainScaffold'),
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        children: [
          ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Author'),
              subtitle: const Text(authorName),
              onTap: () {}),
          ListTile(
            leading: const Icon(Icons.email_rounded),
            title: const Text('E-mail'),
            subtitle: const Text(authorEmail),
            onTap: () => launchOrCopyMail(authorEmail, context),
          ),
          ListTile(
              leading: const Icon(Icons.discord_rounded),
              title: const Text('Discord'),
              subtitle: const Text(authorDiscord),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: authorDiscord));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Discord ID copied to the clipboard'),
                ));
              }),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: const Text('App source code repository'),
            subtitle: Text(
              appSourcesUrl.replaceFirst('https://', ''),
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () => launchOrCopyUrl(appSourcesUrl, context),
          ),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: const Text('Car source code repository'),
            subtitle: Text(
              carSourcesUrl.replaceFirst('https://', ''),
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () => launchOrCopyUrl(carSourcesUrl, context),
          ),
          // TODO: add technologies used
          const Divider(),
          const ListTile(subtitle: Text(_note)),
        ],
      ),
    );
  }
}
