import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gyro_viper/core/services/signalrService.dart';
import 'package:sensors_plus/sensors_plus.dart';


class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final SignalRService _service = SignalRService();
  StreamSubscription<AccelerometerEvent>? _subscription;
  
  DateTime _lastTurnTime = DateTime.now();
  final double _tiltThreshold = 2.5;
  double? _initialY; 
  bool _isPaused = false;
  bool _waitForReset = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _startGyroControl();
    
    _service.onGameOver.listen((reason) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("GAME OVER"),
          content: Text(reason),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
    super.dispose();
  }

  void _startGyroControl() {
    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (_isPaused) return; 

      if (_initialY == null) {
        _initialY = event.y;
        return;
      }

      double deltaY = event.y - _initialY!;

      if (deltaY.abs() < _tiltThreshold) {
        _waitForReset = false;
        return; 
      }

      if (_waitForReset) {
        return;
      }

      if (DateTime.now().difference(_lastTurnTime).inMilliseconds < 200) return;

      final update = _service.currentGameUpdate;
      if (update == null) return;

      final players = update['players'] as List;
      final me = players.firstWhere(
        (p) => p['id'] == _service.socketId, 
        orElse: () => null
      );

      if (me == null) return;
      final body = me['body'] as List;
      
      int currentDx = 1; 
      int currentDy = 0;
      
      if (body.length >= 2) {
        final head = body[0];
        final neck = body[1];
        currentDx = head['x'] - neck['x'];
        currentDy = head['y'] - neck['y'];
      }

      int newDx = currentDx;
      int newDy = currentDy;

      if (deltaY > _tiltThreshold) {
        newDx = -currentDy;
        newDy = currentDx;
      } else if (deltaY < -_tiltThreshold) {
        newDx = currentDy;
        newDy = -currentDx;
      }

      if (newDx != currentDx || newDy != currentDy) {
        _service.sendInput(newDx, newDy);
        _lastTurnTime = DateTime.now();
        _waitForReset = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900], 
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _service,
            builder: (context, child) {
              final update = _service.currentGameUpdate;
              if (update == null) {
                return const Center(child: Text("Waiting for server...", style: TextStyle(color: Colors.white)));
              }

              return SizedBox.expand(
                child: CustomPaint(
                  painter: GamePainter(update, _service.socketId),
                ),
              );
            },
          ),
          
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.pause_circle_filled, color: Colors.black, size: 50),
              onPressed: () {
                setState(() {
                  _isPaused = true;
                });
              },
            ),
          ),

          if (_isPaused)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("PAUSED", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20)
                      ),
                      onPressed: () {
                        setState(() {
                          _initialY = null;
                          _isPaused = false;
                        });
                      },
                      child: const Text("RESUME & RECALIBRATE", style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20)
                      ),
                      onPressed: () {
                        _service.leave();
                        Navigator.pop(context);
                      },
                      child: const Text("QUIT", style: TextStyle(fontSize: 24)),
                    ),
                  ],
                ),
              ),
            ),
            
          if (!_isPaused)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.black45,
                child: const Center(
                  child: Text(
                    "TILT & RETURN TO CENTER",
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final dynamic update;
  final String? myId;
  static const int boardSize = 30;
  static const double viewPortTiles = 16.0; 

  GamePainter(this.update, this.myId);

  @override
  void paint(Canvas canvas, Size size) {
    if (update == null) return;

    canvas.drawPaint(Paint()..color = Colors.blue[900]!);

    final double cellSize = size.height / viewPortTiles;

    final players = update['players'] as List;
    final me = players.firstWhere((p) => p['id'] == myId, orElse: () => null);

    double cameraX = 0;
    double cameraY = 0;

    if (me != null && me['body'] != null && (me['body'] as List).isNotEmpty) {
      final head = me['body'][0];
      cameraX = head['x'] * cellSize;
      cameraY = head['y'] * cellSize;
    } else {
      cameraX = (boardSize * cellSize) / 2;
      cameraY = (boardSize * cellSize) / 2;
    }

    final double screenCenterX = size.width / 2;
    final double screenCenterY = size.height / 2;

    canvas.save();
    canvas.translate(screenCenterX - cameraX - (cellSize / 2), screenCenterY - cameraY - (cellSize / 2));

    final Paint boardPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, boardSize * cellSize, boardSize * cellSize),
      boardPaint
    );

    final fruits = update['fruits'] as List? ?? [];
    
    for (var fruit in fruits) {
      double cx = fruit['x'] * cellSize + cellSize / 2;
      double cy = fruit['y'] * cellSize + cellSize / 2;
      double radius = cellSize / 2 - 2;

      Paint fruitPaint = Paint()..color = Colors.red;
      canvas.drawCircle(Offset(cx, cy), radius, fruitPaint);

      fruitPaint.color = Colors.green;
      fruitPaint.strokeWidth = 3;
      canvas.drawLine(Offset(cx, cy - radius), Offset(cx + 5, cy - radius - 5), fruitPaint);
    }

    for (var p in players) {
      bool isAlive = p['isAlive'];
      bool isBot = p['isBot'];
      bool isMe = p['id'] == myId;

      Color bodyColor;
      Color headColor;

      if (!isAlive) {
        bodyColor = Colors.grey[400]!;
        headColor = Colors.grey[600]!;
      } else if (isMe) {
        bodyColor = Colors.blue;
        headColor = Colors.blue[900]!;
      } else if (isBot) {
        bodyColor = Colors.yellow[700]!;
        headColor = Colors.orange[900]!;
      } else {
        bodyColor = Colors.green;
        headColor = Colors.green[900]!;
      }

      final body = p['body'] as List;
      if (body.isEmpty) continue;

      Paint snakePaint = Paint()..style = PaintingStyle.fill;

      snakePaint.color = bodyColor;
      for (int i = 1; i < body.length; i++) {
        var segment = body[i];
        canvas.drawRect(
          Rect.fromLTWH(
            segment['x'] * cellSize, 
            segment['y'] * cellSize, 
            cellSize + 0.5, 
            cellSize + 0.5
          ),
          snakePaint,
        );
      }

      final head = body.first;
      snakePaint.color = headColor;
      canvas.drawRect(
        Rect.fromLTWH(
          head['x'] * cellSize, 
          head['y'] * cellSize, 
          cellSize + 0.5, 
          cellSize + 0.5
        ),
        snakePaint,
      );
      
      if (isAlive) {
        snakePaint.color = Colors.white;
        double eyeSize = cellSize * 0.2;
        canvas.drawCircle(
          Offset(head['x'] * cellSize + cellSize * 0.3, head['y'] * cellSize + cellSize * 0.3), 
          eyeSize, 
          snakePaint
        );
        canvas.drawCircle(
          Offset(head['x'] * cellSize + cellSize * 0.7, head['y'] * cellSize + cellSize * 0.3), 
          eyeSize, 
          snakePaint
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}