import 'dart:ui';

import 'package:flame/components.dart';
import 'package:gyro_viper/core/player/IPlayer.dart';

class PlayerAlive extends Component{

  final List<IPlayer> players;
  final VoidCallback onPlayersNotAlive;

  PlayerAlive({required this.players, required this.onPlayersNotAlive});

  @override
  void update(double dt)
  {
    if (players.any((player) => player.isAlive())){
      return;
    }

    onPlayersNotAlive();
  }


}