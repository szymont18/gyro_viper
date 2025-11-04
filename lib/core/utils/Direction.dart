enum Direction { up, right, down, left }

Direction helperTurnLeft(Direction d) {
  switch (d) {
    case Direction.up:
      return Direction.left;
    case Direction.left:
      return Direction.down;
    case Direction.down:
      return Direction.right;
    case Direction.right:
      return Direction.up;
  }
}

Direction helperTurnRight(Direction d) {
  switch (d) {
    case Direction.up:
      return Direction.right;
    case Direction.right:
      return Direction.down;
    case Direction.down:
      return Direction.left;
    case Direction.left:
      return Direction.up;
  }
}