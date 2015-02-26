class Player {
  boolean pushEvent = false;

  int id = int(random(65535));
  int maxBomb = MAX_BOMBS;
  int explodeSize = EXPLODE_SIZE;

  boolean alive = true;
  int deadWait = 0;

  String name = "Player"+id;
  int direction = 0; //0::E, 1:S, 2:W, 3:N
  int x = -1;
  int y = -1; 
  int score = 0;  
  int disconnectIn = DISCONNECT_TIMEOUT;
  int killById = -1;  
  HashMap<Integer, Bomb> bombs = new HashMap<Integer, Bomb>();

  int inputSpeed = speedMax; //vari en fonction de l'ecart de la souris pas rapport au centre de la zone
  int inputSpeedWait = -1; // décompte d'attente
  int nextAction = -1; // action a effectuer

  void resurect() {
    do { 
      x = floor(random(MAP_SIZE));
      y = floor(random(MAP_SIZE));
    } 
    while (x%2 == 1 && y%2 == 1);
    alive = true;
    if (pushEvent) {
      pushPlayerInfo(this);
    }
  }

  void killBy(Bomb bomb) {
    deadWait = DEAD_TIME;
    killById = bomb.playerId; // killBy permet le score
    if (pushEvent) {
      //on gère le score en local
      Player killer = gameState.obtainPlayer(killById);
      killer.scored(this);
      if(killer != this) {
        pushPlayerInfo(this); //diffuse le killById
      }      
    } 
  }

  void scored(Player dead) {
    score += dead.id == id ?-1:1;      
    if (pushEvent) {
      pushPlayerInfo(this);
    }
  }


  void applyMove() {
    if (inputSpeedWait>0) {
      inputSpeedWait--;
    }
    if (inputSpeedWait<=0) {
      inputSpeedWait = inputSpeed;
      doApplyMoves(nextAction);
      nextAction = -1;
    }
  } 

  void doApplyMoves(int action) {
    disconnectIn = DISCONNECT_TIMEOUT;   
    if (alive && action != -1 ) {
      int[][] collisionsMap = gameState.getCollisionsMap();
      if (action == RIGHT) {
        direction = 0;
        if (isFree(x+1, y, collisionsMap)) {
          x++;
        }
        if (pushEvent) {
          pushPlayerInfo(this);
        }
      } else if (action == DOWN) {
        direction = 1;
        if (isFree(x, y+1, collisionsMap)) {
          y++;
        }
        if (pushEvent) {
          pushPlayerInfo(this);
        }
      } else if (action == LEFT) {
        direction = 2;
        if (isFree(x-1, y, collisionsMap)) {
          x--;
        }
        if (pushEvent) {
          pushPlayerInfo(this);
        }
      } else if (action == UP) {
        direction = 3;
        if (isFree(x, y-1, collisionsMap)) {
          y--;
        }
        if (pushEvent) {
          pushPlayerInfo(this);
        }
      } else if (action == ENTER && bombs.size() < maxBomb ) {
        Bomb bomb = new Bomb();
        bomb.playerId = id;
        bomb.explodeSize = explodeSize;
        bomb.x = x;
        bomb.y = y;
        bomb.timeLeft = floor(BOMBE_TIME + (random(2*BOMBE_TIME_RND)-BOMBE_TIME_RND));
        bombs.put(bomb.id, bomb);
        if (pushEvent) {
          pushBombInfo(bomb);
        }
      }
    }
  }
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

