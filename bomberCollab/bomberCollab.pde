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
int MAX_BOMBS = 5;
int BOMBE_TIME = 4 * FRAME_RATE;
int BOMBE_TIME_RND = 1 * FRAME_RATE; // BOMBE_TIME +/- BOMBE_TIME_RND
boolean DISPLAY_BOMBE_COUNTER = true;

int MAP_SIZE = 19;
int EXPLODE_SIZE = 9;
int EXPLODE_TIME = round(0.3 * FRAME_RATE);
int DISCONNECT_TIMEOUT = 60 * FRAME_RATE;

int DEAD_TIME = 2 * FRAME_RATE;
int SPRITE_SIZE;
boolean constrastEleve = false; 

Renderer renderer = new Renderer();
boolean typeName = true;
String inputName = "";

boolean typeChat = false;
String inputChat = "";
ArrayList<String> chats = new ArrayList<String>();

int lastAction; //dernière action effectuée


String message = "Hello to BomberCollab.\n\nUse arrows to move,\nENTER to drop your bomb.\nType your name : ";

int speedMax = round(0.05 * FRAME_RATE); //vitesse de déplacement max : 50ms
int speedMin = round(0.8 * FRAME_RATE); //vitesse de déplacement min : 800ms

int deadZoneX; //centre de la zone 
int deadZoneY; //centre de la zone 
float bombZoneSize = 0.2; //coef taille zone bombe (clic: pose une bombe)
float deadZoneSize = 0.25; //coef taille zone morte (aucun effet)
//float manualZoneSize = 0.5; //coef taille zone manuelle (clic: deplacement)
float manualZoneSize = deadZoneSize; //deadZoneSize=desactivée
float autoZoneSize = 1; //coef taille zone auto (mouseOver: déplacement, speed fonction de la distance)

GameState gameState = new GameState();
Player mePlayer = new Player();
ArrayList<CpuPlayer> cpus = new ArrayList<CpuPlayer>();

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
  gameState.allPlayers.put(mePlayer.id, mePlayer);
  mePlayer.pushEvent = true; 
  createCpuPlayer();
}


void draw() {
  detectMouse();
  mePlayer.applyMove();
  for (CpuPlayer cpu : cpus) {
    cpu.computeMove();
    cpu.cpuPlayer.applyMove();
  }
  
  applyGameLogic();
  disconnectPlayers();

  renderer.initColors();
  renderer.drawBackground();
  renderer.drawMovePanel();

  renderer.drawMap();
  renderer.drawPlayers();
  renderer.drawBombs();
  renderer.drawMessage();
  renderer.drawScore();
  renderer.drawChat();
}


void applyGameLogic() {
  //dead message
  if (!mePlayer.alive && !typeName) {
    message = "Start in "+floor(mePlayer.deadWait/FRAME_RATE)+"s";
    if (!typeChat && mePlayer.deadWait-- <= 0) {
      mePlayer.resurect();
      message = "";
    }
  }

  for (Player player : gameState.allPlayers.values ()) {
    for (Bomb bomb : new ArrayList<Bomb> (player.bombs.values ())) { //new arrayList pour copier la liste et permettre les suppressions
      applyBombsLogic(bomb, player);
    }
  }
  //remove
}

void applyBombsLogic(Bomb bomb, Player player) {
  if (bomb.timeLeft > 0 && !bomb.explode) {
    bomb.timeLeft--;
  } else if (bomb.timeLeft == 0 && !bomb.explode) { //pas encore explosé
    bomb.timeLeft = EXPLODE_TIME;
    bomb.explode = true;
    if (player.pushEvent) {
      pushBombInfo(bomb);
    }
  } else if (bomb.timeLeft > 0 && bomb.explode) {
    explodePlayersAndBombs(bomb);
    bomb.timeLeft--;
  } else if (bomb.timeLeft == 0 && bomb.explode) { //fin explosion
    bomb.timeLeft = -1;
    player.bombs.remove(bomb.id);
  }
}

void explodePlayersAndBombs(Bomb bomb) {
  for (Player player : gameState.allPlayers.values ()) {
    explodeAPlayerAndBombs(player, bomb);
  }
}

void explodeAPlayerAndBombs(Player player, Bomb bomb) {
  if (player.alive && isInRange(player.x, player.y, bomb.x, bomb.y, bomb.explodeSize)) {
    player.alive = false;
    //player.killBy = bomb.playerId; //on garde le killBy pour ne compter le score qu'une fois.
    //if (player == mePlayer ||  player == cpu.cpuPlayer2) {
      player.killBy(bomb);
    //}
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

void createCpuPlayer() {
  CpuPlayer cpu = new CpuPlayer();
  gameState.allPlayers.put(cpu.cpuPlayer.id, cpu.cpuPlayer); 
  cpus.add(cpu);
}

void disconnectPlayers() {
  boolean isDisco = false;
  for (Player player : gameState.allPlayers.values ()) {
    if (player.disconnectIn > 0) {
      player.disconnectIn--;
    } else {
      isDisco = true;
    }
  }
  if (isDisco) {
    for (Player player : new ArrayList<Player> (gameState.allPlayers.values ())) {
      if (player.disconnectIn == 0) {
        gameState.allPlayers.remove(player.id);
      }
    }
  }
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
      mePlayer.resurect();
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
  } else if (key == 'c' || key == 'C') {
    noLoop();
    //createCpuPlayer();
  } else {
    //println(keyCode +" ("+RIGHT+","+DOWN+","+LEFT+","+UP+")");
    //println("dir:"+mePlayer.direction +" mePlayer.y%2:"+mePlayer.y%2+", mePlayer.x%2:"+mePlayer.x%2);
    if (keyCode == RIGHT || keyCode == DOWN || keyCode == LEFT || keyCode == UP || keyCode == ENTER) {
      loop();
	  mePlayer.nextAction = keyCode;
      mePlayer.inputSpeed = speedMax;
    }
  }
}

void detectMouse() {
  if (!typeName && !typeChat && mePlayer.nextAction != ENTER) {
    int nextAction = getInZoneDir(manualZoneSize, autoZoneSize);
    if (nextAction != -1) { //si dans la zone
      int dist;
      if (nextAction == LEFT || nextAction == RIGHT) {
        dist = round(abs(mouseX-deadZoneX) - manualZoneSize);
      } else {
        dist = round(abs(mouseY-deadZoneY) - manualZoneSize);
      }
      mePlayer.inputSpeed = round(speedMin + (speedMax-speedMin) * dist/(autoZoneSize-manualZoneSize));

      //println("dist:"+dist+"/("+autoZoneSize+"-"+manualZoneSize+")="+dist/(autoZoneSize-manualZoneSize)+" : currentSpeed:"+currentSpeed);     
      if (lastAction != nextAction) {
        mePlayer.inputSpeedWait=0;
      }
      mePlayer.nextAction = nextAction;
      lastAction = nextAction;
    }
  }
}

void mouseClicked() {
  if (!typeName && !typeChat) {
    //int bombAction = getInZoneDir(0, bombZoneSize);
    int manualAction = getInZoneDir(deadZoneSize, manualZoneSize);
    if (manualAction != -1 && mePlayer.nextAction == -1) {
      mePlayer.nextAction = manualAction;
    } else if (getInZoneDir(manualZoneSize, autoZoneSize)!=-1 && getInZoneDir(bombZoneSize, deadZoneSize) == -1) { //pas dans la zone grise
      mePlayer.nextAction = ENTER;
    }
    //println("manualAction:"+manualAction+", nextAction:"+mePlayer.nextAction);
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





