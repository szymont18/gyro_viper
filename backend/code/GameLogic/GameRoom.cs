using backend.code.Models;
using System.Timers;
using Timer = System.Timers.Timer;

namespace backend.code.GameLogic
{
    public class GameRoom
    {
        public string RoomCode { get; }
        public string HostId { get; private set; }
        public int PlayerCount => Players.Count;

        private const int MaxPlayers = 4;
        private const int BoardSize = 30;
        
        public readonly List<Player> Players = new();
        private readonly List<Position> _fruits = new();
        
        private Timer _gameTimer;
        private bool _isRunning = false;
        private readonly object _lock = new();
        
        private DateTime _nextFruitSpawnTime;
        private readonly Random _rnd = new Random();

        public event Func<string, GameUpdateDto, Task> OnGameStateChanged;
        public event Func<string, RoomStateDto, Task> OnRoomStateChanged;
        public event Func<string, string, Task> OnGameOver;

        public GameRoom(string code, string hostId, string hostName)
        {
            RoomCode = code;
            HostId = hostId;
            AddPlayer(hostId, hostName);
        }

        public bool AddPlayer(string id, string name)
        {
            lock (_lock)
            {
                if (_isRunning || Players.Count >= MaxPlayers) return false;
                
                if (Players.Any(p => p.Name.Equals(name, StringComparison.OrdinalIgnoreCase))) 
                {
                    return false;
                }

                if (Players.Any(p => p.Id == id)) return true;

                Players.Add(new Player(id, name, id == HostId));
                BroadcastRoomState();
                return true;
            }
        }

        public void AddBot()
        {
            lock (_lock)
            {
                if (_isRunning || Players.Count >= MaxPlayers) return;
                
                var botId = "BOT_" + Guid.NewGuid().ToString().Substring(0, 4);
                var bot = new Player(botId, "SnakeAI 🤖", false, true);
                Players.Add(bot);
                
                BroadcastRoomState();
            }
        }

        public void RemoveLastBot()
        {
            lock (_lock)
            {
                if (_isRunning) return;

                var bot = Players.LastOrDefault(p => p.IsBot);
                if (bot != null)
                {
                    Players.Remove(bot);
                    BroadcastRoomState();
                }
            }
        }

        public void RemovePlayer(string id)
        {
            lock (_lock)
            {
                var p = Players.FirstOrDefault(x => x.Id == id);
                if (p == null) return;
                
                Players.Remove(p);
                
                if (p.Id == HostId && Players.Count > 0)
                {
                    var nextRealPlayer = Players.FirstOrDefault(x => !x.IsBot);
                    if (nextRealPlayer != null)
                    {
                        nextRealPlayer.IsHost = true;
                        HostId = nextRealPlayer.Id;
                    }
                    else if (Players.Count > 0)
                    {
                        Players[0].IsHost = true;
                        HostId = Players[0].Id;
                    }
                }
                
                if (Players.Count(x => !x.IsBot) == 0)
                {
                    StopGame("All players left");
                }
                else if (Players.Count < 2 && _isRunning)
                {
                    StopGame("Not enough players");
                }
                else
                {
                    BroadcastRoomState();
                }
            }
        }

        public void StartGame()
        {
            lock (_lock)
            {
                if (Players.Count < 2) return; 
                
                _isRunning = true;
                
                int startY = 5;
                foreach (var p in Players)
                {
                    p.Reset(5, startY += 5);
                }
                
                _fruits.Clear();
                SpawnFruit();
                ScheduleNextFruit();

                _gameTimer = new Timer(900);
                _gameTimer.Elapsed += GameLoop;
                _gameTimer.Start();
                
                BroadcastRoomState();
            }
        }

        private void ScheduleNextFruit()
        {
            int seconds = _rnd.Next(4, 11);
            _nextFruitSpawnTime = DateTime.Now.AddSeconds(seconds);
        }

        private void StopGame(string reason)
        {
            _isRunning = false;
            _gameTimer?.Stop();
            OnGameOver?.Invoke(RoomCode, reason);
            BroadcastRoomState();
        }

        public void HandleInput(string playerId, int dx, int dy)
        {
            var p = Players.FirstOrDefault(x => x.Id == playerId);
            if (p != null && p.IsAlive && !p.IsBot)
            {
                if (p.Dx + dx != 0 || p.Dy + dy != 0) 
                {
                    p.PendingDx = dx;
                    p.PendingDy = dy;
                }
            }
        }

