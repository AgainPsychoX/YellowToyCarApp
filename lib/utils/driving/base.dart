import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:yellow_toy_car/api.dart';

class BaseDrivingModelOptions {
  /// Interval for sending control packets.
  final Duration packetInterval;

  /// Maximal speed motor can run.
  final double maxSpeed;

  /// Minimal speed motor can run without fully stopping. Should be non-zero,
  /// so the motors doesn't generate noises, heat up or damage.
  final double minSpeed;

  /// If true, will blink the internal red light to show packets coming.
  final bool blinkOtherLight;

  const BaseDrivingModelOptions(
      {this.packetInterval = const Duration(milliseconds: 100),
      this.minSpeed = 0.1,
      this.maxSpeed = 1,
      this.blinkOtherLight = true});
}

/// Base driving model, allowing for raw operations.
class BaseDrivingModel extends CarControlData {
  BaseDrivingModelOptions options;
  DateTime lastUpdate = DateTime.now();

  CarConnection? _connection;
  Timer? _timer;

  Duration get deltaTime {
    return DateTime.now().difference(lastUpdate);
  }

  BaseDrivingModel([this.options = const BaseDrivingModelOptions()])
      : super(0.0, 0.0, false, false);

  void bind(CarConnection connection) {
    _connection = connection;
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(options.packetInterval, (_) => packet());
  }

  void dispose() {
    _timer?.cancel();
    _connection = null;
  }

  void packet() {
    if (options.blinkOtherLight) {
      otherLight = !otherLight;
    }

    update();

    // Only UDP used for normal interactions, as HTTP (TCP) might get clogged.
    _connection?.controlUsingUDP(this);
  }

  void toggleMainLight() {
    mainLight = !mainLight;
    packet();
  }

  void update() {
    if (leftMotor.abs() < options.minSpeed) {
      leftMotor = 0;
    } else {
      leftMotor = clampDouble(leftMotor, -options.maxSpeed, options.maxSpeed);
    }

    if (rightMotor.abs() < options.minSpeed) {
      rightMotor = 0;
    } else {
      rightMotor = clampDouble(rightMotor, -options.maxSpeed, options.maxSpeed);
    }

    lastUpdate = DateTime.now();
    _restartTimer();
  }

  /// Stops immediately
  void stop() {
    leftMotor = 0;
    rightMotor = 0;
    otherLight = true;
    _connection?.controlUsingUDP(this);
    _connection?.controlUsingHTTP(this);
  }

  void brake() {
    raw(0, 0);
  }

  void idle() {
    leftMotor = 0;
    rightMotor = 0;
  }

  void raw(double left, double right) {
    leftMotor = left;
    rightMotor = right;
    packet();
  }

  /// Rotates the car with given [speed] clockwise (right).
  /// Negative [speed] means counter-clockwise (left) rotation.
  void rotate([double speed = 1.0]) {
    raw(speed, -speed);
  }
}
