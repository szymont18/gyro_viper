import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../player/IPlayer.dart';
import '../utils/GridPoint.dart';

class Board {
  final int cols;
  final int rows;

  // Game tick interval in milliseconds
  final int tickMs;

  // Players on the board
  final List<IPlayer> players = [];

  Timer? _gameTimer;
  bool running = false;

  Board({required this.cols, required this.rows, this.tickMs = 200});

  /// Add a player to the board
  void addPlayer(IPlayer p) => players.add(p);

  /// Start the game loop
  void start() {
    stop();
    running = true;
    _gameTimer = Timer.periodic(Duration(milliseconds: tickMs), (_) {
      tick();
    });
  }

  /// Stop the game loop
  void stop() {
    _gameTimer?.cancel();
    _gameTimer = null;
    running = false;
  }

  /// Advance all players one tick
  void tick() {
    for (final p in players) {
      try {
        p.update();
      } catch (e) {
        // Keep tick robust even if a player is not implemented
        debugPrint('Player update error: $e');
      }
    }
  }

  bool isOutOfBounds(GridPoint p) {
    return p.x < 0 || p.x >= cols || p.y < 0 || p.y >= rows;
  }

  /// Return whether all players are dead
  bool allPlayersDead() {
    if (players.isEmpty) return true;
    return players.every((p) => !p.alive);
  }
}