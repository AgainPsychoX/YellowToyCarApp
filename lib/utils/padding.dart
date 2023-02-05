import 'package:flutter/widgets.dart';

extension PaddingInserters on List<Widget> {
  List<Widget> insertBetweenAll(Widget widget) {
    return List<Widget>.generate(
      length * 2 - 1,
      (i) => i % 2 == 0 ? this[i ~/ 2] : widget,
      growable: false,
    );
  }
}
