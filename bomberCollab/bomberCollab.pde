//Changes : 
// - gestion d'un timeout/disconnect pour les joueurs offline : Ok
// - gestion des scores : Ok
// - chat : Ok
// - ConstractElevee : C
// - Déplacements Souris simple, bombes = clic
// - Liste des touches
// - IA

String EVENT_GAME_INFO = "GAME";
String EVENT_PLAYER_INFO = "PLAYER";
String EVENT_BOMB = "BOMB";
String EVENT_CHAT = "CHAT";

int FRAME_RATE = 25;
int BOMBE_TIME = 5 * FRAME_RATE;
int BOMBE_TIME_RND = 0 * FRAME_RATE;
boolean DISPLAY_BOMBE_COUNTER = true;

int MAP_SIZE = 19;
int EXPLODE_SIZE = 9;
int EXPLODE_TIME = round(0.3 * FRAME_RATE);
int DISCONNECT_TIMEOUT = 60 * FRAME_RATE;

int DEAD_TIME = 2 * FRAME_RATE;
int deadWait = 0;
int SPRITE_SIZE;
boolean constrastEleve = false; 

Renderer renderer = new Renderer();
boolean typeName = true;
String inputName = "";

boolean typeChat = false;
String inputChat = "";
ArrayList<String> chats = new ArrayList<String>();

int selfAction = -1; // action a effectuer
int lastAction; //dernière action effectuée

Player mePlayer = new Player();
HashMap<Integer, Player> otherPlayers = new HashMap<Integer, Player>();
String message = "Hello to BomberCollab.\n\nUse arrows to move,\nENTER to drop your bomb.\nType your name : ";

int speedMax = round(0.05 * FRAME_RATE); //vitesse de déplacement max : 50ms
int speedMin = round(0.8 * FRAME_RATE); //vitesse de déplacement min : 800ms
int currentSpeed = speedMax; //vari en fonction de l'ecart de la souris pas rapport au centre de la zone
int deadZoneX; //centre de la zone 
int deadZoneY; //centre de la zone 
float bombZoneSize = 0.2; //coef taille zone bombe (clic: pose une bombe)
float deadZoneSize = 0.25; //coef taille zone morte (aucun effet)
//float manualZoneSize = 0.5; //coef taille zone manuelle (clic: deplacement)
float manualZoneSize = deadZoneSize; //deadZoneSize=desactivée
float autoZoneSize = 1; //coef taille zone auto (mouseOver: déplacement, speed fonction de la distance)

int speedWait = -1; // décompte d'attente


void setup() {
  size(1000, 800);
  background(255);  
  frameRate(FRAME_RATE); 
  SPRITE_SIZE = (height-1)/MAP_SIZE;
  int maxZoneSize = round((width-height)/2);
  deadZoneX = width-maxZoneSize;
  deadZoneY = height-maxZoneSize;
  bombZoneSize = round(maxZoneSize*bombZoneSize);
  deadZoneSize = round(maxZoneSize*deadZoneSize);
  manualZoneSize = round(maxZoneSize*manualZoneSize);
  autoZoneSize = round(maxZoneSize*autoZoneSize);
}

void startGame() {
  do { 
    mePlayer.x = floor(random(MAP_SIZE));
    mePlayer.y = floor(random(MAP_SIZE));
  } 
  while (mePlayer.x%2 == 1 && mePlayer.y%2 == 1);
  mePlayer.alive = true;
  pushPlayerInfo(mePlayer);
}

void draw() {
  renderer.initColors();
  renderer.drawBackground();

  renderer.drawMovePanel();
  
  detectMouse();
  applyMoves();
  applyGameLogic();
  disconnectPlayers();

  renderer.drawMap();
  renderer.drawPlayers();
  renderer.drawBombs();
  renderer.drawMessage();
  renderer.drawScore();
  renderer.drawChat();
}

