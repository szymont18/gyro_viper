using System.Collections.Concurrent;
using Microsoft.AspNetCore.SignalR;
using backend.code.GameLogic;
using backend.code.Hubs;
using backend.code.Models;

namespace backend.code.Services
{
    public class RoomManager
    {
        private readonly ConcurrentDictionary<string, GameRoom> _rooms = new();
        private readonly ConcurrentDictionary<string, string> _playerToRoomMap = new();
        private readonly IHubContext<GameHub> _hubContext;

        public RoomManager(IHubContext<GameHub> hubContext)
        {
            _hubContext = hubContext;
        }

        public GameRoom CreateRoom(string hostId, string hostName)
        {
            string code = Guid.NewGuid().ToString().Substring(0, 5).ToUpper();
            var room = new GameRoom(code, hostId, hostName);

            room.OnRoomStateChanged += async (roomCode, state) => 
            {
                await _hubContext.Clients.Group(roomCode).SendAsync("RoomState", state);
            };

            room.OnGameStateChanged += async (roomCode, update) => 
            {
                await _hubContext.Clients.Group(roomCode).SendAsync("GameUpdate", update);
            };

            room.OnGameOver += async (roomCode, message) => 
            {
                Console.WriteLine($"[Manager] Game Over in room {roomCode}. Reason: {message}");
                await _hubContext.Clients.Group(roomCode).SendAsync("GameOver", message);
            };

            _rooms.TryAdd(code, room);
            _playerToRoomMap.TryAdd(hostId, code);
            
            Console.WriteLine($"[Manager] Room CREATED: {code} by {hostName} ({hostId})");
            return room;
        }

        public GameRoom? JoinRoom(string code, string playerId, string playerName)
        {
            if (_rooms.TryGetValue(code.ToUpper(), out var room))
            {
                if (room.AddPlayer(playerId, playerName))
                {
                    _playerToRoomMap.TryAdd(playerId, code);
                    Console.WriteLine($"[Manager] {playerName} JOINED room {code}");
                    return room;
                }
                else
                {
                    Console.WriteLine($"[Manager] Join FAILED: Room {code} is full or game running.");
                }
            }
            else
            {
                Console.WriteLine($"[Manager] Join FAILED: Room {code} not found.");
            }
            return null;
        }

        public GameRoom? GetRoomByPlayer(string playerId)
        {
            if (_playerToRoomMap.TryGetValue(playerId, out var code))
            {
                if (_rooms.TryGetValue(code, out var room)) return room;
            }
            return null;
        }

        public void RemovePlayer(string playerId)
        {
            if (_playerToRoomMap.TryRemove(playerId, out var code))
            {
                if (_rooms.TryGetValue(code, out var room))
                {
                    Console.WriteLine($"[Manager] Player {playerId} leaving room {code}...");
                    room.RemovePlayer(playerId);
                    
                    if (room.PlayerCount == 0)
                    {
                        _rooms.TryRemove(code, out _);
                        Console.WriteLine($"[Manager] Room {code} removed (was empty)");
                    }
                }
            }
        }

        public GameRoom? GetRoomByCode(string code)
        {
            if (_rooms.TryGetValue(code.ToUpper(), out var room)) return room;
            return null;
        }
    }
}