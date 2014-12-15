class Renderer {

  //PImage fullSpritesMap = loadImage("spritesMap.jpg");

  /*PImage bombe1 = loadImage("bombe1.gif");
  PImage bombe2 = loadImage("bombe2.gif");
  PImage bombe3 = loadImage("bombe3.gif");

  PImage bombermanN = loadImage("bombermanN.gif");
  PImage bombermanS = loadImage("bombermanS.gif");
  PImage bombermanE = loadImage("bombermanE.gif");
  PImage bombermanW = loadImage("bombermanW.gif");

  PImage exploC = loadImage("exploC.gif");
  PImage exploN = loadImage("exploN.gif");
  PImage exploS = loadImage("exploS.gif");
  PImage exploE = loadImage("exploE.gif");
  PImage exploW = loadImage("exploW.gif");
  PImage exploEndN = loadImage("exploEndN.gif");
  PImage exploEndS = loadImage("exploEndS.gif");
  PImage exploEndE = loadImage("exploEndE.gif");
  PImage exploEndW = loadImage("exploEndW.gif");*/
	
	color  backgroundColor = color(255);
	color  mapBorderColor = color(20);
	color  squareColor = color(170);
	color  squareLightColor = color(140);
	color  squareDarkColor = color(110);
	color  messageColor = color(20);
	color  titleColor = color(50);
	color  meTextColor = color(50, 50, 150);
	color  otherTextColor = color(150, 20, 20);
	color  meColor = color(50, 50, 220);
	color  otherColor = color(220, 20, 20);
	color  disconnectColor = color(100);
	color  borderPlayerColor = color(80);
	color  deadPlayerColor = color(40);
	color  borderBombColor = color(80);
	color  innerBombColor = color(20);
	color  textBombColor = color(200);
	color  borderFlamsColor = color(250, 200, 20);
	color  innerFlamsColor = color(250, 250, 20);
	
	void initColors() {
		if(constrastEleve) {
			backgroundColor = color(20);
			mapBorderColor = color(200);
			squareColor = color(100);
			squareLightColor = color(140);
			squareDarkColor = color(170);
			messageColor = color(200);
			titleColor = color(150);
			meTextColor = color(150, 150, 220);
			otherTextColor = color(220, 150, 150);
			meColor = color(150, 150, 220);
			otherColor = color(220, 150, 150);
			disconnectColor = color(100);
			borderPlayerColor = color(80);
			deadPlayerColor = color(20);
			borderBombColor = color(180);
			innerBombColor = color(20);
			textBombColor = color(200);
			borderFlamsColor = color(150, 100, 20);
			innerFlamsColor = color(150, 150, 20);
		} else {
			backgroundColor = color(255);
			mapBorderColor = color(20);
			squareColor = color(170);
			squareLightColor = color(140);
			squareDarkColor = color(110);
			messageColor = color(20);
			titleColor = color(50);
			meTextColor = color(50, 50, 150);
			otherTextColor = color(150, 20, 20);
			meColor = color(50, 50, 220);
			otherColor = color(220, 20, 20);
			disconnectColor = color(100);
			borderPlayerColor = color(80);
			deadPlayerColor = color(40);
			borderBombColor = color(80);
			innerBombColor = color(20);
			textBombColor = color(200);
			borderFlamsColor = color(250, 200, 20);
			innerFlamsColor = color(250, 250, 20);
		}
	}
	
	void drawBackground() {
 		background(backgroundColor);
 	}

  void drawMap() {
    noFill();
    stroke(mapBorderColor);
    strokeWeight(5);
    rect(0, 0, height-2, height-2);

    for (int i = 1; i < MAP_SIZE; i+=2) {
      for (int j = 1; j < MAP_SIZE; j+=2) {
        noStroke();
        fill(squareColor);
        rect(i*SPRITE_SIZE, j*SPRITE_SIZE, SPRITE_SIZE, SPRITE_SIZE);
        strokeWeight(5);
        stroke(squareLightColor);
        line(i*SPRITE_SIZE, j*SPRITE_SIZE, (i+1)*SPRITE_SIZE, j*SPRITE_SIZE);
        line(i*SPRITE_SIZE, j*SPRITE_SIZE, i*SPRITE_SIZE, (j+1)*SPRITE_SIZE);
        stroke(squareDarkColor);
        line(i*SPRITE_SIZE, (j+1)*SPRITE_SIZE, (i+1)*SPRITE_SIZE, (j+1)*SPRITE_SIZE);
        line((i+1)*SPRITE_SIZE, j*SPRITE_SIZE, (i+1)*SPRITE_SIZE, (j+1)*SPRITE_SIZE);
      }
    }

    /*stroke(120);
     strokeWeight(2);
     for(int i = 0; i < MAP_SIZE+1; i++) {
     line(0, i*SPRITE_SIZE, height, i*SPRITE_SIZE);
     } 
     for(int i = 0; i < MAP_SIZE+1; i++) {
     line(i*SPRITE_SIZE,0, i*SPRITE_SIZE, height);
     }*/
  }

  void drawMessage() {
    fill(messageColor);
    textSize(32);
    textAlign(CENTER, CENTER);
    textLeading(2*SPRITE_SIZE);
    text(message, SPRITE_SIZE*MAP_SIZE/2, 4*SPRITE_SIZE+SPRITE_SIZE/2);
  }
  
  void drawScore() {
    int i = 0;
    textAlign(LEFT, TOP);
    textSize(12);
    fill(titleColor);
    stroke(titleColor);
    text("Scores", height+10, 20-15);
    line(height+10, 20, width-10, 20);
    
    fill(meTextColor);
    text(mePlayer.name, height+10, 25 + i*15);
    text(mePlayer.score, height+120, 25 + i*15);
    i++;
    for (Player other : otherPlayers.values ()) {
      fill(otherTextColor);
      if(other.name!=null) {
        text(other.name, height+10, 25 + i*15);
      } else {
        text(other.id, height+10, 25 + i*15);
      }      
      text(other.score, height+120, 25 + i*15);
      i++;
    }
    textAlign(CENTER, CENTER);
  }
  
   void drawChat() {
    int i = 0;
    textAlign(LEFT, TOP);
    textSize(12);
    fill(titleColor);
    stroke(titleColor);
    text("Chat      <<press T>>", height+10, 245-15);
    line(height+10, 245, width-10, 245);
   
    fill(meTextColor);
    text("["+mePlayer.name+"] "+inputChat, height+10, 250 + i*15);
    i++;
    for (String chat : chats) {
      fill(otherTextColor);
      text(chat, height+10, 250 + i*15);
      i++;
    }
    textAlign(CENTER, CENTER);
  }

  void drawPlayers() {  
    for (Player other : otherPlayers.values ()) {
      fill(otherColor);
      if(other.disconnectIn<30*FRAME_RATE) {
        fill(disconnectColor);
      }
      drawAPlayer(other);
    }
    fill(meColor);
    drawAPlayer(mePlayer);
    noStroke();
    noFill();
  }

  void drawAPlayer(Player player) {
    stroke(borderPlayerColor);
    strokeWeight(2);
    int centerX = player.x*SPRITE_SIZE+SPRITE_SIZE/2;
    int centerY = player.y*SPRITE_SIZE+SPRITE_SIZE/2;
    ellipse(centerX, centerY, SPRITE_SIZE, SPRITE_SIZE);

    if (player.name != null) {
      textSize(10);
      text(player.name, centerX, centerY-SPRITE_SIZE/2-10);
    }
    if (!player.alive) {
      stroke(deadPlayerColor);
      line(centerX-SPRITE_SIZE*0.3, centerY, centerX-SPRITE_SIZE*0.1, centerY-SPRITE_SIZE*0.2);
      line(centerX-SPRITE_SIZE*0.3, centerY-SPRITE_SIZE*0.2, centerX-SPRITE_SIZE*0.1, centerY);
      line(centerX+SPRITE_SIZE*0.3, centerY, centerX+SPRITE_SIZE*0.1, centerY-SPRITE_SIZE*0.2);
      line(centerX+SPRITE_SIZE*0.3, centerY-SPRITE_SIZE*0.2, centerX+SPRITE_SIZE*0.1, centerY);
    }
  }

  void drawBombs() {
    for (Player other : otherPlayers.values ()) {
      for (Bomb bomb : other.bombs.values ()) {
        if (!bomb.explode) {
          drawABomb(bomb);
        } else {
          drawAExplosion(bomb);
        }
      }
    }
    for (Bomb bomb : mePlayer.bombs.values ()) {
      if (!bomb.explode) {
        drawABomb(bomb);
      } else {
        drawAExplosion(bomb);
      }
    }
    noStroke();
    noFill();
  }

  void drawABomb(Bomb bomb) {
    stroke(borderBombColor);
    strokeWeight(2);
    int centerX = bomb.x*SPRITE_SIZE+SPRITE_SIZE/2;
    int centerY = bomb.y*SPRITE_SIZE+SPRITE_SIZE/2;
    float timedCoef = bomb.timeLeft%(FRAME_RATE/2);
    fill(innerBombColor);
    ellipse(centerX, centerY, 
    SPRITE_SIZE*0.9-(12f/FRAME_RATE)*timedCoef, 
    SPRITE_SIZE*0.9-(12f/FRAME_RATE)*timedCoef);

    fill(textBombColor);
    textSize(18);
    text(floor(bomb.timeLeft/FRAME_RATE)+1, centerX, centerY); //affiche le decompte
  }

  void drawAExplosion(Bomb bomb) {
    float timedCoef = (1-0.8*float(bomb.timeLeft)/EXPLODE_TIME)*0.8;  
    stroke(borderFlamsColor);
    strokeWeight(4);
    fill(innerFlamsColor);
    rectMode(CENTER);
    if (bomb.x%2==0) {
      rect(bomb.x*SPRITE_SIZE+SPRITE_SIZE/2, bomb.y*SPRITE_SIZE+SPRITE_SIZE/2, SPRITE_SIZE*timedCoef, SPRITE_SIZE*(1+EXPLODE_SIZE*2), SPRITE_SIZE/3);
    }
    if (bomb.y%2==0) {
      rect(bomb.x*SPRITE_SIZE+SPRITE_SIZE/2, bomb.y*SPRITE_SIZE+SPRITE_SIZE/2, SPRITE_SIZE*(1+EXPLODE_SIZE*2), SPRITE_SIZE*timedCoef, SPRITE_SIZE/3);
    }
    rectMode(CORNER);
    ellipse(bomb.x*SPRITE_SIZE+SPRITE_SIZE/2, bomb.y*SPRITE_SIZE+SPRITE_SIZE/2, SPRITE_SIZE*timedCoef+10, SPRITE_SIZE*timedCoef+10);
  }
}

