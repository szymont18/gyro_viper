
import 'components/Snake.dart';

abstract class IPlayer {
  void turnLeft();
  void turnRight();
  bool isAlive();

  Snake get snake;
}