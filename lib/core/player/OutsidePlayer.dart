import 'dart:ui';
import '../utils/GridPoint.dart';
import 'IPlayer.dart';

class OutsidePlayer implements IPlayer {
  @override
  void update() {
    throw UnimplementedError('OutsidePlayer.update is not implemented yet.');
  }

  @override
  void turnLeft() {
    throw UnimplementedError('OutsidePlayer.turnLeft is not implemented yet.');
  }

  @override
  void turnRight() {
    throw UnimplementedError('OutsidePlayer.turnRight is not implemented yet.');
  }

  @override
  List<GridPoint> get body => throw UnimplementedError();

  @override
  Color get color => throw UnimplementedError();

  @override
  bool get alive => throw UnimplementedError();
}