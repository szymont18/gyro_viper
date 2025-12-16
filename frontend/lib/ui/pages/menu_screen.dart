import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gyro_viper/core/services/signalrService.dart';
import 'package:gyro_viper/ui/pages/lobby_screen.dart';


class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _currentStep = 0; 
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final SignalRService _service = SignalRService();
  StreamSubscription? _errorSub;
  bool _isLoading = false;
  
  String? _topErrorMessage;
  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    _errorSub = _service.onError.listen((errorMessage) {
      _showError(errorMessage);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _errorSub?.cancel();
    _errorTimer?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _topErrorMessage = message;
    });
    
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _topErrorMessage = null;
        });
      }
    });
  }

  void _navigateToLobby() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LobbyScreen()),
    );
  }

  bool _validateNick() {
    if (_nameController.text.trim().length < 4) {
      _showError("Nickname must be at least 4 characters long!");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24)
                ),
                child: _buildStepContent(),
              ),
            ),
          ),
          
          if (_topErrorMessage != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _topErrorMessage!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _topErrorMessage = null;
                          });
                        },
                        child: const Icon(Icons.close, color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.greenAccent),
          SizedBox(height: 20),
          Text("Connecting...", style: TextStyle(color: Colors.white)),
        ],
      );
    }

    switch (_currentStep) {
      case 0:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "GYRO VIPER",
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.greenAccent),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent, 
                  foregroundColor: Colors.black
                ),
                child: const Text("START", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      
      case 1:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "CHOOSE MODE",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 2;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white
                ),
                child: const Text("CREATE ROOM"),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 3;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white
                ),
                child: const Text("JOIN ROOM"),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                });
              },
              child: const Text("BACK", style: TextStyle(color: Colors.grey)),
            ),
          ],
        );

      case 2: 
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "CREATE GAME",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "ENTER NICKNAME (MIN 4 CHARS)",
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  if (_validateNick()) {
                    setState(() => _isLoading = true);
                    bool success = await _service.createRoom(_nameController.text);
                    setState(() => _isLoading = false);

                    if (success) {
                      _navigateToLobby();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white
                ),
                child: const Text("CREATE & ENTER LOBBY"),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
              child: const Text("BACK", style: TextStyle(color: Colors.grey)),
            ),
          ],
        );

      case 3: 
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "JOIN GAME",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "ENTER NICKNAME (MIN 4 CHARS)",
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "ROOM CODE",
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  if (_codeController.text.isEmpty) {
                    _showError("Please enter Room Code!");
                    return;
                  }
                  
                  if (_validateNick()) {
                    setState(() => _isLoading = true);
                    bool success = await _service.joinRoom(_codeController.text, _nameController.text);
                    setState(() => _isLoading = false);

                    if (success) {
                      _navigateToLobby();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white
                ),
                child: const Text("JOIN LOBBY"),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
              child: const Text("BACK", style: TextStyle(color: Colors.grey)),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}