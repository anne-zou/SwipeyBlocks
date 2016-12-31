// Author: Anne Zou
// Email: anne.zou@vanderbilt.edu
// Last Edited: 12/29/16

import java.util.*;
import java.io.FileReader;

// global variables and constants

int score = 0;
int highScore = 0;
//PrintWriter writer;

PImage gameOverImg1;
PImage gameOverImg2;
float stopTime = -1;
float gameOverImg2X = 0;
float gameOverImg2Y = 0;

PImage blockImg;
float BLOCK_WIDTH = 200;
int TALLEST_INITIAL_HEIGHT = 7;
float risingSpeed = 3;
float SWIPE_SPEED = 100;
int NUM_COLUMNS = 3;

Vector<Column> vecOfColumns = new Vector<Column>(NUM_COLUMNS);
List<Block> looseBlocks = new LinkedList<Block>();

boolean blockClicked = false;
Column clickedColumn = null;
float clickXcoord;
float clickTime;

Random rand = new Random();

// classes

class Block {
  public Block(float init_x, float init_y) {
    xPos = init_x;
    yPos = init_y;
    xVel = 0;
    yVel = -risingSpeed;
  } 
  public float getxPos() {
    return xPos;
  }
  public float getyPos() {
    return yPos;
  }
  public void setxVel(float newxVel) {
    xVel = newxVel;
  }
  public void setyVel(float newyVel) {
    yVel = newyVel;
  }
  public void move() {
    xPos += xVel;
    yPos += yVel;
  }
  public void print() {
    image(blockImg, xPos, yPos, BLOCK_WIDTH, BLOCK_WIDTH);
  }
  public boolean contains(float xCoord, float yCoord) {
    if (abs(xPos - xCoord) <= BLOCK_WIDTH/2 && abs(yPos - yCoord) <= BLOCK_WIDTH/2) {
      return true;
    }
    return false;
  }
  private float xPos;
  private float yPos;
  private float xVel;
  private float yVel;
};


class Column {
  public Column(float init_x, int numBlocks) {
    x = init_x;
    list = new Vector<Block>(numBlocks);
    for (int i = 0; i < numBlocks; ++i){
      list.add(i, new Block(x, height + (i-numBlocks+.5) * BLOCK_WIDTH));
    }
  }
  public void move() {
    for (Block b : list) {
      b.move();
    }
  }
  public void print() {
    for (Block b : list) {
      b.print();
    }
  }
  public void setyVel(float newyVel) {
    for (Block b : list) {
      b.setyVel(newyVel);
    }
  }
  public boolean isEmpty() {
    return list.isEmpty();
  }
  public Block firstElement() {
    return list.firstElement();
  }
  public Block lastElement() {
    return list.lastElement();
  }
  public void add() {
    if (isEmpty()) {
      list.add(new Block(x, height + 1.5 * BLOCK_WIDTH));
    } else {
      list.add(new Block(x, lastElement().getyPos() + BLOCK_WIDTH));
    }
  }
  public boolean topBlockIsAt(float xCoord, float yCoord) {
    return firstElement().contains(xCoord, yCoord);
  }
  public void remove() {
    list.removeElementAt(0);
  }
  
  private float x;
  private Vector<Block> list;
};


// helper methods

boolean gameIsOver() {
  for (Column column : vecOfColumns) {
    if (column.firstElement().getyPos() < BLOCK_WIDTH/2) {
      stopTime = -1;
      return true;
    }
  }
  return false;
}

Column findColumnWhoseTopBlockIsAt(float x, float y) {
  for (Column column : vecOfColumns) {
    if (column.topBlockIsAt(x, y)){
      return column;
    }
  }
  return null;
}

void handleSwipe(float mouseXsnapshot, float clickXcoord){
  if (mouseXsnapshot > clickXcoord) {
    clickedColumn.firstElement().setxVel(SWIPE_SPEED);
  }
  if (mouseXsnapshot < clickXcoord) {
    clickedColumn.firstElement().setxVel(-SWIPE_SPEED);
  }
  clickedColumn.firstElement().setyVel(0);
      
  looseBlocks.add(clickedColumn.firstElement());
  clickedColumn.remove();
}

