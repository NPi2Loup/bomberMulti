int cpuSpeed = round(1 * FRAME_RATE); //vitesse de déplacement max : 250ms
int MAX_DEEP = 2; 

 int computeBestMove(Player movedPlayer, Object[] players) {
 return computeBestMoveJS(movedPlayer, players, 0, "")[IDX_MOVE];
 }
   
 int[] computeBestMoveJS(Player movedPlayer, Object[] players, int deep, String previous) {
    
    int[][] collisionsMap = gameState.getCollisionsMap();
    if (collisionsMap[movedPlayer.x+1][movedPlayer.y+1] == 1) {
      collisionsMap[movedPlayer.x+1][movedPlayer.y+1] = 0; //on retire le joueur de la collision pour ne pas lui faire croire qu'il se bloque lui même
    }
    Player testMovePlayer = new Player();
    testMovePlayer.id = movedPlayer.id;
    testMovePlayer.alive = movedPlayer.alive;
    testMovePlayer.name = movedPlayer.name;


    int[] testMoves = {
      -1, RIGHT, LEFT, DOWN, UP, ENTER
    };
    testMoves = suffle(testMoves, 1, testMoves.length-1);
    int bestMove = -1;
    int bestScore = -10000;
    for (int move : testMoves) {
      testMovePlayer.x = movedPlayer.x;
      testMovePlayer.y = movedPlayer.y;
      if (move == ENTER) {
        testMovePlayer.bombs = new HashMap<Integer, Bomb>(movedPlayer.bombs);
      } else {
        testMovePlayer.bombs = movedPlayer.bombs;
      }
      if (simulateApplyMoves(testMovePlayer, move, collisionsMap)) {
        int score = evalMove(testMovePlayer, collisionsMap, players, deep, previous+", "+deep+":"+actionToString(move)); 

        if (score > bestScore) {
          bestMove = move;
          bestScore = score;
        }
      }
    }
    return new int[] {
      bestMove, bestScore
    };
  }

  String actionToString(int bestMove) {
    String bestMoveStr = "STAY";
    if (bestMove == RIGHT) {
      bestMoveStr = "RIGHT";
    } else if (bestMove == DOWN) {
      bestMoveStr = "DOWN";
    } else if (bestMove == LEFT) {
      bestMoveStr = "LEFT";
    } else if (bestMove == UP) {
      bestMoveStr = "UP";
    } else if (bestMove == ENTER) {
      bestMoveStr = "BOMB";
    }
    return bestMoveStr;
  }
  
  int[] suffle(int[] moves, int from, int to) {
    for (int i=to; i> (from+1); i--) {
      swap(moves, i-1, int(random(i-from)+from));
    }
    return moves;
  }
  void swap(int[] arr, int i, int j) {
    int tmp = arr[i];
    arr[i] = arr[j];
    arr[j] = tmp;
  }


  boolean simulateApplyMoves(Player player, int action, int[][] collisionsMap) {   
    if (!player.alive) {
      return false;
    }
    boolean doable = true;
    if (action == -1) {
      //rien
    } else if (action == RIGHT && isFree(player.x+1, player.y, collisionsMap)) {
      player.x++;
    } else if (action == DOWN && isFree(player.x, player.y+1, collisionsMap)) {
      player.y++;
    } else if (action == LEFT && isFree(player.x-1, player.y, collisionsMap)) {
      player.x--;
    } else if (action == UP && isFree(player.x, player.y-1, collisionsMap)) {
      player.y--;
    } else if (action == ENTER && player.bombs.size() < player.maxBomb && isFree(player.x, player.y, collisionsMap)) {
      Bomb bomb = new Bomb();
      bomb.playerId = player.id;
      bomb.explodeSize = player.explodeSize;
      bomb.x = player.x;
      bomb.y = player.y;
      bomb.timeLeft = BOMBE_TIME;
      player.bombs.put(bomb.id, bomb);
    } else {
      doable = false;
    }
    return doable;
  }


  int evalMove(Player movedPlayer, int[][] collisionsMap, Object[] players, int deep, String previous) {
    int score = evalMapState(movedPlayer, collisionsMap, deep*cpuSpeed, players);
    println(previous+" : "+score);
    if (deep < MAX_DEEP) {
      score += computeBestMove(movedPlayer, players, deep+1, previous)[IDX_SCORE];
    }
    return score;
  }


