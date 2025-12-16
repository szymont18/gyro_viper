using Microsoft.AspNetCore.SignalR;
using backend.code.Services;
using backend.code.Models;

namespace backend.code.Hubs
{
    public class GameHub : Hub
    {
        private readonly RoomManager _manager;

        public GameHub(RoomManager manager)
        {
            _manager = manager;
        }

        public async Task CreateRoom(string playerName)
        {
            Console.WriteLine($"[Hub] CreateRoom request from {Context.ConnectionId} ({playerName})");
            var room = _manager.CreateRoom(Context.ConnectionId, playerName);
            await Groups.AddToGroupAsync(Context.ConnectionId, room.RoomCode);

            await Clients.Caller.SendAsync("RoomState", new RoomStateDto(
                room.RoomCode,
                room.Players.Select(p => p.ToDto()).ToList(),
                "Lobby"
            ));
        }

        public async Task JoinRoom(string roomCode, string playerName)
        {
            var existingRoom = _manager.GetRoomByCode(roomCode);
            
            if (existingRoom == null)
            {
                await Clients.Caller.SendAsync("Error", "Room does not exist!");
                return;
            }

            var room = _manager.JoinRoom(roomCode, Context.ConnectionId, playerName);
            if (room != null)
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, room.RoomCode);
                
                await Clients.Caller.SendAsync("RoomState", new RoomStateDto(
                    room.RoomCode,
                    room.Players.Select(p => p.ToDto()).ToList(),
                    "Lobby"
                ));
            }
            else
            {
                await Clients.Caller.SendAsync("Error", "Nickname taken or Room is full/running!");
            }
        }

        public void AddBot()
        {
            var room = _manager.GetRoomByPlayer(Context.ConnectionId);
            if (room != null && room.HostId == Context.ConnectionId)
            {
                Console.WriteLine($"[Hub] AddBot request in room {room.RoomCode}");
                room.AddBot();
            }
        }

        public void RemoveBot()
        {
            var room = _manager.GetRoomByPlayer(Context.ConnectionId);
            if (room != null && room.HostId == Context.ConnectionId)
            {
                Console.WriteLine($"[Hub] RemoveBot request in room {room.RoomCode}");
                room.RemoveLastBot();
            }
        }

        public void StartGame()
        {
            var room = _manager.GetRoomByPlayer(Context.ConnectionId);
            if (room != null && room.HostId == Context.ConnectionId)
            {
                Console.WriteLine($"[Hub] StartGame request in room {room.RoomCode}");
                room.StartGame();
            }
        }

        public void SendInput(int dx, int dy)
        {
            var room = _manager.GetRoomByPlayer(Context.ConnectionId);
            room?.HandleInput(Context.ConnectionId, dx, dy);
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            Console.WriteLine($"[Hub] Disconnected: {Context.ConnectionId}");
            _manager.RemovePlayer(Context.ConnectionId);
            await base.OnDisconnectedAsync(exception);
        }

        public async Task KickPlayer(string playerId)
        {
            var room = _manager.GetRoomByPlayer(Context.ConnectionId);
            if (room != null && room.HostId == Context.ConnectionId)
            {
                await Clients.Client(playerId).SendAsync("Kicked");
                room.RemovePlayer(playerId);
                await Groups.RemoveFromGroupAsync(playerId, room.RoomCode);
            }
        }
    }
}