void updateScore() {
  Iterator<Block> iter = looseBlocks.iterator();
  Block block;
  while(iter.hasNext()) {
    block = iter.next();
    if (block.getxPos() < 0 - BLOCK_WIDTH || block.getxPos() > width + BLOCK_WIDTH) {
      iter.remove();
      ++score;
      if (score > highScore) {
        highScore = score;
      }
    }
  }
}

void move() {
  for (Column column : vecOfColumns) {
    column.move();
    if (column.lastElement().getyPos() <= height + BLOCK_WIDTH) {
      column.add();
    }
  }
  
  for (Block block : looseBlocks) {
    block.move();
  }
}

void print() {
  background(#74AFAD);
  for (Column column : vecOfColumns) {
    column.print();
  }
  for (Block block : looseBlocks) {
    block.print();
  }
  text(Integer.toString(score), 30, 60);
  //text("hi score: " + Integer.toString(highScore), width - 300, 60);
}

void setup() {
  fullScreen();
  fill(0);
  stroke(0);
  textSize(50);
  rectMode(CENTER);
  
  gameOverImg1 = loadImage("gameover.jpg");
  //gameOverImg2 = loadImage("socialism.png");
  blockImg = loadImage("block.jpg");
  imageMode(CENTER);
 
  try {
    Scanner in = new Scanner("highScore.txt");
    highScore = in.nextInt();
    in.close();
  } catch (Exception e) {}
 
  if (NUM_COLUMNS % 2 == 1)
  for (int i = 0; i < NUM_COLUMNS; ++i) {
    vecOfColumns.add(i, new Column(width/2 + BLOCK_WIDTH*(i - floor(NUM_COLUMNS/2)) , rand.nextInt(TALLEST_INITIAL_HEIGHT) + 2));
  }
  if (NUM_COLUMNS % 2 == 0)
  for (int i = 0; i < NUM_COLUMNS; ++i) {
    vecOfColumns.add(i, new Column(width/2 + BLOCK_WIDTH*(i - NUM_COLUMNS/2 + .5) , rand.nextInt(TALLEST_INITIAL_HEIGHT) + 2));
  }
  for (Column column : vecOfColumns) {
    column.print();
  }
}


void draw() {
  
  // check if game is lost
  if (!gameIsOver()) {
    
    // check if the mouse has been clicked
    if (mousePressed && !blockClicked) {
      float mouseXsnapshot = mouseX;
      float mouseYsnapshot = mouseY;
      float millisSnapshot = millis();
      // check if the clicked location is on a block at the top of a column
      clickedColumn = findColumnWhoseTopBlockIsAt(mouseXsnapshot, mouseYsnapshot);
      if (clickedColumn != null) {
        blockClicked = true;
        clickXcoord = mouseXsnapshot;
        clickTime = millisSnapshot;
      }
    }
    // check if a block has been released (swiped)
    if (!mousePressed && blockClicked) {    
      float mouseXsnapshot = mouseX;
      float millisSnapshot = millis();
      // check if swipe distance is right & swipe time is short enough
      if (abs(mouseXsnapshot - clickXcoord) > BLOCK_WIDTH/3 && millisSnapshot - clickTime < 1000) {
          handleSwipe(mouseXsnapshot, clickXcoord);
      }
      blockClicked = false;
      clickedColumn = null;
      clickXcoord = clickTime = 0;
    }
    
    // update score
    updateScore();
     
    // move mountain & loose blocks, add bottom layer
    move();
    
    // print
    print();
    
    // update risingSpeed
    if (stopTime < 0) {
      stopTime = millis();
    }
    if (stopTime > 0 && millis() - stopTime > 2000) {
      risingSpeed += .1;
      for (Column column : vecOfColumns) {
        column.setyVel(-risingSpeed);
      }
      stopTime = millis();
    }
    
  } else { // game over
    
  //  if (stopTime < 0) {
  //    stopTime = millis();
  //  }
  //  if (stopTime > 0 && millis() - stopTime > 50) {
  //    gameOverImg2X = (float)rand.nextDouble() * width;
  //    gameOverImg2Y = (float)rand.nextDouble() * height;
  //    stopTime = millis();
  //  }
    print();
    image(gameOverImg1, width/2, height/2);
    //image(gameOverImg2, gameOverImg2X, gameOverImg2Y, 50, 50);
    
  }

}