void applyMoves() {
  if(speedWait>0) {
    speedWait--;
  }  
  if (mePlayer.alive && selfAction != -1 && speedWait<=0) {
    speedWait = currentSpeed;
    int[][] collisionsMap = getCollisionsMap();

    if (selfAction == RIGHT) {
      mePlayer.direction = 0;
      if (isFree(mePlayer.x+1, mePlayer.y, collisionsMap)) {
        mePlayer.x++;
      }
      pushPlayerInfo(mePlayer);
    } else if (selfAction == DOWN) {
      mePlayer.direction = 1;
      if (isFree(mePlayer.x, mePlayer.y+1, collisionsMap)) {
        mePlayer.y++;
      }
      pushPlayerInfo(mePlayer);
    } else if (selfAction == LEFT) {
      mePlayer.direction = 2;
      if (isFree(mePlayer.x-1, mePlayer.y, collisionsMap)) {
        mePlayer.x--;
      }
      pushPlayerInfo(mePlayer);
    } else if (selfAction == UP) {
      mePlayer.direction = 3;
      if (isFree(mePlayer.x, mePlayer.y-1, collisionsMap)) {
        mePlayer.y--;
      }
      pushPlayerInfo(mePlayer);
    } else if (selfAction == ENTER && mePlayer.bombs.size() < mePlayer.maxBomb ) {
      Bomb bomb = new Bomb();
      bomb.playerId = mePlayer.id;
      bomb.explodeSize = mePlayer.explodeSize;
      bomb.x = mePlayer.x;
      bomb.y = mePlayer.y;
      bomb.timeLeft = floor(BOMBE_TIME + (random(BOMBE_TIME_RND)-BOMBE_TIME_RND/2));
      mePlayer.bombs.put(bomb.id, bomb);
      pushBombInfo(bomb);
    }
    selfAction = -1;
  }
}


void applyGameLogic() {
  //dead message
  if (!mePlayer.alive && !typeName) {
    message = "Start in "+floor(deadWait/FRAME_RATE)+"s";
    if (!typeChat && deadWait-- <= 0) {
      startGame();
      message = "";
    }
  }

  for (Player other : otherPlayers.values ()) {
    for (Bomb bomb : new ArrayList<Bomb> (other.bombs.values ())) { //new arrayList pour copier la liste et permettre les suppressions
      applyBombsLogic(bomb, false);
    }
  }
  for (Bomb bomb : new ArrayList<Bomb> (mePlayer.bombs.values ())) {//new arrayList pour copier la liste et permettre les suppressions
    applyBombsLogic(bomb, true);
  }

  //remove
}

void applyBombsLogic(Bomb bomb, boolean isMePlayer) {
  if (bomb.timeLeft > 0 && !bomb.explode) {
    bomb.timeLeft--;
  } else if (bomb.timeLeft == 0 && !bomb.explode) { //pas encore explosé
    bomb.timeLeft = EXPLODE_TIME;
    bomb.explode = true;
    if (isMePlayer) {
      pushBombInfo(bomb);
    }
  } else if (bomb.timeLeft > 0 && bomb.explode) {
    explodePlayersAndBombs(bomb);
    bomb.timeLeft--;
  } else if (bomb.timeLeft == 0 && bomb.explode) { //fin explosion
    bomb.timeLeft = -1;
    if (isMePlayer && mePlayer.id == bomb.playerId) {
      mePlayer.bombs.remove(bomb.id);
    } else {
      Player other = otherPlayers.get(bomb.playerId);
      other.bombs.remove(bomb.id);
    }
  }
}

void explodePlayersAndBombs(Bomb bomb) {
  explodeAPlayerAndBombs(mePlayer, bomb, true);  
  for (Player player : otherPlayers.values ()) {
    explodeAPlayerAndBombs(player, bomb, false);
  }
}

void explodeAPlayerAndBombs(Player player, Bomb bomb, boolean isMePlayer) {
  if (player.alive && isInRange(player.x, player.y, bomb.x, bomb.y, bomb.explodeSize)) {
    player.alive = false;
    //player.killBy = bomb.playerId; //on garde le killBy pour ne compter le score qu'une fois.
    if (isMePlayer) {
      deadWait = DEAD_TIME;
      mePlayer.killBy = bomb.playerId; // killBy permet le score
      scored(bomb.playerId, player);
      pushPlayerInfo(mePlayer);
    }
    //scored(bomb.playerId, player);
  }
  for (Bomb otherBomb : player.bombs.values ()) {
    if (!otherBomb.explode && isInRange(otherBomb.x, otherBomb.y, bomb.x, bomb.y, bomb.explodeSize)) {
      otherBomb.timeLeft = 0; //le bomb.explode sera passé à true par applyBombsLogic plus tard
    }
  }
}