        private void GameLoop(object? sender, ElapsedEventArgs e)
        {
            lock (_lock)
            {
                if (!_isRunning) return;

                if (DateTime.Now >= _nextFruitSpawnTime)
                {
                    SpawnFruit();
                    ScheduleNextFruit();
                }

                foreach (var p in Players.Where(x => x.IsBot && x.IsAlive))
                {
                    var move = BotAI.CalculateMove(p, _fruits, Players, BoardSize);
                    p.Dx = move.dx;
                    p.Dy = move.dy;
                    p.PendingDx = move.dx;
                    p.PendingDy = move.dy;
                }

                int aliveCount = 0;

                foreach (var p in Players.Where(x => x.IsAlive))
                {
                    p.Dx = p.PendingDx;
                    p.Dy = p.PendingDy;

                    var head = p.Body.First();
                    var newHead = new Position(head.X + p.Dx, head.Y + p.Dy);

                    if (newHead.X < 0 || newHead.X >= BoardSize || newHead.Y < 0 || newHead.Y >= BoardSize)
                    {
                        p.IsAlive = false; 
                        continue;
                    }

                    bool hitBody = false;
                    foreach (var other in Players)
                    {
                        if (other.Body.Any(b => b.X == newHead.X && b.Y == newHead.Y))
                        {
                            hitBody = true;
                            break;
                        }
                    }

                    if (hitBody)
                    {
                        p.IsAlive = false;
                        continue;
                    }

                    p.Body.Insert(0, newHead);
                    
                    var eatenFruit = _fruits.FirstOrDefault(f => f.X == newHead.X && f.Y == newHead.Y);

                    if (eatenFruit != null)
                    {
                        _fruits.Remove(eatenFruit);
                        if (_fruits.Count == 0)
                        {
                            SpawnFruit();
                        }
                    }
                    else
                    {
                        p.Body.RemoveAt(p.Body.Count - 1);
                    }
                    
                    aliveCount++;
                }

                if (aliveCount <= 1 && Players.Count > 1) 
                {
                    var winner = Players.FirstOrDefault(x => x.IsAlive);
                    StopGame(winner != null ? $"{winner.Name} Wins!" : "Draw!");
                    return;
                }

                var update = new GameUpdateDto(
                    Players.Select(p => p.ToDto()).ToList(),
                    _fruits.ToList()
                );
                
                OnGameStateChanged?.Invoke(RoomCode, update);
            }
        }

        private void SpawnFruit()
        {
            if (_fruits.Count >= 15) return;

            int attempts = 0;
            while (attempts < 100)
            {
                int x = _rnd.Next(0, BoardSize);
                int y = _rnd.Next(0, BoardSize);
                
                bool occupiedBySnake = Players.Any(p => p.Body.Any(b => b.X == x && b.Y == y));
                bool occupiedByFruit = _fruits.Any(f => f.X == x && f.Y == y);

                if (!occupiedBySnake && !occupiedByFruit)
                {
                    _fruits.Add(new Position(x, y));
                    return;
                }
                attempts++;
            }
        }

        private void BroadcastRoomState()
        {
            var dto = new RoomStateDto(
                RoomCode, 
                Players.Select(p => p.ToDto()).ToList(), 
                _isRunning ? "Running" : "Lobby"
            );
            OnRoomStateChanged?.Invoke(RoomCode, dto);
        }
    }

    public class Player
    {
        public string Id { get; }
        public string Name { get; }
        public bool IsHost { get; set; }
        public bool IsAlive { get; set; }
        public bool IsBot { get; set; }
        public List<Position> Body { get; set; } = new();
        public int Dx { get; set; } = 1;
        public int Dy { get; set; } = 0;
        public int PendingDx { get; set; } = 1;
        public int PendingDy { get; set; } = 0;

        public Player(string id, string name, bool isHost, bool isBot = false)
        {
            Id = id;
            Name = name;
            IsHost = isHost;
            IsBot = isBot;
            IsAlive = true;
        }

        public void Reset(int x, int y)
        {
            IsAlive = true;
            Body.Clear();
            Body.Add(new Position(x, y));
            Body.Add(new Position(x - 1, y));
            Body.Add(new Position(x - 2, y));
            Dx = 1; Dy = 0;
            PendingDx = 1; PendingDy = 0;
        }

        public PlayerDto ToDto() => new PlayerDto(Id, Name, IsHost, IsAlive, IsBot, Body);
    }
}