import 'base.dart';

/// Driving model where movement is represented by a vector of direction and speed.
class VectorizedDrivingModel extends BaseDrivingModel {
  static const neutralDirection = 0.0;

  bool isRaw = false;

  double direction = neutralDirection;
  double speed = 0;

  VectorizedDrivingModel([super.options]);

  @override
  void update() {
    if (!isRaw) {
      leftMotor = speed * (1.0 + direction) / (1.0 + direction.abs());
      rightMotor = speed * (1.0 - direction) / (1.0 + direction.abs());
    }
    super.update();
  }

  @override
  void stop() {
    isRaw = true;
    speed = 0;
    direction = neutralDirection;
    super.stop();
  }

  @override
  void brake() {
    isRaw = false;
    speed = 0;
  }

  @override
  void idle() {
    turnIdle();
    throttleIdle();
  }

  @override
  void raw(double left, double right) {
    isRaw = true;
    super.raw(left, right);
  }

  void turn([double direction = neutralDirection]) {
    isRaw = false;
    this.direction = direction;
    packet();
  }

  void turnIdle() {
    isRaw = false;
    direction = neutralDirection;
  }

  void throttle([double speed = 0]) {
    isRaw = false;
    this.speed = speed;
    packet();
  }

  void throttleIdle() {
    isRaw = false;
    speed = 0;
  }
}
