import 'dart:ui';
import '../board/BoardObserver.dart';
import '../utils/GridPoint.dart';

abstract class IPlayer {
  /// Called every tick to advance the player
  void update();

  /// Ask the player to turn left/right (90 degrees)
  void turnLeft();
  void turnRight();

  /// The snake body positions (head = first element)
  List<GridPoint> get body;

  /// Color used when rendering
  Color get color;

  /// Whether the player is alive
  bool get alive;
}