import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../board/BoardObserver.dart';
import '../utils/Direction.dart';
import '../utils/GridPoint.dart';
import 'IPlayer.dart';
import 'package:sensors_plus/sensors_plus.dart';


class LocalPlayer implements IPlayer {
  // Snake body: head at index 0
  final List<GridPoint> _body;
  final BoardObserver _boardObserver;

  Direction _direction;

  @override
  Color get color => Colors.green;

  @override
  bool get alive => _alive;
  bool _alive = true;

  // Threshold for accelerometer x-axis to consider "leaning".
  // If device x (tilt) > threshold => lean right
  // If device x (tilt) < -threshold => lean left
  // You can tune this value. Typical accelerometer tilt values range ~ -9..9
  static const double tiltThreshold = 1.6; // how much tilt needed
  // The tilt must be maintained for at least this many milliseconds
  // to trigger a turn (debounce / intentional lean).
  static const int tiltHoldMilliseconds = 180;

  // Internal: stream subscription to accelerometer
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // timers to confirm tilt hold
  Timer? _rightHoldTimer;
  Timer? _leftHoldTimer;

  // Prevent repeated turns from same sustained tilt
  bool _justTurnedRecently = false;
  Timer? _turnCooldownTimer;
  static const int turnCooldownMs = 300;

  LocalPlayer({
    required List<GridPoint> initialBody,
    required BoardObserver boardObserver,
    Direction initialDirection = Direction.right,
  })  : _body = List.from(initialBody),
        _direction = initialDirection,
        _boardObserver = boardObserver{
    _startListeningToTilt();
  }

  void dispose() {
    _accelSub?.cancel();
    _rightHoldTimer?.cancel();
    _leftHoldTimer?.cancel();
    _turnCooldownTimer?.cancel();
  }

  void _startListeningToTilt() {
    // sensors_plus provides accelerometerEvents: we use x-axis to detect lean
    _accelSub = accelerometerEvents.listen((AccelerometerEvent event) {
      final double x = event.x;
      // NOTE: device axes depend on orientation; you may need to adjust sign
      // depending on how your phone behaves. This implementation assumes:
      //  - positive x means tilt to the right (landscape assumptions may vary).
      if (_justTurnedRecently) {
        // ignore tilt until cooldown expires
        return;
      }

      // Right lean
      if (x > tiltThreshold) {
        _leftHoldTimer?.cancel();
        if (_rightHoldTimer == null || !_rightHoldTimer!.isActive) {
          _rightHoldTimer = Timer(Duration(milliseconds: tiltHoldMilliseconds),
                  () {
                // final confirmation: still over threshold? (we don't have the latest event here
                // so we optimistically assume it is — this is simple and works well in practice).
                _performTurnRight();
                _rightHoldTimer?.cancel();
              });
        }
      } else if (x < -tiltThreshold) {
        _rightHoldTimer?.cancel();
        if (_leftHoldTimer == null || !_leftHoldTimer!.isActive) {
          _leftHoldTimer = Timer(Duration(milliseconds: tiltHoldMilliseconds),
                  () {
                _performTurnLeft();
                _leftHoldTimer?.cancel();
              });
        }
      } else {
        // neutral
        _rightHoldTimer?.cancel();
        _leftHoldTimer?.cancel();
      }
    });
  }

  void _performTurnLeft() {
    if (!_alive) return;
    turnLeft();
    _setTurnCooldown();
  }

  void _performTurnRight() {
    if (!_alive) return;
    turnRight();
    _setTurnCooldown();
  }

  void _setTurnCooldown() {
    _justTurnedRecently = true;
    _turnCooldownTimer?.cancel();
    _turnCooldownTimer = Timer(Duration(milliseconds: turnCooldownMs), () {
      _justTurnedRecently = false;
    });
  }

  @override
  void update() {
    if (!_alive) return;
    // move snake forward one cell
    final head = _body.first;
    final newHead = head.translate(_direction, 1);

    // Check collisions: walls or self
    if (_boardObserver.isGridPointOutOfBoundaries(newHead) || _body.contains(newHead)) {
      _alive = false;
      return;
    }

    // Insert new head, remove tail (no food implemented yet)
    _body.insert(0, newHead);
    _body.removeLast();
  }

  @override
  void turnLeft() {
    _direction = helperTurnLeft(_direction);
  }

  @override
  void turnRight() {
    _direction = helperTurnRight(_direction);
  }

  @override
  List<GridPoint> get body => _body;
}