import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/painting.dart';

class BackgroundTile extends ParallaxComponent {
  final String color;
  BackgroundTile({
    super.position,
    this.color = 'Gray',
  });

  final double scrollSpeed = 40;

  @override
  FutureOr<void> onLoad() async {
    size = Vector2.all(64);
    priority = -10;

    parallax = await game.loadParallax(
      [ParallaxImageData('Background/$color.png')],
      baseVelocity: Vector2(0, -scrollSpeed),
      repeat: ImageRepeat.repeat,
      fill: LayerFill.none,
    );

    return super.onLoad();
  }
}
