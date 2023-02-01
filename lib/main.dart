import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:yellow_toy_car/api.dart';
import 'pages/home.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CarController?>(
            create: (context) => CarController()),
      ],
      child: MaterialApp(
        title: 'YellowToyCar',
        theme: ThemeData(
          primarySwatch: Colors.amber,
          primaryColor: const Color.fromARGB(255, 255, 192, 16),
        ),
        initialRoute: '/home',
        routes: {
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}