boolean isInRange(int x, int y, int bombX, int bombY, int size) {
  return (x%2==0 && x == bombX && abs(y - bombY) <= size)
    || (y%2==0 && y == bombY && abs(x - bombX) <= size);
}

void scored(int killerId, Player dead) {
  if (killerId == mePlayer.id) {
    dead.killBy = killerId;
    mePlayer.score += dead.id==mePlayer.id?-1:1;
    pushPlayerInfo(mePlayer);
  }
}

void disconnectPlayers() {
  boolean isDisco = false;
  for (Player player : otherPlayers.values ()) {
    if (player.disconnectIn > 0) {
      player.disconnectIn--;
    } else {
      isDisco = true;
    }
  }
  if (isDisco) {
    for (Player player : new ArrayList<Player> (otherPlayers.values ())) {
      if (player.disconnectIn == 0) {
        otherPlayers.remove(player.id);
      }
    }
  }
}

int[][] getCollisionsMap() {
  int[][] collisionsMap = new int[MAP_SIZE+2][MAP_SIZE+2]; //pour simplifier on entoure les collisions de bloc infranchissable
  for (int x = 0; x < MAP_SIZE+2; x++) {
    for (int y = 0; y < MAP_SIZE+2; y++) {
      collisionsMap[x][y] = ((x+1)%2==0 || (y+1)%2==0) // les blocs interrieurs
        && x!=0 && y!=0 && x!=(MAP_SIZE+1) && y!=(MAP_SIZE+1) // le cadre exterieur
          ? 0 : 1; // 0=libre, 1=occupé
    }
  }
  for (Bomb bomb : mePlayer.bombs.values ()) {
    collisionsMap[bomb.x+1][bomb.y+1] = 1;
  }
  for (Player other : otherPlayers.values ()) {
    collisionsMap[other.x+1][other.y+1] = 1;
    for (Bomb bomb : other.bombs.values ()) {
      collisionsMap[bomb.x+1][bomb.y+1] = 1;
    }
  }
  return collisionsMap;
}

boolean isFree(int x, int y, int[][] collisionsMap) {
  return collisionsMap[x+1][y+1] == 0;
}

void keyPressed() {
  if (keyCode == CONTROL) {
    constrastEleve = !constrastEleve;
  }
  if (typeName) {
    if (keyCode == ENTER && inputName .length() > 0) {
      message = "";
      typeName = false;
      mePlayer.name = inputName;
      startGame();
    } else if (inputName.length() > 0 && (keyCode == BACKSPACE || keyCode == DELETE)) {
      message = message.substring(0, message.length()-1);
      inputName = inputName.substring(0, inputName.length()-1);
    } else if (key >= ' ' && key <= '~') {
      message = message + str(key);
      inputName = inputName + str(key);
    }
  } else if (typeChat) {
    if (keyCode == ENTER && inputName .length() > 0) {
      message = "";
      typeChat = false;    
      pushChat();
    } else if (inputChat.length() > 0 && (keyCode == BACKSPACE || keyCode == DELETE)) {
      inputChat = inputChat.substring(0, inputChat.length()-1);
    } else if (key >= ' ' && key <= '~') {
      inputChat = inputChat + str(key);
    }
  } else if (key == 't' || key == 'T') {
    message = "\nCHAT MODE\npress ENTER to send";
    typeChat = true;
    inputChat = "";
  } else {
    //println(keyCode +" ("+RIGHT+","+DOWN+","+LEFT+","+UP+")");
    //println("dir:"+mePlayer.direction +" mePlayer.y%2:"+mePlayer.y%2+", mePlayer.x%2:"+mePlayer.x%2);
    if (keyCode == RIGHT || keyCode == DOWN || keyCode == LEFT || keyCode == UP || keyCode == ENTER) {
      selfAction = keyCode;
      currentSpeed = speedMax;
    }
  }
}

void detectMouse() {
  if (!typeName && !typeChat && selfAction != ENTER) {
    int nextAction = getInZoneDir(manualZoneSize, autoZoneSize);
    if (nextAction != -1) { //si dans la zone
      int dist;
      if (nextAction == LEFT || nextAction == RIGHT) {
        dist = round(abs(mouseX-deadZoneX) - manualZoneSize);
      } else {
        dist = round(abs(mouseY-deadZoneY) - manualZoneSize);
      }
      currentSpeed = round(speedMin + (speedMax-speedMin) * dist/(autoZoneSize-manualZoneSize));
      
      //println("dist:"+dist+"/("+autoZoneSize+"-"+manualZoneSize+")="+dist/(autoZoneSize-manualZoneSize)+" : currentSpeed:"+currentSpeed);     
    }
     if(lastAction != nextAction) {
        speedWait=0;
      }
      selfAction = nextAction;
      lastAction = nextAction;
  }
}

