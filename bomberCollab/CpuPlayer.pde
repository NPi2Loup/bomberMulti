int nbCpu = 0;

class CpuPlayer {
  
  int cpuSpeed = Math.round(0.1 * FRAME_RATE); //vitesse de déplacement max en s
  Player cpuPlayer;
  
	CpuPlayer() {
		cpuPlayer = new Player();
		cpuPlayer.inputSpeed = cpuSpeed;
		cpuPlayer.name = "Cpu"+(++nbCpu)+ " nv"+round(FRAME_RATE / cpuSpeed)+".2";
		cpuPlayer.pushEvent = true;
		cpuPlayer.resurect();
		//startWorker(cpuSpeed);
	}

  void startCpuGame() {
    cpuPlayer.resurect();
    cpuPlayer.inputSpeed = cpuSpeed;
  }

  void computeMove() {
    if (!cpuPlayer.alive) {
      if (cpuPlayer.deadWait-- <= 0) {
        cpuPlayer.resurect();
      }
    }  
    //if (cpuPlayer.inputSpeedWait==cpuPlayer.inputSpeed) {
    if (cpuPlayer.inputSpeedWait==1) {
	   //si inputSpeedWait == inputSpeed, on calcul le mouvement
		//println("=========================================");
		//HashMap<String, Integer> result = new HashMap<String, Integer>();
		computeBestMove(cpuPlayer, gameState.allPlayers.values().toArray());
		//cpuPlayer.doApplyMoves(bestMove);
		//println("move: "+actionToString(bestMove));
		//printArray(result);
		//cpuPlayer.inputSpeedWait = cpuPlayer.inputSpeed;
		//return bestMove;
	}
  }



  //----------------------------------

}

