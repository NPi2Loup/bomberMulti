  FRAME_RATE = 25; 
  MAP_SIZE = 19;
  BOMBE_TIME = 4 * FRAME_RATE;
  RIGHT = 39;
  LEFT = 37; 
  DOWN = 40; 
  UP = 38; 
  ENTER = 10;
  MAX_DEEP = 4;
  KEY_RANGE = 6;
  STATE_HISTORY = BOMBE_TIME/2;
  USE_WORKER = false;
  USE_LEARNING = false;
  nbMessg = 0;
  nbMoves = 0;
  knownBase = {};
  stateHistory = [];
  
  var prevMapStateKey;
  var myWorker;
  var isWaiting = false;
  function startWorker(inputSpeed) {
		if(USE_WORKER) {
			myWorker = new Worker("cpuPlayerCalcWorker.js");
		}
		console.log('Worker started');
  }
  
  function computeBestMove(movedPlayer, allPlayers) {
		if(!isWaiting) {
			var jsMovedPlayer = pdePlayerToJs(movedPlayer);
			var jsAllPlayers = [];
			for (var idx in allPlayers) {
				jsAllPlayers.push(pdePlayerToJs(allPlayers[idx]));
			}
			if(USE_WORKER) {
				myWorker.postMessage([jsMovedPlayer,jsAllPlayers, nbMessg++]);
				isWaiting = true;
				//console.log('Message posted to worker :'+nbMessg);		
				
				myWorker.onmessage = function(e) {
					movedPlayer.nextAction = e.data[0];
					//console.log('Message received from worker: '+e.data[1]);
					isWaiting = false;
				}
			} else {
				movedPlayer.nextAction = innerComputeBestMove(jsMovedPlayer, jsAllPlayers);				
			}
		}
  }
  

  
  function innerComputeBestMove(jsMovedPlayer, jsAllPlayers) {
		try {
			//convert to JS object
			var startTime = performance.now();
			//console.log("==================================================");
			nbMoves = 0;
			var bestMove = computeBestMoveJS(jsMovedPlayer, jsAllPlayers, 0, "");
			if(USE_LEARNING) {
				applyLearning(jsMovedPlayer, jsAllPlayers);
				stateHistory.unshift(bestMove); //add first
				if(stateHistory.length > STATE_HISTORY) {
					stateHistory.pop(); //remove last
				}
			}		
			console.log("Best : "+bestMove.bestMoveChaine+" score:"+bestMove.bestScore + " in "+(performance.now()-startTime)+"ms ("+nbMoves+" checked, knowed:" +Object.keys(knownBase).length+")");
			
			return bestMove.bestMove;
		} catch(err) {
			console.log(err);
			return -1;
		}
  }
  
  var moveCount = 0;
  
  function applyLearning(movedPlayer, allPlayers) {
  	var learnScore = 0;
  	var msg = "";
  	if(!movedPlayer.alive && movedPlayer.killById != -1) {
  			  //neg score
  			  msg = "Bien joué";
  			  learnScore -= 100;
  			  movedPlayer.killById = -1;
  	}
  	for (var idx in allPlayers) {
			if(!allPlayers[idx].alive && allPlayers[idx].killById == movedPlayer.id) {
					//plus score
					msg = "Ahah, je t'ai eu.";
					learnScore += 50;
					allPlayers[idx].killById = -1;
			}
		}
		if(moveCount++>STATE_HISTORY) {
			//pas très efficace, on change
			msg = "J'apprend";
			learnScore -= 25;
		}
		
		if(learnScore != 0) {
			moveCount = 0;
			var impact = 2;
			for (var idx in stateHistory) {
				var previousMove = stateHistory[idx];
				var knowPrevious = knownBase[previousMove.mapStateKey][previousMove.bestMove];
				if(!knowPrevious) {
					knowPrevious = { 
						"score" : previousMove.bestScore,
						"learn":0
						};
					knownBase[previousMove.mapStateKey][previousMove.bestMove] = knowPrevious;
				}
				knowPrevious.learn += learnScore*impact;
				impact -= 2/STATE_HISTORY;
			}
			var event = [ "CHAT", movedPlayer.name, msg ];
  		//pushEvent(event);
  		//Processing.getInstanceById('sketch').receiveEvent(event);
		}
  }
  
  function pdePlayerToJs(player) {
	var jsPlayer = {
		id : player.id,
		inputSpeed : player.inputSpeed,
		maxBomb : player.maxBomb,
		explodeSize : player.explodeSize,
		alive : player.alive,
		deadWait : player.deadWait,
		killById : player.killById,
		name : player.name,
		x : player.x,
		y : player.y,
		bombs : [] //player.bombs.values().toArray()		
	}
	var pdeBombs = player.bombs.values().toArray();
	for (var idx2 in pdeBombs) {
		var bomb = pdeBombs[idx2];
        jsPlayer.bombs.push(bomb);
    }
	return jsPlayer;
  }
  
  function getCollisionsMap(movedPlayer, allPlayers) {
    var collisionsMap = []; //pour simplifier on entoure les collisions de bloc infranchissable
    for (var x = 0; x < MAP_SIZE+2; x++) {
		collisionsMap[x] = [];
      for (var y = 0; y < MAP_SIZE+2; y++) {
        collisionsMap[x][y] = ((x+1)%2==0 || (y+1)%2==0) // les blocs interrieurs
          && x!=0 && y!=0 && x!=(MAP_SIZE+1) && y!=(MAP_SIZE+1) // le cadre exterieur
            ? 0 : 1; // 0=libre, 1=block, 2=joueur, 3=bomb
      }
    }
    for (var idx in allPlayers) {
	  var player = allPlayers[idx];
	  if (player.id == movedPlayer.id) {
        player = movedPlayer;
      }
      collisionsMap[player.x+1][player.y+1] = 2;
      for (var idx2 in player.bombs) {
		var bomb = player.bombs[idx2];
        collisionsMap[bomb.x+1][bomb.y+1] = 3;
      }
    }
    return collisionsMap;
  }
  
  function computeBestMoveJS(movedPlayer, players, deep, previous) {
    var bestMove = -1;
    var bestMoveChaine = previous;
    var bestScore = -10000; 
    
    var collisionsMap = getCollisionsMap(movedPlayer, players);
		var dangerousBombs = computeDanderousBombs(movedPlayer, deep*movedPlayer.inputSpeed, players);
  	var bombScoreMap = computeBombScoreMap(dangerousBombs);    
		var mapStateKey = USE_LEARNING?computeMapStateKey(movedPlayer, collisionsMap, bombScoreMap):false;
		var knowMove = USE_LEARNING?knownBase[mapStateKey]:false;
		
		var testMoves = [
	      -1, RIGHT, LEFT, DOWN, UP, ENTER
	    ];
	  testMoves = suffle(testMoves, 1, testMoves.length-1);
	    
		if(knowMove) {
			for (var idx in testMoves) {
	    	var move = testMoves[idx];
				knowMoveScore = knowMove[move];
				if(knowMoveScore) {
					deepScore = knowMoveScore.score + knowMoveScore.learn;
					if (deepScore > bestScore) {
			      bestMove = move;
			      bestScore = deepScore;
					  bestMoveChaine = previous+", "+deep+":LEARN";
	        }
	      }
			}
		} else {
	    var testMovePlayer = {
				id : movedPlayer.id,
		    alive : movedPlayer.alive,
				name : movedPlayer.name,
				maxBomb : movedPlayer.maxBomb,
				explodeSize : movedPlayer.explodeSize,
				inputSpeed : movedPlayer.inputSpeed,
			}
	
	    
	    var testedKnowMove = {};
	    for (var idx in testMoves) {
	    	var move = testMoves[idx];
		    testMovePlayer.x = movedPlayer.x;
		    testMovePlayer.y = movedPlayer.y;
		    testMovePlayer.bombs = movedPlayer.bombs;
	    
	      if (simulateApplyMoves(testMovePlayer, move, collisionsMap, movedPlayer)) {
	      	var moveScore = evalMove(testMovePlayer, collisionsMap, players, deep, previous+", "+deep+":"+ actionToString(move)); 
	        if(deep == 0) {
						testedKnowMove[move] = {
								"score" : moveScore.deepScore,
								"learn" : 0
							};
					}
					if (moveScore.deepScore > bestScore) {
			      bestMove = move;
			      bestScore = moveScore.deepScore;
					  bestMoveChaine = moveScore.moveChaine;
	        }
	        rollbackMoves(testMovePlayer, move, collisionsMap, movedPlayer);
	      }
	    }
	    if(deep == 0 && USE_LEARNING) {
	    	knownBase[mapStateKey] = testedKnowMove;
	  	}
	  }
    return {
      "bestMove" : bestMove,
	    "bestMoveChaine" : bestMoveChaine,
	    "bestScore": bestScore,
	    "mapStateKey" : mapStateKey
    };
  }

  function actionToString(bestMove) {
    var bestMoveStr = "STAY";
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
  
  function suffle(moves, from,  to) {
    for (var i=to; i> (from+1); i--) {
      swap(moves, i-1, Math.floor(Math.random()*(i-from)+from));
    }
    return moves;
  }
  function swap(arr, i, j) {
    var tmp = arr[i];
    arr[i] = arr[j];
    arr[j] = tmp;
  }


  function rollbackMoves(player, action, collisionsMap, originPlayer) {
  	   
  	if (action == -1) {
      //rien
    } else if (action == RIGHT) {
      collisionsMap[player.x+1][player.y+1] = 0;      
    } else if (action == DOWN) {
      collisionsMap[player.x+1][player.y+1] = 0;  
    } else if (action == LEFT) {
      collisionsMap[player.x+1][player.y+1] = 0;  
    } else if (action == UP) {
      collisionsMap[player.x+1][player.y+1] = 0;  
    } else if (action == ENTER) {
      collisionsMap[player.x+1][player.y+1] = 2;  
    }
    player.x = originPlayer.x;
    player.y = originPlayer.y;
    player.bombs = originPlayer.bombs;
    if(collisionsMap[player.x+1][player.y+1] == 0) {
      	collisionsMap[player.x+1][player.y+1] = 2;
    }
  }

  function simulateApplyMoves( player,  action,  collisionsMap, originPlayer) {   
    if (!player.alive) {
      return false;
    }
	//console.log((action == ENTER)+" && "+player.bombs.length +" < "+ player.maxBomb +" && "+ isFree(player.x, player.y, collisionsMap));
    var doable = true;
    if (action == -1) {
      //rien
    } else if (action == RIGHT && isFree(player.x+1, player.y, collisionsMap)) {
      if(collisionsMap[player.x+1][player.y+1] == 2) {
      	collisionsMap[player.x+1][player.y+1] = 0;
    	}
      player.x++;
      collisionsMap[player.x+1][player.y+1] = 2; 
    } else if (action == DOWN && isFree(player.x, player.y+1, collisionsMap)) {
      if(collisionsMap[player.x+1][player.y+1] == 2) {
      	collisionsMap[player.x+1][player.y+1] = 0;
    	}player.y++;
    	collisionsMap[player.x+1][player.y+1] = 2; 
    } else if (action == LEFT && isFree(player.x-1, player.y, collisionsMap)) {
      if(collisionsMap[player.x+1][player.y+1] == 2) {
      	collisionsMap[player.x+1][player.y+1] = 0;
    	}player.x--;
    	collisionsMap[player.x+1][player.y+1] = 2; 
    } else if (action == UP && isFree(player.x, player.y-1, collisionsMap)) {
      if(collisionsMap[player.x+1][player.y+1] == 2) {
      	collisionsMap[player.x+1][player.y+1] = 0;
    	}player.y--;
    	collisionsMap[player.x+1][player.y+1] = 2; 
    } else if (action == ENTER && player.bombs.length < player.maxBomb && collisionsMap[player.x+1][player.y+1] != 3) {
      
	  var bomb = {
		  id : Math.random()*65535+100000,
		  playerId : player.id,
		  explodeSize : player.explodeSize,
		  x : player.x,
		  y : player.y,
		  timeLeft : BOMBE_TIME
      }
      player.bombs = originPlayer.bombs.slice()
	  	player.bombs.push(bomb);
	  	collisionsMap[player.x+1][player.y+1] = 3;  
    } else {
      doable = false;
    }    
    return doable;
  }

function evalMove(movedPlayer, collisionsMap, allPlayers,  deep, previous) {
  var moveChaine = previous;	
	var dangerousBombs = computeDanderousBombs(movedPlayer, deep*movedPlayer.inputSpeed, allPlayers);
  var bombScoreMap = computeBombScoreMap(dangerousBombs);
	var deepScore;
	
	var deepScore = evalMapState(movedPlayer, collisionsMap, bombScoreMap, allPlayers);
		if (deep < MAX_DEEP) {
				var subMove = computeBestMoveJS(movedPlayer, allPlayers, deep+1, previous);
				deepScore += subMove.bestScore;
				moveChaine = subMove.bestMoveChaine;
				//console.log(previous+" : "+deepScore + " -> best:"+actionToString(subMove.bestMove)+" : "+subMove.bestScore);
		} else {
				//console.log(previous+" : "+deepScore);
		}
		//console.log(previous+" : "+deepScore);
		return {
			  "moveChaine" : moveChaine,
			  "deepScore": deepScore
			};
  }

function evalMapState(movedPlayer, collisionsMap, bombScoreMap, allPlayers) {
    //check if i was in bomb range //compute exploding time
   
	//check if someone is blocked 
    var playersMobility = computePlayersMobility(movedPlayer, collisionsMap, allPlayers); //the more blocked, the more score
    	
    
    var score = 0;
	//score -= playersMobility.get(movedPlayer.id);
    //score -= movedPlayer.bombs.size();
  
    //
    for (playerIdx in allPlayers) {
	  var player = allPlayers[playerIdx];
      if (player.x == -1) {
        continue;
      }
      if (player.id == movedPlayer.id) {
        player = movedPlayer;
      } else {
        score -= Math.abs(player.x - movedPlayer.x) + Math.abs(player.y - movedPlayer.y);
      }
      //check if someone is in bomb range //+1 if mine bomes
      if(player.x >=0 ){
	      var bombScore = bombScoreMap[player.x+1][player.y+1];
		  //console.log(bombScore);
	      bombScore += Math.ceil(bombScoreMap[player.x+2][player.y+1]/30); //right
	      bombScore += Math.ceil(bombScoreMap[player.x][player.y+1]/30); //left
	      bombScore += Math.ceil(bombScoreMap[player.x+1][player.y+2]/30); //down
	      bombScore += Math.ceil(bombScoreMap[player.x+1][player.y]/30); //up
	      //bombScore *= playersMobility[player.id]; 
	      if(bombScore > 50) {
	      	bombScore *= playersMobility[player.id]; 
	      }
		  
	      if (player.id == movedPlayer.id) {
	        score -= bombScore;
	      } else {
	        score += bombScore;
	      }
	    }
    }
    nbMoves++;
    return score;
  }
 
function computePlayersMobility(movedPlayer, collisionsMap, allPlayers) {
	var playersMobility = {}; //the more blocked, the more score
    for (playerIdx in allPlayers) {
	  var player = allPlayers[playerIdx];
	  if (player.id == movedPlayer.id) {
        player = movedPlayer;
      }
      if (player.alive && player.x !=-1) {
        //println("x:"+player.x+", y:"+player.y);
        var rightF = collisionsMap[player.x+1+1][player.y+1];//isFree(player.x+1, player.y, collisionsMap);
        var leftF = collisionsMap[player.x+1-1][player.y+1];//isFree(player.x-1, player.y, collisionsMap);
        var downF = collisionsMap[player.x+1][player.y+1+1];//isFree(player.x, player.y+1, collisionsMap);
        var upF = collisionsMap[player.x+1][player.y+1-1];//isFree(player.x, player.y-1, collisionsMap);
		var playerMobility = 0.8 + (rightF/10) + (leftF/10) + (downF/10) + (upF/10);
		//playerMobility += ((!rightF && !leftF)?0.25:0) + ((!downF && !upF)?0.25:0);
        playerMobility += ((rightF!=0 && leftF!=0 && downF!=0 && upF!=0)?1:0);
        playersMobility[player.id] = playerMobility;
      } else {
        playersMobility[player.id] = 0;
      }
    }
    return playersMobility;
}
 
 
function computeDanderousBombs(movedPlayer, deltaTime, allPlayers) {
	var dangerousBombs = {};
    for (playerIdx in allPlayers) {
	  var player = allPlayers[playerIdx];
      if (player.x == -1) {
        continue;
      }
      if (player.id == movedPlayer.id) {
        player = movedPlayer;
      }
      for (bombId in player.bombs) {
	  var bomb = player.bombs[bombId];
        var bombScore = -1;
        if (!bomb.explode) {         
          if (bomb.timeLeft-deltaTime < 0 ) { //explose
            bombScore = 1200;
          } else if (bomb.timeLeft-deltaTime < 0.5*FRAME_RATE ) { //moins de 500ms
            bombScore = 800;
          } else if (bomb.timeLeft-deltaTime < 1*FRAME_RATE ) { //moins de 1s
            bombScore = 100;
          } else if (bomb.timeLeft-deltaTime < 2*FRAME_RATE ) { //moins de 2s
            bombScore = 75;
          } else if (bomb.timeLeft-deltaTime < 3*FRAME_RATE ) { //moins de 3s
            bombScore = 50;
          } else {// plus de 3s
            bombScore = 25;
          }
        } else if (bomb.timeLeft-deltaTime > 0) { //en cours d'explosion       
          bombScore = 1200;
        } else {
			//console.log("Bombe a finie d'exploser : "+bomb.explode+" timeLeft:"+bomb.timeLeft+" delta:"+deltaTime);
		}
        if (bombScore >= 0) {
          dangerousBombs[playerIdx*10+bombId] = {
			  bomb:bomb, 
			  bombScore:bombScore
		  };
        }
      }
    }
    for (firstBombId in dangerousBombs) {
		var firstBomb = dangerousBombs[firstBombId].bomb;
      for (secondBombId in dangerousBombs) {		  
        if (firstBombId != secondBombId) {
			var secondBomb = dangerousBombs[secondBombId].bomb;
          if (isInRange(firstBomb.x, firstBomb.y, secondBomb.x, secondBomb.y, firstBomb.explodeSize)) {
            dangerousBombs[firstBombId].bombScore = Math.max(dangerousBombs[firstBombId].bombScore, dangerousBombs[secondBombId].bombScore);
          }
        }
      }
    }
    return dangerousBombs;
}


function computeBombScoreMap(dangerousBombs) {
	var bombScoreMap = [];// = new int[MAP_SIZE+2][MAP_SIZE+2];
	for(var i =0;i<MAP_SIZE+2; i++) {
		bombScoreMap[i] = [];
		for(var j =0;j<MAP_SIZE+2; j++) {
			bombScoreMap[i][j] = 0;
		}
	}
    for (bombId in dangerousBombs) {
      var dangerousBomb = dangerousBombs[bombId];
	  var bomb = dangerousBomb.bomb;
	  var bombScore = dangerousBomb.bombScore;
      bombScoreMap[bomb.x+1][bomb.y+1] = Math.max(bombScoreMap[bomb.x+1][bomb.y+1]*1.1, bombScore);
      if (bomb.y%2==0) {
        for (var i = 1; i < bomb.explodeSize; i++) {
          if (bomb.x+i < MAP_SIZE) {
            bombScoreMap[bomb.x+i+1][bomb.y+1] = Math.max(bombScoreMap[bomb.x+i+1][bomb.y+1], bombScore-2*i);
          }
          if (bomb.x-i >= 0) {
            bombScoreMap[bomb.x-i+1][bomb.y+1] = Math.max(bombScoreMap[bomb.x-i+1][bomb.y+1], bombScore-2*i);
          }
        }
      }
      if (bomb.x%2==0) {
        for (var i = 1; i < bomb.explodeSize; i++) {
          if (bomb.y+i < MAP_SIZE) {
            bombScoreMap[bomb.x+1][bomb.y+i+1] = Math.max(bombScoreMap[bomb.x+1][bomb.y+i+1], bombScore-2*i);
          }
          if (bomb.y-i >= 0) {
            bombScoreMap[bomb.x+1][bomb.y-i+1] = Math.max(bombScoreMap[bomb.x+1][bomb.y-i+1], bombScore-2*i);
          }
        }
      }
    }
	return bombScoreMap;
}

function computeMapStateKey(movedPlayer, collisionsMap, bombScoreMap) {
	var mapKey = "";
	var it = 0;
	for (var y = movedPlayer.y-KEY_RANGE; y < movedPlayer.y+KEY_RANGE; y++) {
      key = 0;
	  for (var x = movedPlayer.x-KEY_RANGE; x < movedPlayer.x+KEY_RANGE; x++) {
			key = key << 4;
			//1&2 bits : free=0, block=1, player=2, bomb=3
		if(x<-1 || y<-1 || x >= collisionsMap.length-1 || y >= collisionsMap.length-1) {
			key += 0x1;
			continue;
		}
		key += collisionsMap[x+1][y+1];
		//3&4 bits : danger : rien=0, posÃ©=1, <2s=2, <1s=3
		var danger = bombScoreMap[x+1][y+1];
		if(danger >= 1000) {
			key+=0xC;
		} else if(danger >= 500) {
			key+=0x8;
		} else if(danger >= 15) {
			key+=0x4;
		}
		if(++it%8 == 0) {
			mapKey += key.toString(16);
			key = 0;
	  }
	}
	  mapKey += key.toString(16);
	  mapKey += "-";
    }
	return mapKey;
}

function isFree(x, y, collisionsMap) {
  return collisionsMap[x+1][y+1] == 0;
}

function isInRange( x,  y,  bombX,  bombY,  size) {
  return (x%2==0 && x == bombX && Math.abs(y - bombY) <= size)
    || (y%2==0 && y == bombY && Math.abs(x - bombX) <= size);
}

function printCollision(collisionsMap) {
var asString = "";
  for (var y = 0; y < collisionsMap[0].length; y++) {
      for (var x = 0; x < collisionsMap.length; x++) {
		asString += collisionsMap[x][y];
	  }
	  console.log(asString);
	  toString = "";
    }    
}

/*function maxDangerousBomb(firstDangerousBomb, secondDangerousBomb) {
	if(firstDangerousBomb && !secondDangerousBomb) {
		return firstDangerousBomb;
	} else if(!firstDangerousBomb && secondDangerousBomb) {
		return firstDangersecondDangerousBombousBomb;
	} else {
		if(firstDangerousBomb.bombScore >= secondDangerousBomb.bombScore) {
		return firstDangerousBomb;
		} 
		return secondDangerousBomb;
	}
}*/