int evalMapState(Player movedPlayer, int[][] collisionsMap, int deltaTime, Object[] players) {
    int score = 0;

    //check if someone is blocked    
    HashMap<Integer, Integer> playersMobility = new HashMap<Integer, Integer>(); //the more blocked, the more score
    for (Object elem : players) {
      Player player = (Player) elem;
      if (player.x == -1) {
        continue;
      }
      if (player.id == movedPlayer.id) {
        player = movedPlayer;
      }
      if (player.alive && player.x !=-1) {
        //println("x:"+player.x+", y:"+player.y);
        boolean rightF = isFree(player.x+1, player.y, collisionsMap);
        boolean leftF = isFree(player.x-1, player.y, collisionsMap);
        boolean downF = isFree(player.x, player.y+1, collisionsMap);
        boolean upF = isFree(player.x, player.y-1, collisionsMap);
        int playerMobility = (rightF?0:1) + (leftF?0:1) + (downF?0:1) + (upF?0:1);
        playerMobility += ((!rightF && !leftF)?2:0) + ((!downF && !upF)?2:0);
        playerMobility += ((!rightF && !leftF && !downF && !upF)?10:0);
        playersMobility.put(player.id, playerMobility);
      } else {
        playersMobility.put(player.id, 0);
      }
    }

    //check if i was in bomb range //compute exploding time
    HashMap<Bomb, Integer> dangerousBombs = new HashMap<Bomb, Integer>();
    for (Player player : gameState.allPlayers.values ()) {
      if (player.x == -1) {
        continue;
      }
      if (player.id == movedPlayer.id) {
        player = movedPlayer;
      }
      for (Bomb bomb : player.bombs.values ()) {
        int bombScore = -1;
        if (!bomb.explode) {         
          if (bomb.timeLeft-deltaTime < 0 ) { //explose
            bombScore = 1200;
          } else if (bomb.timeLeft-deltaTime < 0.5*FRAME_RATE ) { //moins de 500ms
            bombScore = 800;
          } else if (bomb.timeLeft-deltaTime < 1*FRAME_RATE ) { //moins de 1s
            bombScore = 300;
          } else if (bomb.timeLeft-deltaTime < 2*FRAME_RATE ) { //moins de 2s
            bombScore = 200;
          } else if (bomb.timeLeft-deltaTime < 3*FRAME_RATE ) { //moins de 3s
            bombScore = 100;
          } else {// plus de 3s
            bombScore = 50;
          }
        } else if (bomb.timeLeft-deltaTime > 0) { //en cours d'explosion       
          bombScore = 1200;
        }
        if (bombScore >= 0) {
          dangerousBombs.put(bomb, bombScore);
        }
      }
    }
    for (Bomb firstBomb : dangerousBombs.keySet ()) {
      for (Bomb secondBomb : dangerousBombs.keySet ()) {
        if (secondBomb != firstBomb) {
          if (isInRange(firstBomb.x, firstBomb.y, secondBomb.x, secondBomb.y, firstBomb.explodeSize)) {
            dangerousBombs.put(secondBomb, max(dangerousBombs.get(firstBomb), dangerousBombs.get(secondBomb)));
          }
        }
      }
    }

    //score -= playersMobility.get(movedPlayer.id);
    //score -= movedPlayer.bombs.size();
    int[][] bombScoreMap = new int[MAP_SIZE+2][MAP_SIZE+2];
    for (Bomb bomb : dangerousBombs.keySet()) {
      int bombScore = dangerousBombs.get(bomb);
      bombScoreMap[bomb.x+1][bomb.y+1] = max(bombScoreMap[bomb.x+1][bomb.y+1], bombScore);
      if (bomb.y%2==0) {
        for (int i = 1; i < bomb.explodeSize; i++) {
          if (bomb.x+i < MAP_SIZE) {
            bombScoreMap[bomb.x+i+1][bomb.y+1] = max(bombScoreMap[bomb.x+i+1][bomb.y+1], bombScore-i);
          }
          if (bomb.x-i >= 0) {
            bombScoreMap[bomb.x-i+1][bomb.y+1] = max(bombScoreMap[bomb.x-i+1][bomb.y+1], bombScore-i);
          }
        }
      }
      if (bomb.x%2==0) {
        for (int i = 1; i < bomb.explodeSize; i++) {
          if (bomb.y+i < MAP_SIZE) {
            bombScoreMap[bomb.x+1][bomb.y+i+1] = max(bombScoreMap[bomb.x+1][bomb.y+i+1], bombScore-i);
          }
          if (bomb.y-i >= 0) {
            bombScoreMap[bomb.x+1][bomb.y-i+1] = max(bombScoreMap[bomb.x+1][bomb.y-i+1], bombScore-i);
          }
        }
      }
    }
    //
    for (Player player : gameState.allPlayers.values ()) {
      if (player.x == -1) {
        continue;
      }
      if (player.id == movedPlayer.id) {
        player = movedPlayer;
      } else {
        score -= abs(player.x - movedPlayer.x) + abs(player.y - movedPlayer.y);
      }
      //check if someone is in bomb range //+1 if mine bomes
      if(player.x >=0 ){
      int bombScore = bombScoreMap[player.x+1][player.y+1];
      bombScore += ceil(bombScoreMap[player.x+2][player.y+1]/20);
      bombScore += ceil(bombScoreMap[player.x][player.y+1]/20);
      bombScore += ceil(bombScoreMap[player.x+1][player.y+2]/20);
      bombScore += ceil(bombScoreMap[player.x+1][player.y]/20);
      
      bombScore *= playersMobility.get(movedPlayer.id); 
      
      if (player.id == movedPlayer.id) {
        score -= bombScore*0.9;       
      } else {
        score += bombScore * 1.1;
      }
    }
    }
    if(score < 0 ) {
     // printArray(bombScoreMap);
    }
    //println("score:"+score+", x:"+movedPlayer.x+", y:"+movedPlayer.y);
    return score;
  }
