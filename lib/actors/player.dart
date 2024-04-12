import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/saw.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/utilities.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState { idle, run, jump, fall, hit, spawn, despawn }

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  Player({super.position});

  double fixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  late final SpriteAnimation idleAnim;
  late final SpriteAnimation runAnim;
  late final SpriteAnimation jumpAnim;
  late final SpriteAnimation fallAnim;
  late final SpriteAnimation hitAnim;
  late final SpriteAnimation spawnAnim;
  late final SpriteAnimation despawnAnim;

  final double stepTime = 0.05;

  final double _gravity = 9.8;
  final double _jumpForce = 320;
  final double _terminalVelocity = 360;

  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();

  bool isOnGround = false;
  bool hasJumped = false;
  bool gotHit = false;
  bool reachedCheckpoint = false;

  List<CollisionBlock> collisionBlocks = [];
  CustomHitbox hitbox =
      CustomHitbox(offsetX: 10, offsetY: 6, width: 14, height: 26);

  Vector2 startingPosition = Vector2.zero();

  @override
  FutureOr<void> onLoad() {
    priority = 10;
    _loadAllAnimations();
    // debugMode = true;

    startingPosition = Vector2(position.x, position.y);

    add(
      RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height),
      ),
    );
    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;

    while (accumulatedTime >= fixedDeltaTime) {
      if (!gotHit && !reachedCheckpoint) {
        _playerState();
        _playerMovement(fixedDeltaTime);
        _checkHorizontalCollisions();
        _applyGravity(fixedDeltaTime);
        _checkVerticalCollisions();
      }

      accumulatedTime -= fixedDeltaTime;
    }

    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;

    final isLeftKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
            keysPressed.contains(LogicalKeyboardKey.keyA);
    final isRightKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
            keysPressed.contains(LogicalKeyboardKey.keyD);

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    hasJumped = keysPressed.contains(LogicalKeyboardKey.space);

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      if (other is Fruit) {
        other.collisionWithPlayer();
      }
      if (other is Saw) {
        _respawn();
      }
      if (other is Checkpoint) {
        _reachedCheckpoint();
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _loadAllAnimations() {
    idleAnim =
        _spriteAnimations('Main Characters/Pink Man/Idle (32x32).png', 11);
    runAnim =
        _spriteAnimations('Main Characters/Pink Man/Run (32x32).png', 12); //
    jumpAnim =
        _spriteAnimations('Main Characters/Pink Man/Jump (32x32).png', 1);
    fallAnim =
        _spriteAnimations('Main Characters/Pink Man/Fall (32x32).png', 1);

    hitAnim = _spriteAnimations('Main Characters/Pink Man/Hit (32x32).png', 7)
      ..loop = false;

    spawnAnim = _spriteAnimationsForSpecialBehavior(
        'Main Characters/Appearing (96x96).png', 7, Vector2.all(96));
    despawnAnim = _spriteAnimationsForSpecialBehavior(
        'Main Characters/Desappearing (96x96).png', 7, Vector2.all(96));

    animations = {
      PlayerState.idle: idleAnim,
      PlayerState.run: runAnim,
      PlayerState.jump: jumpAnim,
      PlayerState.fall: fallAnim,
      PlayerState.hit: hitAnim,
      PlayerState.spawn: spawnAnim,
      PlayerState.despawn: despawnAnim,
    };

    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimations(String characterPath, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache(
        characterPath,
      ),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );
  }

  SpriteAnimation _spriteAnimationsForSpecialBehavior(
      String characterPath, int amount, Vector2 textureSize) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache(
        characterPath,
      ),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: textureSize,
        loop: false,
      ),
    );
  }

  void _playerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    if (velocity.x != 0) {
      playerState = PlayerState.run;
    }

    if (velocity.y > 0) {
      playerState = PlayerState.fall;
    }

    if (velocity.y < 0) {
      playerState = PlayerState.jump;
    }

    current = playerState;
  }

  void _playerMovement(double dt) {
    if (hasJumped && isOnGround) _playerJump(dt);

    if (velocity.y > _gravity) isOnGround = false;

    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.offsetX + hitbox.width;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
            break;
          }
        }
      }
    }
  }

  void _respawn() async {
    gotHit = true;
    current = PlayerState.hit;

    await animationTicker?.completed;
    animationTicker?.reset();

    current = PlayerState.spawn;
    scale.x = 1;
    position = startingPosition - Vector2.all(32);

    await animationTicker?.completed;
    animationTicker?.reset();

    position = startingPosition;
    current = PlayerState.idle;
    Future.delayed(const Duration(milliseconds: 250), () => gotHit = false);
  }

  void _reachedCheckpoint() async {
    reachedCheckpoint = true;
    current = PlayerState.despawn;
    if (scale.x > 0) {
      position = position - Vector2.all(32);
    } else if (scale.x < 0) {
      position = position + Vector2(32, -32);
    }

    await animationTicker?.completed;
    animationTicker?.reset();

    reachedCheckpoint = false;
    position = Vector2.all(-640);

    Future.delayed(
      const Duration(seconds: 3),
      () {
        game.loadNextLevel();
      },
    );
  }
}
