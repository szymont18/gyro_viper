import '../utils/GridPoint.dart';
import 'Board.dart';

class BoardObserver {

  Board _board;

  BoardObserver(this._board);


  bool isGridPointOutOfBoundaries(GridPoint point)
  {
      return _board.isOutOfBounds(point);
  }
}