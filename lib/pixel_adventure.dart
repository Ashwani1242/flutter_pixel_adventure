import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/actors/player.dart';
import 'package:pixel_adventure/components/utilities.dart';
import 'package:pixel_adventure/levels/level.dart';

class PixelAdventure extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  @override
  Color backgroundColor() => const Color(0xFF211F30);
  late CameraComponent cam;
  Player player = Player();
  late JoystickComponent joystick;

  bool showMobileControls = false;

  List<String> levelNames = ['Level_01', 'Level_02'];
  int currentLevelIndex = 0;

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    _loadLevel();

    if (showMobileControls) {
      addJoystick();
      add(JumpButton());
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showMobileControls) {
      joystickMovement();
    }
    super.update(dt);
  }

  void joystickMovement() {
    switch (joystick.direction) {
      case JoystickDirection.left ||
            JoystickDirection.upLeft ||
            JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right ||
            JoystickDirection.upRight ||
            JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }

  void addJoystick() {
    joystick = JoystickComponent(
      priority: 2,
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
      ),
      background: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Joystick.png'),
        ),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );

    add(joystick);
  }

  void loadNextLevel() {
    removeWhere((component) => component is Level);

    if (currentLevelIndex < levelNames.length - 1) {
      currentLevelIndex++;
      _loadLevel();
    } else {}
  }

  void _loadLevel() {
    Future.delayed(
      const Duration(seconds: 1),
      () {
        Level myWorld =
            Level(levelName: levelNames[currentLevelIndex], player: player);

        cam = CameraComponent.withFixedResolution(
          world: myWorld,
          width: 640,
          height: 360,
        );
        cam.priority = 1;
        cam.viewfinder.anchor = Anchor.topLeft;

        addAll([cam, myWorld]);
      },
    );
  }
}
