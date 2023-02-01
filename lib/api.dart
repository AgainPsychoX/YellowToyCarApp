import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

final log = Logger('api');

class CarStatus {
  /// Microseconds passed from device boot.
  final int uptime;

  /// Device time, synced using SNTP.
  final DateTime time;

  /// RSSI Signal strength of AP the device is connected to, or 0 if not connected.
  final int rssi;

  /// List of stations currently connected to our AP
  final List<String> stations;

  CarStatus(this.uptime, this.time, [this.rssi = 0, this.stations = const []]);

  CarStatus.fromJSON(Map<String, dynamic> json)
      : uptime = json['uptime'] ?? -1,
        time = DateTime.parse(json['time']),
        rssi = json['rssi'] ?? 0,
        stations = json['stations'] ?? const [];

  Map<String, dynamic> toJSON() => {
        'uptime': uptime,
        'time': time.toIso8601String(),
        'rssi': rssi,
        'stations': stations,
      };
}

class CarConnection {
  final String address;
  bool isConnected = false;

  /// Response time (in milliseconds) for last HTTP request
  int lastPing = -1;

  final Dio _client;

  CarConnection(this.address)
      : _client = Dio(BaseOptions(connectTimeout: 3333));

  /// Should be called to make sure the connection is closed and resources are freed
  void dispose() {
    _client.close();
  }

  Future<CarStatus> getStatus() async {
    final stopwatch = Stopwatch()..start();
    final response = await _client.get(Uri.http(address, '/status').toString());
    lastPing = stopwatch.elapsedMilliseconds;
    return CarStatus.fromJSON(response.data);
  }
}

class CarController extends ChangeNotifier {
  CarConnection? connection;

  get isConnected {
    return connection != null;
  }

  Future<void> connect(String address) async {
    if (connection != null) {
      await disconnect();
      notifyListeners();
    }
    try {
      log.finer("Connecting to '$address'...");
      connection = CarConnection(address);
      await connection!.getStatus();
      log.info("Connected to '$address'");
      notifyListeners();
    } catch (e, s) {
      log.warning("Failed to connect to '$address'", e, s);
      connection?.dispose();
      connection = null;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (connection != null) {
      log.info("Disconnecting from '${connection!.address}'");
      connection!.dispose();
      connection = null;
      notifyListeners();
    }
  }
}
