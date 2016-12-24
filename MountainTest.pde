// Author: Anne Zou
// Email: anne.zou@vanderbilt.edu
// Last Edited: 12/23/16

import java.util.*;
import java.io.FileReader;

// global variables and constant

int score = 0;
int highScore = 0;
PrintWriter writer;
boolean GAME_OVER = false;
PImage gameOverImg;
PImage otherGameOverImg;
float stopTime = -1;
float stopTime2 = -1;
float otherGameOverImgX = 0;
float otherGameOverImgY = 0;

PImage blockImg;
float BLOCK_WIDTH = 150;
int TALLEST_INITIAL_HEIGHT = 4;
float RISING_SPEED = 2;
float SWIPE_SPEED = 100;
int NUM_COLUMNS = 5;

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
    yVel = -RISING_SPEED;
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
      list.add(new Block(x, height + BLOCK_WIDTH/2));
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
  for (Block block : looseBlocks) {
    if (block.getxPos() < 0 - BLOCK_WIDTH || block.getxPos() > width + BLOCK_WIDTH) {
      looseBlocks.remove(block);
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
    if (column.isEmpty() || column.lastElement().getyPos() <= height) {
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
  
  gameOverImg = loadImage("gameover.jpg");
  otherGameOverImg = loadImage("socialism.png");
  blockImg = loadImage("block.jpg");
  imageMode(CENTER);
 
  try {
    Scanner in = new Scanner("highScore.txt");
    highScore = in.nextInt();
    in.close();
  } catch (Exception e) {}
 
  for (int i = 0; i < NUM_COLUMNS; ++i) {
    vecOfColumns.add(i, new Column(width/2 + BLOCK_WIDTH*(i - floor(NUM_COLUMNS/2)) , rand.nextInt(TALLEST_INITIAL_HEIGHT) + 1));
  }
  for (Column column : vecOfColumns) {
    column.print();
  }
}


void draw() {
  
  // check if game is lost
  if (!gameIsOver()) {
    
    // check if a top block has been clicked
    if (mousePressed && !blockClicked) {
      float mouseXsnapshot = mouseX;
      float mouseYsnapshot = mouseY;
      float millisSnapshot = millis();
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
      if (abs(mouseXsnapshot - clickXcoord) > BLOCK_WIDTH/2 && millisSnapshot - clickTime < 1500) {
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
    
  } else { // game over
    
    if (stopTime2 < 0) {
      stopTime2 = millis();
    }
    if (stopTime2 > 0 && millis() - stopTime2 > 50) {
      otherGameOverImgX = (float)rand.nextDouble() * width;
      otherGameOverImgY = (float)rand.nextDouble() * height;
      stopTime2 = millis();
    }
    print();
    image(gameOverImg, width/2, height/2);
    image(otherGameOverImg, otherGameOverImgX, otherGameOverImgY, 50, 50);
    
  }
  
}