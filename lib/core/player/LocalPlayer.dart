import 'dart:async' as async;
import 'package:flame/components.dart';
import 'package:gyro_viper/core/player/components/Snake.dart';
import 'IPlayer.dart';
import 'package:sensors_plus/sensors_plus.dart';


class LocalPlayer implements IPlayer {
  static const double tiltThreshold = 2.5;
  static const int tiltHoldMilliseconds = 150;

  final Snake _snake;
  @override
  Snake get snake => _snake;

  async.StreamSubscription<AccelerometerEvent>? _accelSub;

  async.Timer? _rightHoldTimer;
  async.Timer? _leftHoldTimer;

  bool _justTurnedRecently = false;
  async.Timer? _turnCooldownTimer;
  static const int turnCooldownMs = 300;

  LocalPlayer({required Snake snake})
    : _snake = snake
  {
    _startListeningToTilt();
  }

  void dispose() {
    _accelSub?.cancel();
    _rightHoldTimer?.cancel();
    _leftHoldTimer?.cancel();
    _turnCooldownTimer?.cancel();
  }

  void _startListeningToTilt() {
    _accelSub = accelerometerEvents.listen((AccelerometerEvent event) {
      final double y = event.y;

      if (_justTurnedRecently) {
        // ignore tilt until cooldown expires
        return;
      }
      if (_turnLeftAccelerometerHandle(y) || _turnRightAccelerometerHandle(y))
        {
          return;
        }
      _rightHoldTimer?.cancel();
      _leftHoldTimer?.cancel();
    });
  }

  bool _turnLeftAccelerometerHandle(double y) {
    if (y > tiltThreshold) {
      _rightHoldTimer?.cancel();
      if (_leftHoldTimer == null || !_leftHoldTimer!.isActive) {
        _leftHoldTimer =
            async.Timer(Duration(milliseconds: tiltHoldMilliseconds),
                    () {
                  _performTurnLeft();
                  _leftHoldTimer?.cancel();
                });
        return true;
      }
    }
    return false;
  }

  bool _turnRightAccelerometerHandle(double y) {
    if (y < -tiltThreshold) {
      _leftHoldTimer?.cancel();
      if (_rightHoldTimer == null || !_rightHoldTimer!.isActive) {
        _rightHoldTimer =
            async.Timer(Duration(milliseconds: tiltHoldMilliseconds),
                    () {
              _performTurnRight();
              _rightHoldTimer?.cancel();
            });
        return true;
      }
    }
    return false;
  }

  void _performTurnLeft() {
    if (!isAlive()) return;
    turnLeft();
    _setTurnCooldown();
  }

  void _performTurnRight() {
    if (!isAlive()) return;
    turnRight();
    _setTurnCooldown();
  }

  void _setTurnCooldown() {
    _justTurnedRecently = true;
    _turnCooldownTimer?.cancel();
    _turnCooldownTimer = async.Timer(Duration(milliseconds: turnCooldownMs), () {
      _justTurnedRecently = false;
    });
  }

  @override
  void turnLeft() {
    _snake.turnLeft();
  }

  @override
  void turnRight() {
    _snake.turnRight();
  }

  @override
  bool isAlive() {
    return _snake.isAlive;
  }

}