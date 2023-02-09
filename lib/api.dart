import 'dart:io';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:sprintf/sprintf.dart';

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
  final InternetAddress address;
  bool isConnected = false;

  /// Response time (in milliseconds) for last HTTP request
  int lastPing = -1;

  Uri get cameraStreamUri {
    return Uri(scheme: 'http', host: address.host, port: 81, path: '/stream');
  }

  final Dio _dio;
  final RawDatagramSocket _udp;

  CarConnection._(this.address, this._dio, this._udp);

  static Future<CarConnection> prepare(InternetAddress address) async {
    final dio = Dio(BaseOptions(connectTimeout: 3333));

    final udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    // TODO: implement some ping mechanism in the UDP server and use here to test UDP connection

    return CarConnection._(address, dio, udp);
  }

  /// Should be called to make sure the connection is closed and resources are freed
  void dispose() {
    _dio.close();
    _udp.close();
  }

  Future<CarStatus> getStatus() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.getUri(Uri.http(address.host, '/status'));
      lastPing = stopwatch.elapsedMilliseconds;
      isConnected = true;
      return CarStatus.fromJSON(response.data);
    } catch (_) {
      isConnected = false;
      rethrow;
    }
  }

  void controlUsingUDP(CarControlData data) {
    // debugPrint(sprintf('UDP: F:%02X T:0ms L:%.2f R:%.2f',
    //     [data.flags, data.leftMotor * 100, data.rightMotor * 100]));
    _udp.send(data.toLongPacket().buffer.asInt8List(), address, 83);
  }

  void controlUsingHTTP(CarControlData data) {
    // TODO: actually code control in HTTP server of the car
    // _dio
    //     .postUri(
    //       Uri.http(address.host, '/config'),
    //       data: data.toJSON(),
    //       options: Options(receiveTimeout: 1),
    //     )
    //     .ignore();
  }
}

class CarController extends ChangeNotifier {
  CarConnection? connection;

  get isConnected {
    return connection != null;
  }

  Future<void> connect(String address) async {
    var resolvedAddress = InternetAddress.tryParse(address);
    try {
      if (resolvedAddress == null) {
        log.finer("Resolving '$address'...");
        resolvedAddress = (await InternetAddress.lookup(address)).first;
      }
    } catch (e, s) {
      log.warning("Failed to resolve address '$address'", e, s);
      rethrow;
    }

    if (connection != null) {
      await disconnect();
      notifyListeners();
    }
    try {
      log.finer("Connecting to $resolvedAddress...");
      connection = await CarConnection.prepare(resolvedAddress);
      await connection!.getStatus();
      log.info("Connected to $resolvedAddress");
      notifyListeners();
    } catch (e, s) {
      log.warning("Failed to connect to $resolvedAddress", e, s);
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

/// Set of data used to control the car.
///
/// Motor values range from 0.0 to 1.0 (full stop to full speed).
class CarControlData {
  double leftMotor;
  double rightMotor;
  bool mainLight;
  bool otherLight;

  CarControlData(
      this.leftMotor, this.rightMotor, this.mainLight, this.otherLight);

  int get flags {
    int flags = 0;
    if (mainLight) flags |= 1 << 0;
    if (otherLight) flags |= 1 << 1;
    if (leftMotor < 0) flags |= 1 << 6;
    if (rightMotor < 0) flags |= 1 << 7;
    return flags;
  }

  ByteData toShortPacket() {
    final bytes = ByteData(12);

    bytes.setUint8(0, 1); // Packet type: 1 for long control packet.
    bytes.setUint8(1, flags);
    bytes.setUint8(2, (leftMotor * 255).round());
    bytes.setUint8(3, (rightMotor * 255).round());

    return bytes;
  }

  ByteData toLongPacket() {
    final bytes = ByteData(12);

    bytes.setUint8(0, 2); // Packet type: 2 for long control packet.
    bytes.setUint8(1, flags);
    bytes.setUint16(2, 0); // Not used currently, need to be 0.
    bytes.setFloat32(4, leftMotor * 100);
    bytes.setFloat32(8, rightMotor * 100);

    return bytes;
  }

  Map<String, dynamic> toJSON() => {
        'control': {
          'left': leftMotor,
          'right': rightMotor,
          'mainLight': mainLight,
          'otherLight': otherLight,
        },
        'silent': true,
      };
}
