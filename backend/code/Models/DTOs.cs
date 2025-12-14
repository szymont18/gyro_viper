

namespace backend.code.Models
{
    public record Position(int X, int Y);
    
    public record PlayerDto(string Id, string Name, bool IsHost, bool IsAlive, bool IsBot, List<Position> Body);
    
    public record RoomStateDto(string RoomCode, List<PlayerDto> Players, string Status);
    
    public record GameUpdateDto(List<PlayerDto> Players, List<Position> Fruits);
}