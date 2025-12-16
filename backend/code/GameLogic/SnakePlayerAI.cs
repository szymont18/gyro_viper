using backend.code.Models;


namespace backend.code.GameLogic
{
    public static class BotAI
    {
        public static (int dx, int dy) CalculateMove(Player bot, List<Position> fruits, List<Player> allPlayers, int boardSize)
        {
            var head = bot.Body.First();
            
            Position target = new Position(boardSize / 2, boardSize / 2);

            if (fruits != null && fruits.Any())
            {
                target = fruits.OrderBy(f => Math.Abs(f.X - head.X) + Math.Abs(f.Y - head.Y)).First();
            }

            var possibleMoves = new List<(int dx, int dy)>
            {
                (0, -1),
                (0, 1), 
                (-1, 0),
                (1, 0)  
            };

            var safeMoves = possibleMoves.Where(move => 
            {
                int nx = head.X + move.dx;
                int ny = head.Y + move.dy;

                if (nx < 0 || nx >= boardSize || ny < 0 || ny >= boardSize) return false;

                bool collision = allPlayers.Any(p => p.Body.Any(b => b.X == nx && b.Y == ny));
                return !collision;
            }).ToList();

            if (!safeMoves.Any()) return (bot.Dx, bot.Dy);

            return safeMoves.OrderBy(m => 
            {
                int nx = head.X + m.dx;
                int ny = head.Y + m.dy;
                return Math.Abs(nx - target.X) + Math.Abs(ny - target.Y);
            }).First();
        }
    }
}