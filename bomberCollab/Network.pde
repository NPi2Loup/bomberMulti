//********* Events Handler ***************************
void pushPlayerInfo(Player player) {
  String[] event = {
    //id, name, alive, x, y, score, direction, killBy
    EVENT_PLAYER_INFO, str(player.id), player.name, str(player.alive), str(player.x), str(player.y), str(player.score), str(player.direction), str(player.killById)
    };
    pushEvent(event);
}

void pushBombInfo(Bomb bomb) {
  String[] event = {
    //id, playerId, explodeSize, x, y, timeLeft, explode
    EVENT_BOMB, str(bomb.id), str(bomb.playerId), str(bomb.explodeSize), str(bomb.x), str(bomb.y), str(bomb.timeLeft), str(bomb.explode)
    };
    pushEvent(event);
}

void pushChat() {
  String[] event = {
    //playerId, message
    EVENT_CHAT, mePlayer.name, inputChat
  };
  inputChat = "";
  pushEvent(event);
  receiveEvent(event);
}


void receiveEvent(String[] event) {
  String eventType = event[0];
  if (eventType == EVENT_GAME_INFO) {
    //start, regles, ...
  } else if (eventType == EVENT_PLAYER_INFO) {
    //id, name, alive, x, y, score, direction, killBy
    receivePlayerInfo(int(event[1]), event[2], boolean(event[3]), int(event[4]), int(event[5]), int(event[6]), int(event[7]), int(event[8]));
  } else if (eventType == EVENT_BOMB) {
    //id, playerId, explodeSize, x, y, timeLeft, explode
    receiveBombInfo(int(event[1]), int(event[2]), int(event[3]), int(event[4]), int(event[5]), int(event[6]), boolean(event[7]));
  } else if (eventType == EVENT_CHAT) {
    //playerName, inputChat
    receiveChat(event[1], event[2]);
  }
}

void receiveChat(String playerName, String message) {
  chats.add(0, "["+playerName+"] "+message);
  if (chats.size() > 30) {
    chats.remove(chats.size()-1);
  }
}

void receivePlayerInfo(int id, String name, boolean alive, int x, int y, int score, int direction, int killById) {
  Player player = gameState.obtainPlayer(id);
  player.name = name;
  if (!alive && player.killById == -1) {
    player.killById = killById;
    Player killer = gameState.obtainPlayer(killById);
    killer.scored(player);
  } else if (!player.alive) { //resurect dead->live
    player.killById = -1;
  }
  player.alive = alive;
  player.x = x;
  player.y = y;
  player.score = score;
  player.direction = direction;
  player.disconnectIn = DISCONNECT_TIMEOUT;
}

void receiveBombInfo(int id, int playerId, int explodeSize, int x, int y, int timeLeft, boolean explode) {
  Player player = gameState.obtainPlayer(playerId);  
  Bomb bomb = player.bombs.get(id);
  if (bomb == null) {
    bomb = new Bomb();
    bomb.id = id;
    bomb.playerId = playerId;
    player.bombs.put(bomb.id, bomb);
  }
  bomb.explodeSize = explodeSize;
  bomb.x = x;
  bomb.y = y;
  bomb.timeLeft = timeLeft;
  bomb.explode = explode;
}

