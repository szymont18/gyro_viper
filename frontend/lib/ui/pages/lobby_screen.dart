import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gyro_viper/core/services/signalrService.dart';
import 'package:gyro_viper/ui/pages/game_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final SignalRService _service = SignalRService();
  bool _isGameStarting = false; 
  StreamSubscription? _kickSub;

  @override
  void initState() {
    super.initState();
    
    _kickSub = _service.onKicked.listen((_) {
      if (!mounted) return;
      
      Navigator.pop(context);
      _service.leave();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have been kicked by the host."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    _kickSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LOBBY"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            _service.leave();
          },
        ),
      ),
      body: AnimatedBuilder(
        animation: _service,
        builder: (context, child) {
          final state = _service.currentRoomState;
          
          if (state == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final status = state['status'] as String;
          
          if (status == 'Running' && !_isGameStarting) {
            _isGameStarting = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GameScreen()),
              );
            });
          }

          final players = state['players'] as List;
          final roomCode = state['roomCode'];
          
          bool amIHost = false;
          try {
             final me = players.firstWhere(
               (p) => p['id'] == _service.socketId, 
               orElse: () => null
             );
             if (me != null) {
               amIHost = me['isHost'];
             } else {
               amIHost = false; 
             }
          } catch(e) {
            amIHost = false;
          }

          return Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("ROOM CODE", style: TextStyle(color: Colors.grey)),
                    Text(
                      roomCode, 
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.greenAccent)
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("PLAYERS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final p = players[index];
                          return PlayerCard(
                            key: ValueKey(p['id']), 
                            player: p, 
                            isMe: p['id'] == _service.socketId,
                            amIHost: amIHost,
                            onKick: () => _service.kickPlayer(p['id']), 
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          if (amIHost && status != 'Running') ...[
                            Row(
                              children: [
                                if (players.length < 4)
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _service.addBot(),
                                        icon: const Icon(Icons.smart_toy),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blueAccent, 
                                          side: const BorderSide(color: Colors.blueAccent)
                                        ),
                                        label: const Text("ADD BOT"),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                if (players.any((p) => p['isBot'] == true))
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _service.removeBot(),
                                        icon: const Icon(Icons.remove_circle_outline),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent, 
                                          side: const BorderSide(color: Colors.redAccent)
                                        ),
                                        label: const Text("DEL BOT"),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: amIHost 
                              ? ElevatedButton.icon(
                                  onPressed: players.length >= 2 
                                      ? () => _service.startGame() 
                                      : null,
                                  icon: const Icon(Icons.play_arrow),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  label: Text(players.length < 2 ? "WAITING FOR PLAYERS..." : "START GAME"),
                                )
                              : const Center(child: Text("WAITING FOR HOST...", style: TextStyle(fontSize: 18, color: Colors.grey))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class PlayerCard extends StatelessWidget {
  final dynamic player;
  final bool isMe;
  final bool amIHost;
  final VoidCallback onKick;

  const PlayerCard({
    required Key key,
    required this.player,
    required this.isMe,
    required this.amIHost,
    required this.onKick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: ListTile(
        leading: Icon(
          player['isHost'] ? Icons.star : Icons.person,
          color: player['isHost'] ? Colors.yellow : Colors.white
        ),
        title: Text(player['name']),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe)
              const Text("(YOU)", style: TextStyle(color: Colors.green))
            else if (player['isBot'] == true)
              const Icon(Icons.smart_toy, color: Colors.blueGrey),
            
            if (amIHost && !isMe && player['isBot'] != true) ...[
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: onKick,
                tooltip: "Kick Player",
              ),
            ]
          ],
        ),
      ),
    );
  }
}