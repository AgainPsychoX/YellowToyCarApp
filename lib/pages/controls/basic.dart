import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yellow_toy_car/api.dart';
import 'package:yellow_toy_car/common/car_camera.dart';
import 'package:yellow_toy_car/common/drawer.dart';

enum GamepadCrossDirection {
  up,
  left,
  right,
  down,
  rotateLeft,
  rotateRight,
}

typedef GamepadCrossTapCallback = void Function(
    GamepadCrossDirection direction);
typedef GamepadInsideBuilder = List<Widget> Function(
    BuildContext context, double size);

class GamepadCross extends StatelessWidget {
  final GamepadCrossTapCallback? onTapDown;
  final GamepadCrossTapCallback? onTapUp;
  final GamepadInsideBuilder? insideBuilder;

  const GamepadCross(
      {Key? key, this.onTapDown, this.onTapUp, this.insideBuilder})
      : super(key: key);

  Widget _arrow(BuildContext context, double step) {
    return SizedBox(
      height: 5 * step,
      width: 3 * step,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(1.5 * step),
              bottomRight: Radius.circular(1.5 * step),
            ),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: () {},
        child: Align(
          alignment: Alignment.topCenter,
          child: Icon(Icons.keyboard_arrow_up_rounded, size: 3 * step),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxHeight, constraints.maxWidth);
        final step = size / 11;
        return SizedBox.square(
          dimension: size,
          child: Stack(children: [
            // Top
            Positioned(
              top: 0,
              left: 4 * step,
              child: RotatedBox(quarterTurns: 0, child: _arrow(context, step)),
            ),
            // Right
            Positioned(
              top: 4 * step,
              left: 6 * step,
              child: RotatedBox(quarterTurns: 1, child: _arrow(context, step)),
            ),
            // Bottom
            Positioned(
              top: 6 * step,
              left: 4 * step,
              child: RotatedBox(quarterTurns: 2, child: _arrow(context, step)),
            ),
            // Left
            Positioned(
              top: 4 * step,
              left: 0,
              child: RotatedBox(quarterTurns: 3, child: _arrow(context, step)),
            ),
            // Custom
            if (insideBuilder != null) ...insideBuilder!(context, size),
          ]),
        );
      },
    );
  }
}

class BasicControlsPage extends StatefulWidget {
  const BasicControlsPage({Key? key}) : super(key: key);

  @override
  State<BasicControlsPage> createState() => _BasicControlsPageState();
}

class _BasicControlsPageState extends State<BasicControlsPage> {
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
        child: ElevatedButton(
          onPressed: () {},
          style: cornerButtonStyle,
          child: Icon(Icons.rotate_left_rounded, size: 3 * step),
        ),
      ),
      // Rotate right
      Positioned(
        top: step / 2,
        right: step / 2,
        child: ElevatedButton(
          onPressed: () {},
          style: cornerButtonStyle,
          child: Icon(Icons.rotate_right_rounded, size: 3 * step),
        ),
      ),
      // Stop
      Positioned(
        bottom: step / 2,
        left: step / 2,
        child: ElevatedButton(
          onPressed: () {},
          style: cornerButtonStyle,
          child: Icon(Icons.stop_rounded, size: 3 * step),
        ),
      ),
      // Action
      Positioned(
        bottom: step / 2,
        right: step / 2,
        child: ElevatedButton(
          onPressed: () {},
          style: cornerButtonStyle,
          child: SizedBox.square(
            dimension: 3 * step,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FittedBox(
                fit: BoxFit.fill,
                child: Icon(Icons.flashlight_on_rounded),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('mainScaffold'),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GamepadCross(
                  onTapDown: (direction) {},
                  onTapUp: (direction) {},
                  insideBuilder: _gamepadInsideBuilder,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
