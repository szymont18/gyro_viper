import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/board/Board.dart';
import '../../core/board/BoardObserver.dart';
import '../../core/player/LocalPlayer.dart';
import '../../core/utils/Direction.dart';
import '../../core/utils/GridPoint.dart';
import '../painters/board_painter.dart';


class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  SnakeGamePageState createState() => SnakeGamePageState();
}


class SnakeGamePageState extends State<SnakeGamePage> {
  late Board board = Board(cols: 20, rows: 30, tickMs: 150);
  LocalPlayer? localPlayer;

  // grid configuration
  final int cols = 20;
  final int rows = 30;
  final double cellSize = 14.0;

  // redraw timer for UI: refresh at same tick as board
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    board.stop();
    localPlayer?.dispose();
    _uiTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    // Clean up previous
    board?.stop();

    board = Board(cols: cols, rows: rows, tickMs: 150);

    // initial snake in center, length 6 going right
    final startX = (cols / 4).floor();
    final startY = (rows / 2).floor();
    final initial = List.generate(6, (i) => GridPoint(startX - i, startY));
    localPlayer?.dispose();
    BoardObserver boardObserver = BoardObserver(board);

    localPlayer = LocalPlayer(initialBody: initial, boardObserver: boardObserver, initialDirection: Direction.right);
    board.addPlayer(localPlayer!);

    board.start();

    // UI update timer
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(Duration(milliseconds: board.tickMs ~/ 1), (_) {
      if (mounted) setState(() {}); // redraw
      if (board.allPlayersDead()) {
        // stop timers to preserve state; user can tap to restart
        board.stop();
      }
    });

    setState(() {});
  }

  void _onTap() {
    if (board.allPlayersDead() || !board.running) {
      _startNewGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = cols * cellSize;
    final height = rows * cellSize;
    return Scaffold(
      appBar: AppBar(title: const Text('Gyro Snake (Local Solo)')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _onTap,
              child: Container(
                width: width + 2,
                height: height + 2,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: CustomPaint(
                  painter: BoardPainter(
                    board: board,
                    cellSize: cellSize,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(board.allPlayersDead() ? 'Game over — tap to restart' : 'Tilt phone left/right to steer'),
            const SizedBox(height: 8),
            _buildControlsHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsHint() {
    return Column(
      children: [
        Text(
          'LocalPlayer settings:\n'
              'tiltThreshold = ${LocalPlayer.tiltThreshold.toStringAsFixed(2)}, holdMs = ${LocalPlayer.tiltHoldMilliseconds}ms',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: () {
            // quick manual left/right controls for debugging on desktop/emulator
            setState(() {
              localPlayer?.turnLeft();
            });
          },
          child: const Text('Manual Turn Left (debug)'),
        ),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: () {
            setState(() {
              localPlayer?.turnRight();
            });
          },
          child: const Text('Manual Turn Right (debug)'),
        ),
      ],
    );
  }
}