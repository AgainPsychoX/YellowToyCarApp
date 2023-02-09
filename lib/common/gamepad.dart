import 'dart:math';
import 'package:flutter/material.dart';

enum GamepadCrossDirection {
  up,
  left,
  right,
  down,
}

typedef GamepadCrossTapCallback = void Function(
    GamepadCrossDirection direction);
typedef GamepadInsideBuilder = List<Widget> Function(
    BuildContext context, double size);

class GamepadCross extends StatelessWidget {
  final GamepadCrossTapCallback? onTapDown;
  final GamepadCrossTapCallback? onTapUp;
  final GamepadCrossTapCallback? onPressed;
  final GamepadInsideBuilder? insideBuilder;

  const GamepadCross(
      {Key? key,
      this.onTapDown,
      this.onTapUp,
      this.onPressed,
      this.insideBuilder})
      : super(key: key);

  Widget _arrow(
      BuildContext context, double step, GamepadCrossDirection direction) {
    return GestureDetector(
      onTapDown: onTapDown == null ? null : (_) => onTapDown!(direction),
      onTapUp: onTapUp == null ? null : (_) => onTapUp!(direction),

      // TODO: fix onTapUp not working; onTapCancel used as workaround
      onTapCancel: onTapUp == null ? null : () => onTapUp!(direction),
      behavior: HitTestBehavior.translucent,

      child: SizedBox(
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
          onPressed: onPressed == null ? null : () => onPressed!(direction),
          child: Align(
            alignment: Alignment.topCenter,
            child: Icon(Icons.keyboard_arrow_up_rounded, size: 3 * step),
          ),
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
                child: RotatedBox(
                    quarterTurns: 0,
                    child: _arrow(context, step, GamepadCrossDirection.up))),
            // Right
            Positioned(
                top: 4 * step,
                left: 6 * step,
                child: RotatedBox(
                    quarterTurns: 1,
                    child: _arrow(context, step, GamepadCrossDirection.left))),
            // Bottom
            Positioned(
                top: 6 * step,
                left: 4 * step,
                child: RotatedBox(
                    quarterTurns: 2,
                    child: _arrow(context, step, GamepadCrossDirection.right))),
            // Left
            Positioned(
                top: 4 * step,
                left: 0,
                child: RotatedBox(
                    quarterTurns: 3,
                    child: _arrow(context, step, GamepadCrossDirection.down))),
            // Custom
            if (insideBuilder != null) ...insideBuilder!(context, size),
          ]),
        );
      },
    );
  }
}
