import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:yellow_toy_car/api.dart';
import 'package:yellow_toy_car/common/car_camera.dart';
import 'package:yellow_toy_car/common/drawer.dart';
import 'package:yellow_toy_car/utils/driving/vectorized_smooth.dart';

final log = Logger('gyro');

class SensorsControls extends StatefulWidget {
  final CarConnection connection;

  const SensorsControls({Key? key, required this.connection}) : super(key: key);

  @override
  State<SensorsControls> createState() => _SensorsControlsState();
}

extension NiceAccelerometerEvent on AccelerometerEvent {
  String toStringNice() {
    return 'X: ${x.toStringAsFixed(3)} Y: ${y.toStringAsFixed(3)} Z: ${z.toStringAsFixed(3)}';
  }
}

class _SensorsControlsState extends State<SensorsControls> {
  final _options = const SmoothedDrivingModelOptions(
    speedResponse: 1.0,
    speedDecay: 1.0,
    directionResponse: 1.0,
    directionDecay: 2.0,
  );
  final _drivingModel = SmoothedVectorizedDrivingModel();
  late StreamSubscription<AccelerometerEvent> _streamSubscription;
  AccelerometerEvent? _reference;
  bool get isRunning => !_streamSubscription.isPaused;

  void _calibrate() async {
    // TODO: average for calibration, start-stop calibration button
    try {
      final e = await accelerometerEvents.first
          .timeout(const Duration(milliseconds: 500));
      log.info('Calibrated! Reference: ${e.toStringNice()}');
      setState(() {
        _reference = e;
      });
    } catch (e) {
      // TODO: display toast with message
    }
  }

  void _togglePause() async {
    if (_streamSubscription.isPaused) {
      _streamSubscription.resume();
      log.finer('Resume');
      _drivingModel.isRaw = false;
    } else {
      _streamSubscription.pause();
      log.finer('Pause');
      _drivingModel.stop();
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _drivingModel.options = _options;
    _drivingModel.bind(widget.connection);

    _streamSubscription = accelerometerEvents.listen((event) {
      if (_reference == null) return;
      // TOOD: add nice options instead hardcoding ;_;
      _drivingModel.targetDirection = -(event.x - _reference!.x) / 10;
      _drivingModel.targetSpeed = -(event.y - _reference!.y) / 10;
    });
    _streamSubscription.pause();

    // Lock orientation for now, as landscape is not implemented
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    _drivingModel.stop();
    _drivingModel.dispose();
    super.dispose();
  }

  bool get isDisabled => !widget.connection.isConnected;

  List<Widget> _buttonsBuild(BuildContext context) {
    final step = 20.0;
    final cornerButtonStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.zero,
      backgroundColor: Theme.of(context).primaryColorLight,
    );
    return [
      // Rotate left
      Positioned(
        top: 0,
        left: 0,
        child: Listener(
          onPointerDown: (_) => _drivingModel.rotate(-0.5),
          onPointerUp: (_) => _drivingModel.brake(),
          onPointerCancel: (_) => _drivingModel.brake(),
          child: ElevatedButton(
            onPressed: () {},
            style: cornerButtonStyle,
            child: Icon(Icons.rotate_left_rounded, size: 3 * step),
          ),
        ),
      ),
      // Rotate right
      Positioned(
        top: 0,
        right: 0,
        child: Listener(
          onPointerDown: (_) => _drivingModel.rotate(0.5),
          onPointerUp: (_) => _drivingModel.brake(),
          onPointerCancel: (_) => _drivingModel.brake(),
          child: ElevatedButton(
            onPressed: () {},
            style: cornerButtonStyle,
            child: Icon(Icons.rotate_right_rounded, size: 3 * step),
          ),
        ),
      ),
      // Stop
      Positioned(
        bottom: 0,
        left: 0,
        child: Listener(
          onPointerDown: (_) => _drivingModel.stop(),
          onPointerUp: (_) => _drivingModel.stop(),
          onPointerCancel: (_) => _drivingModel.stop(),
          child: ElevatedButton(
            onPressed: () => {},
            style: cornerButtonStyle,
            child: Icon(Icons.stop_rounded, size: 3 * step),
          ),
        ),
      ),
      // Action
      Positioned(
        bottom: 0,
        right: 0,
        child: ElevatedButton(
          onPressed: () {
            setState(() => _drivingModel.toggleMainLight());
          },
          style: cornerButtonStyle,
          child: SizedBox.square(
            dimension: 3 * step,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FittedBox(
                fit: BoxFit.fill,
                child: _drivingModel.mainLight
                    ? const Icon(Icons.flashlight_off_rounded)
                    : const Icon(Icons.flashlight_on_rounded),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Container(), // to expand stack area to make buttons stick to edges
            ..._buttonsBuild(context),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _calibrate,
                    child: const Text('Calibrate'),
                  ),

                  // Feed
                  StreamBuilder(
                    stream: accelerometerEvents,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        log.warning(
                            'Error accessing accelerometer', snapshot.error);
                        return const Text('Error accessing accelerometer');
                      }
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final e = snapshot.data!;
                      return Text(e.toStringNice());
                    },
                  ),

                  // Calibration value
                  if (_reference == null)
                    const Text('Calibration is required')
                  else
                    Text(_reference!.toStringNice()),

                  const SizedBox(height: 40),
                  SizedBox.square(
                    dimension: 100,
                    child: ElevatedButton(
                      onPressed: _reference == null ? null : _togglePause,
                      child:
                          isRunning ? const Text('Stop') : const Text('Start'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SensorsControlsPage extends StatefulWidget {
  const SensorsControlsPage({Key? key}) : super(key: key);

  @override
  State<SensorsControlsPage> createState() => _SensorsControlsPageState();
}

class _SensorsControlsPageState extends State<SensorsControlsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text('Sensors controls'),
      ),
      body: Consumer<CarController>(builder: (context, controller, child) {
        if (controller.connection == null) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
          return const Center(child: CircularProgressIndicator());
        }
        final connection = controller.connection!;
        return Column(
          children: [
            CarCameraView(uri: connection.cameraStreamUri),
            SensorsControls(connection: connection),
          ],
        );
      }),
    );
  }
}
