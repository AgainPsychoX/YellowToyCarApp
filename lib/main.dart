import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:yellow_toy_car/api.dart';
import 'package:yellow_toy_car/pages/about.dart';
import 'package:yellow_toy_car/pages/connection.dart';
import 'package:yellow_toy_car/pages/controls/analog.dart';
import 'package:yellow_toy_car/pages/controls/basic.dart';

void main() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      developer.log(record.message,
          time: record.time,
          level: record.level.value,
          name: record.loggerName,
          error: record.error,
          stackTrace: record.stackTrace);
    }
  });
  runApp(const MyApp());
}

final routes = <String, Widget Function(BuildContext context)>{
  '/about': (context) => const AboutPage(),
  '/connection': (context) => const ConnectionPage(),
  '/controls/basic': (context) => const BasicControlsPage(),
  '/controls/analog': (context) => const AnalogControlsPage(),
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CarController>(
            create: (context) => CarController()),
      ],
      child: MaterialApp(
        title: 'YellowToyCar',
        theme: ThemeData(
          primarySwatch: Colors.amber,
          primaryColor: const Color.fromARGB(255, 255, 192, 16),
        ),
        initialRoute: '/connection',
        routes: routes,
      ),
    );
  }
}
