import 'base.dart';
import 'vectorized.dart';
import 'dart:math';

class SmoothedDrivingModelOptions extends BaseDrivingModelOptions {
  /// Speed change (per second) towards target value.
  final double speedResponse;

  /// Drop in speed (per second) when idle.
  final double speedDecay;

  /// Factor on how fast direction changes (per second) towards target value.
  final double directionResponse;

  /// Factor on how fast direction returns (per second) to neutral.
  final double directionDecay;

  const SmoothedDrivingModelOptions(
      {this.speedResponse = 1,
      this.speedDecay = 0.5,
      this.directionResponse = 1,
      this.directionDecay = 0.5,
      super.packetInterval = const Duration(milliseconds: 100),
      super.minSpeed = 0.1,
      super.maxSpeed = 1,
      super.blinkOtherLight = true});
}

/// Driving model where movement is represented by a vector of direction
/// and speed, with smoothing by limiting values change in time.
class SmoothedVectorizedDrivingModel extends VectorizedDrivingModel {
  double targetSpeed = 0;
  double targetDirection = VectorizedDrivingModel.neutralDirection;

  SmoothedDrivingModelOptions get optionsAsSmoothed {
    return options as SmoothedDrivingModelOptions;
  }

  SmoothedVectorizedDrivingModel(
      [super.options = const SmoothedDrivingModelOptions()]);

  @override
  void update() {
    final delta = deltaTime.inMilliseconds / 1000;

    final speedDelta = delta *
        (targetSpeed == 0
            ? optionsAsSmoothed.speedDecay
            : optionsAsSmoothed.speedResponse);
    if (speed < targetSpeed) {
      speed = min(targetSpeed, speed + speedDelta);
    } else {
      speed = max(targetSpeed, speed - speedDelta);
    }

    final directionDelta = delta *
        (targetDirection == VectorizedDrivingModel.neutralDirection
            ? optionsAsSmoothed.directionDecay
            : optionsAsSmoothed.directionResponse);
    if (direction < targetDirection) {
      direction = min(targetDirection, direction + directionDelta);
    } else {
      direction = max(targetDirection, direction - directionDelta);
    }

    super.update();
  }

  @override
  void stop() {
    targetSpeed = 0;
    targetDirection = VectorizedDrivingModel.neutralDirection;
    super.stop();
  }

  @override
  void brake() {
    isRaw = false;
    targetSpeed = -0.0001; // dirty way to use response instead decay
  }

  @override
  void idle() {
    turnIdle();
    throttleIdle();
  }

  @override
  void turn([double direction = VectorizedDrivingModel.neutralDirection]) {
    isRaw = false;
    targetDirection = direction;
  }

  @override
  void turnIdle() {
    isRaw = false;
    targetDirection = VectorizedDrivingModel.neutralDirection;
  }

  @override
  void throttle([double speed = 0]) {
    isRaw = false;
    targetSpeed = speed;
  }

  @override
  void throttleIdle() {
    isRaw = false;
    targetSpeed = 0;
  }

  // TODO: smoothing for rotation
}
