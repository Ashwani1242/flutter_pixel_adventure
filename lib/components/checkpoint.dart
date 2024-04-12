import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:pixel_adventure/actors/player.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Checkpoint extends SpriteAnimationComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  Checkpoint({
    super.position,
    super.size,
  });
  final double stepTime = 0.05;
  CustomHitbox hitbox =
      CustomHitbox(offsetX: 18, offsetY: 50, width: 12, height: 14);

  @override
  FutureOr<void> onLoad() {
    priority = 1;
    // debugMode = true;

    add(
      RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height),
        collisionType: CollisionType.passive,
      ),
    );

    animation = SpriteAnimation.fromFrameData(
        game.images
            .fromCache("Items/Checkpoints/Checkpoint/Checkpoint (No Flag).png"),
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: stepTime,
          textureSize: Vector2.all(64),
        ));
    return super.onLoad();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) _playerCollision();
    super.onCollisionStart(intersectionPoints, other);
  }

  void _playerCollision() async {
    final flagOutAnimation = SpriteAnimation.fromFrameData(
      game.images.fromCache(
          "Items/Checkpoints/Checkpoint/Checkpoint (Flag Out) (64x64).png"),
      SpriteAnimationData.sequenced(
        amount: 26,
        stepTime: stepTime,
        textureSize: Vector2.all(64),
        loop: false,
      ),
    );
    final flagIdleAnimation = SpriteAnimation.fromFrameData(
      game.images.fromCache(
        "Items/Checkpoints/Checkpoint/Checkpoint (Flag Idle)(64x64).png",
      ),
      SpriteAnimationData.sequenced(
        amount: 10,
        stepTime: stepTime,
        textureSize: Vector2.all(64),
      ),
    );

    animation = flagOutAnimation;

    await animationTicker?.completed;
    animationTicker?.reset();

    animation = flagIdleAnimation;
  }
}
