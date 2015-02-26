class GameState {
 
  HashMap<Integer, Player> allPlayers = new HashMap<Integer, Player>();

Player obtainPlayer(int id) {
  Player player = allPlayers.get(id);
  if (player == null) {
    player = new Player();
    player.id = id;
    player.name = "Player"+id;
    allPlayers.put(id, player);
  }
  return player;
}
  int[][] getCollisionsMap() {
    int[][] collisionsMap = new int[MAP_SIZE+2][MAP_SIZE+2]; //pour simplifier on entoure les collisions de bloc infranchissable
    for (int x = 0; x < MAP_SIZE+2; x++) {
      for (int y = 0; y < MAP_SIZE+2; y++) {
        collisionsMap[x][y] = ((x+1)%2==0 || (y+1)%2==0) // les blocs interrieurs
          && x!=0 && y!=0 && x!=(MAP_SIZE+1) && y!=(MAP_SIZE+1) // le cadre exterieur
            ? 0 : 1; // 0=libre, 1=occupé, 2=bomb
      }
    }
    for (Player player : allPlayers.values ()) {
      collisionsMap[player.x+1][player.y+1] = 1;
      for (Bomb bomb : player.bombs.values ()) {
        collisionsMap[bomb.x+1][bomb.y+1] = 2;
      }
    }
    return collisionsMap;
  }
}
