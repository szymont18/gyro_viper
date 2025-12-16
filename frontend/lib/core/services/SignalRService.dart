import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService extends ChangeNotifier {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;

  late HubConnection _connection;
  final String _serverUrl = "http://ADDRES_IP_BACKEND:5114/gamehub";

  String? socketId;
  dynamic currentRoomState;
  dynamic currentGameUpdate;
  
  bool _isInitialized = false;
  bool _lastOperationFailed = false;

  final StreamController<String> _errorController = StreamController.broadcast();
  Stream<String> get onError => _errorController.stream;

  final StreamController<String> _gameOverController = StreamController.broadcast();
  Stream<String> get onGameOver => _gameOverController.stream;

  final StreamController<void> _kickedController = StreamController.broadcast();
  Stream<void> get onKicked => _kickedController.stream;

  SignalRService._internal();

  void _init() {
    if (_isInitialized) return;

    _connection = HubConnectionBuilder()
      .withUrl(_serverUrl)
      .withAutomaticReconnect()
      .build();

    _connection.on("RoomState", (args) {
      if (args != null && args.isNotEmpty) {
        currentRoomState = args[0];
        notifyListeners();
      }
    });

    _connection.on("GameUpdate", (args) {
      if (args != null && args.isNotEmpty) {
        currentGameUpdate = args[0];
        notifyListeners();
      }
    });

    _connection.on("GameOver", (args) {
      if (args != null) {
        _gameOverController.add(args[0] as String);
      }
    });

    _connection.on("Error", (args) {
      if (args != null) {
        _lastOperationFailed = true;
        _errorController.add(args[0] as String);
      }
    });

    _connection.on("Kicked", (_) {
      _kickedController.add(null);
      currentRoomState = null; 
    });

    _isInitialized = true;
  }

  Future<void> _ensureConnection() async {
    if (!_isInitialized) _init();

    if (_connection.state == HubConnectionState.Disconnected) {
      try {
        await _connection.start();
        socketId = _connection.connectionId;
      } catch (e) {
        if (kDebugMode) {
          print("Connection error: $e");
        }
      }
    }
  }

  Future<void> connect() async {
    await _ensureConnection();
  }

  Future<bool> createRoom(String nickname) async {
    await _ensureConnection();
    currentRoomState = null;
    _lastOperationFailed = false;
    
    await _connection.invoke("CreateRoom", args: [nickname]);
    
    return await _waitForRoomState();
  }

  Future<bool> joinRoom(String code, String nickname) async {
    await _ensureConnection();
    currentRoomState = null;
    _lastOperationFailed = false;

    await _connection.invoke("JoinRoom", args: [code, nickname]);

    return await _waitForRoomState();
  }

  Future<bool> _waitForRoomState() async {
    int retries = 0;
    while (retries < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (_lastOperationFailed) return false;

      if (currentRoomState != null) return true;
      
      retries++;
    }
    return false;
  }

  Future<void> addBot() async {
    await _ensureConnection(); 
    await _connection.invoke("AddBot");
  }

  Future<void> removeBot() async {
    await _ensureConnection(); 
    await _connection.invoke("RemoveBot");
  }

  Future<void> kickPlayer(String playerId) async {
    await _ensureConnection();
    await _connection.invoke("KickPlayer", args: [playerId]);
  }

  Future<void> startGame() async {
    await _ensureConnection();
    await _connection.invoke("StartGame");
  }

  Future<void> sendInput(int dx, int dy) async {
    if (_isInitialized && _connection.state == HubConnectionState.Connected) {
      await _connection.invoke("SendInput", args: [dx, dy]);
    }
  }

  void leave() {
    if (_isInitialized) {
      _connection.stop();
      currentRoomState = null;
    }
  }
}