import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:provider/provider.dart';
import 'package:yellow_toy_car/api.dart';
import 'package:yellow_toy_car/common/car_camera.dart';
import 'package:yellow_toy_car/common/drawer.dart';
import 'package:yellow_toy_car/utils/driving/vectorized_smooth.dart';

class AnalogControls extends StatefulWidget {
  final CarConnection connection;

  const AnalogControls({Key? key, required this.connection}) : super(key: key);

  @override
  State<AnalogControls> createState() => _AnalogControlsState();
}

class _AnalogControlsState extends State<AnalogControls> {
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
        top: 0,
        right: 0,
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
        bottom: 0,
        left: 0,
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
              child: AspectRatio(
                aspectRatio: 1,
                child: Joystick(
                  listener: (details) {
                    _drivingModel.targetDirection = details.x;
                    _drivingModel.targetSpeed = details.y;
                  },
                  onStickDragEnd: () => _drivingModel.idle(),
                  stick: const MyJoystickStick(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyJoystickStick extends StatelessWidget {
  const MyJoystickStick({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColorLight,
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

class AnalogControlsPage extends StatefulWidget {
  const AnalogControlsPage({Key? key}) : super(key: key);

  @override
  State<AnalogControlsPage> createState() => _AnalogControlsPageState();
}

class _AnalogControlsPageState extends State<AnalogControlsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text('Analog controls'),
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
            AnalogControls(connection: connection),
          ],
        );
      }),
    );
  }
}