void mouseClicked() {
  if (!typeName && !typeChat) {
    //int bombAction = getInZoneDir(0, bombZoneSize);
    int manualAction = getInZoneDir(deadZoneSize, manualZoneSize);
    if (manualAction != -1 && selfAction == -1) {
      selfAction = manualAction;
    } else if (getInZoneDir(bombZoneSize, deadZoneSize) == -1) { //pas dans la zone grise
      selfAction = ENTER;
    }
    //println("manualAction:"+manualAction+", selfAction:"+selfAction);
  }
}

int getInZoneDir(float sizeMin, float sizeMax) {
  int dX = mouseX-deadZoneX;
  int dY = mouseY-deadZoneY;
  if ((abs(dX)>sizeMin || abs(dY)>sizeMin) && (abs(dX)<sizeMax && abs(dY)<sizeMax)) {
    //println("("+dX+","+dY+") sizeMin:"+sizeMin+", sizeMax:"+sizeMax);
    if (abs(dX)>abs(dY) && dX>0) {
      return RIGHT;
    } else if (abs(dX)>abs(dY) && dX<0) {
      return LEFT;
    } else if (abs(dY)>abs(dX) && dY>0) {
      return DOWN;
    } else if (abs(dY)>abs(dX) && dY<0) {
      return UP;
    }
  }
  return -1;
} 


//********* Events Handler ***************************
void pushPlayerInfo(Player player) {
  String[] event = {
    //id, name, alive, x, y, score, direction, killBy
    EVENT_PLAYER_INFO, str(player.id), player.name, str(player.alive), str(player.x), str(player.y), str(player.score), str(player.direction), str(player.killBy)
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

void receivePlayerInfo(int id, String name, boolean alive, int x, int y, int score, int direction, int killBy) {
  Player other = otherPlayers.get(id);
  if (other == null) {
    other = new Player();
    other.id = id;
    otherPlayers.put(other.id, other);
  }
  other.name = name;
  if (!alive && other.killBy == -1) {
    other.killBy = killBy;
    scored(killBy, other);
  } else if (!other.alive) { //resurect dead->live
    other.killBy = -1;
  }
  other.alive = alive;
  other.x = x;
  other.y = y;
  other.score = score;
  other.direction = direction;
  other.disconnectIn = DISCONNECT_TIMEOUT;
}

void receiveBombInfo(int id, int playerId, int explodeSize, int x, int y, int timeLeft, boolean explode) {
  Player other = otherPlayers.get(playerId);
  if (other == null) {
    other = new Player();
    other.id = playerId;
    other.name = "Player"+playerId;
    other.alive = true;
    other.explodeSize = explodeSize;
    other.x = x;
    other.y = y;
    otherPlayers.put(other.id, other);
  }
  Bomb bomb = other.bombs.get(id);
  if (bomb == null) {
    bomb = new Bomb();
    bomb.id = id;
    bomb.playerId = playerId;
    other.bombs.put(bomb.id, bomb);
  }
  bomb.explodeSize = explodeSize;
  bomb.x = x;
  bomb.y = y;
  bomb.timeLeft = timeLeft;
  bomb.explode = explode;
}

class Player {
  int id = int(random(65535));
  int maxBomb = 3;
  int explodeSize = EXPLODE_SIZE;

  boolean alive = true;
  String name = "Player"+id;
  int direction = 0; //0::E, 1:S, 2:W, 3:N
  int x = -1;
  int y = -1; 
  int score = 0;  
  int disconnectIn = DISCONNECT_TIMEOUT;
  int killBy = -1;  
  HashMap<Integer, Bomb> bombs = new HashMap<Integer, Bomb>();
}

class Bomb {
  int playerId = -1;
  int id = int(random(65535));
  int explodeSize = -1;
  int x = -1;
  int y = -1;
  int timeLeft = -1;
  boolean explode = false;
}

