import 'package:gyro_viper/core/player/components/Snake.dart';

import 'IPlayer.dart';

class OutsidePlayer implements IPlayer {
  @override
  void turnLeft() {
    throw UnimplementedError('OutsidePlayer.turnLeft is not implemented yet.');
  }

  @override
  void turnRight() {
    throw UnimplementedError('OutsidePlayer.turnRight is not implemented yet.');
  }

  @override
  bool isAlive() {
    throw UnimplementedError();
  }

  @override
  Snake get snake => throw UnimplementedError();
}