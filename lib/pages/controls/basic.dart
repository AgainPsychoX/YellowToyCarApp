import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yellow_toy_car/api.dart';
import 'package:yellow_toy_car/common/car_camera.dart';
import 'package:yellow_toy_car/common/drawer.dart';
import 'package:yellow_toy_car/common/gamepad.dart';
import 'package:yellow_toy_car/utils/driving/vectorized_smooth.dart';

class BasicControls extends StatefulWidget {
  final CarConnection connection;

  const BasicControls({Key? key, required this.connection}) : super(key: key);

  @override
  State<BasicControls> createState() => _BasicControlsState();
}

class _BasicControlsState extends State<BasicControls> {
  final _options = const SmoothedDrivingModelOptions(
    speedResponse: 1.0,
    speedDecay: 1.0,
    directionResponse: 1.0,
    directionDecay: 2.0,
  );
  final _drivingModel = SmoothedVectorizedDrivingModel();

  @override
  void initState() {
    super.initState();
    _drivingModel.options = _options;
    _drivingModel.bind(widget.connection);

    // Lock orientation for now, as landscape is not implemented
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _drivingModel.stop();
    _drivingModel.dispose();
    super.dispose();
  }

  bool get isDisabled => !widget.connection.isConnected;

  List<Widget> _gamepadInsideBuilder(BuildContext context, double size) {
    final step = size / 11;
    final cornerButtonStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.zero,
      backgroundColor: Theme.of(context).primaryColorLight,
    );
    return [
      // Rotate left
      Positioned(
        top: step / 2,
        left: step / 2,
        child: GestureDetector(
          onTapDown: (_) => _drivingModel.rotate(-0.5),
          onTapUp: (_) => _drivingModel.brake(),
          child: ElevatedButton(
            onPressed: () {},
            style: cornerButtonStyle,
            child: Icon(Icons.rotate_left_rounded, size: 3 * step),
          ),
        ),
      ),
      // Rotate right
      Positioned(
        top: step / 2,
        right: step / 2,
        child: GestureDetector(
          onTapDown: (_) => _drivingModel.rotate(0.5),
          onTapUp: (_) => _drivingModel.brake(),
          child: ElevatedButton(
            onPressed: () {},
            style: cornerButtonStyle,
            child: Icon(Icons.rotate_right_rounded, size: 3 * step),
          ),
        ),
      ),
      // Stop
      Positioned(
        bottom: step / 2,
        left: step / 2,
        child: GestureDetector(
          onTapDown: (_) => _drivingModel.stop(),
          onTapUp: (_) => _drivingModel.stop(),
          child: ElevatedButton(
            onPressed: () => {},
            style: cornerButtonStyle,
            child: Icon(Icons.stop_rounded, size: 3 * step),
          ),
        ),
      ),
      // Action
      Positioned(
        bottom: step / 2,
        right: step / 2,
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
        child: GamepadCross(
          onPressed: isDisabled ? null : (_) {},
          onTapDown: (direction) {
            debugPrint('onTapDown $direction');
            switch (direction) {
              case GamepadCrossDirection.up:
                _drivingModel.throttle(1.0);
                break;
              case GamepadCrossDirection.left:
                _drivingModel.turn(-1.0);
                break;
              case GamepadCrossDirection.right:
                _drivingModel.turn(1.0);
                break;
              case GamepadCrossDirection.down:
                _drivingModel.throttle(-1.0);
                break;
            }
          },
          onTapUp: (direction) {
            debugPrint('onTapUp $direction');
            switch (direction) {
              case GamepadCrossDirection.up:
              case GamepadCrossDirection.down:
                _drivingModel.throttleIdle();
                break;
              case GamepadCrossDirection.left:
              case GamepadCrossDirection.right:
                _drivingModel.turnIdle();
                break;
            }
          },
          insideBuilder: _gamepadInsideBuilder,
        ),
      ),
    );
  }
}

class BasicControlsPage extends StatefulWidget {
  const BasicControlsPage({Key? key}) : super(key: key);

  @override
  State<BasicControlsPage> createState() => _BasicControlsPageState();
}

class _BasicControlsPageState extends State<BasicControlsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text('Basic controls'),
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
            BasicControls(connection: connection),
          ],
        );
      }),
    );
  }
}
