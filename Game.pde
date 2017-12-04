float score = 0;
float lastScore = 0;
float scoreMax = 100;
float depth = 2000;
float valX;
float valZ;
float gravityConstant = 0.981;
PVector gravityForce = new PVector(0, 0, 0);
float tippingSpeed = 1;
Mover mover = new Mover();
float boxSize = 800;
float boxDepth = 40;
boolean pause = false;
float cylinderBaseSize = 50;
ArrayList<Cylinder> listCylinders = new ArrayList();
PGraphics mySurface;
PGraphics topView;
PGraphics scoreBoard;
PGraphics barchart;
PGraphics video;
HScrollbar hscroll;
ArrayList<Float> listScore = new ArrayList();
int counter = 0;
float nbRect = 0;
ImageProcessing imgpro;
Movie cam;


void settings() {
  size(800, 800, P3D);
}

void setup() {
  imgpro = new ImageProcessing();
  String args[] = {"Image processing window"};
  PApplet.runSketch(args, imgpro);
  noStroke();
  hscroll = new HScrollbar(width/30 + height/3 + width/40, 4*height/5 + height/7 + height/45, width - height/3 - 3* width/60 - width/40, height/50);
  mySurface = createGraphics(width, height/5, P2D);
  topView = createGraphics(height/6, height/6, P2D);
  scoreBoard = createGraphics(height/6, height/6, P2D);
  barchart = createGraphics(width - height/3 - 3* width/60 - width/40, height/7, P2D);
  video = createGraphics(4*width/5, 4*height/5, P2D);
  pushMatrix();
  translate(width/2, height/2);
  valX = width/2;
  valZ = height/2;
  popMatrix();
}


void draw() {
  background(255);

  drawMySurface();
  image(mySurface, 0, 4*height/5);
  
  drawVideo();
  if(imgpro.cam!=null){
    image(imgpro.cam, 4.5*width/6, 0, 1.5*width/6, height/5);
  }
  drawTopView();
  image(topView, width/60, height/60 + 4*height/5); 

  drawScoreBoard();
  image(scoreBoard, width/30 + height/6, height/60 + 4*height/5);

  drawBarchart();
  image(barchart, width/30 + height/3 + width/40, height/60 + 4*height/5);

  hscroll.update();
  hscroll.display();
  //println(hscroll.getPos());

  pushMatrix();
  if (keyPressed == true) {
    if (keyCode == UP) {
      depth -= 50;
    } else if (keyCode == DOWN) {
      depth += 50;
    }
  }
  camera(width/2, height/2, depth, 400, 400, 0, 0, 1, 0);
  directionalLight(50, 100, 125, 0, 1, 0);
  ambientLight(102, 102, 102);  

  translate(width/2, height/2);

  if (valX < 0) {
    valX = 0;
  } else if (valX > width) {
    valX = width;
  }
  if (valZ < 0) {
    valZ = 0;
  } else if (valZ > height) {
    valZ = height;
  }
  
  PVector rot = imgpro.graph.rot;
  float rx = rot.x;
  float rz = rot.z;
  //float rx = map(valX, 0, width, -PI/3, PI/3);
  //float rz = map(valZ, 0, height, -PI/3, PI/3);
  gravityForce.x = sin(rz) * gravityConstant;
  gravityForce.z = -sin(rx) * gravityConstant;
  float normalForce = 1;
  float mu = 0.1;
  float frictionMagnitude = normalForce * mu;
  PVector friction = mover.velocity.copy();
  friction.mult(-1);
  friction.normalize();
  friction.mult(frictionMagnitude);


  pushMatrix();
  if (!(keyPressed == true && keyCode == SHIFT)) {
    rotateX(rx);
    rotateZ(rz);
    pause = false;
  } else {
    rotateX(-PI/2);
    pause = true;
  }
  fill(255);
  box(boxSize, boxDepth, boxSize);
  if (!pause) {
    mover.velocity.add(gravityForce);
    mover.velocity.add(friction);
    mover.update();
    mover.checkEdges();
  }
  mover.checkCylinderCollision();
  fill(255, 0, 0);
  mover.display();

  fill(153, 255, 153);

  for (Cylinder c : listCylinders) {                
    c.display();
  }

  popMatrix();
  popMatrix();
}



void mouseDragged() {
  if (mouseY <= 4*height/5) {
    valX += (pmouseY - mouseY)*tippingSpeed;
    valZ += (mouseX - pmouseX)*tippingSpeed;
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if (e < 0) {
    tippingSpeed += 0.1;
  } else if (e > 0) {
    tippingSpeed -= 0.1;
  }
  if (tippingSpeed < 0.2) {
    tippingSpeed = 0.2;
  } else if (tippingSpeed > 1.5) {
    tippingSpeed = 1.5;
  }
  println(tippingSpeed);
}

void mouseClicked() {
  if (keyPressed  && keyCode == SHIFT) {
    float x = map(mouseX, 260, 540, -boxSize/2, boxSize/2);
    float y  = map(mouseY, 260, 540, -boxSize/2, boxSize/2);
    if (!((mouseX < 260 || mouseX > 540 || (mouseY < 260) || mouseY > 540))) {
      Cylinder c = new Cylinder(x, y);
      if (distinctCylinders(c)) {
        listCylinders.add(c);
      }
    }
  }
}

boolean distinctCylinders(Cylinder c) {
  for (int i = 0; i < listCylinders.size(); i++) {
    if (listCylinders.get(i).getCenter().dist(c.getCenter()) < 2*cylinderBaseSize) {
      return false;
    }
  }
  return c.getCenter().dist(new PVector(mover.location.x, mover.location.z)) > (mover.radius + cylinderBaseSize/2);
}

void drawVideo(){
  video.beginDraw();
  video.stroke(0);
  video.strokeWeight(1);
  video.rect(0, 0, 4.5*width/5, 4*height/5);
  video.endDraw();
}

void drawMySurface() {
  mySurface.beginDraw();
  mySurface.stroke(0);
  mySurface.strokeWeight(4);
  mySurface.rect(0, 0, width, height/5);
  mySurface.fill(255, 204, 153);

  mySurface.endDraw();
}

void drawTopView() {
  topView.beginDraw();
  topView.rect(0, 0, height/6, height/6);
  float scale = (height/6) / boxSize;
  topView.fill(0);
  for (Cylinder c : listCylinders) {
    topView.ellipse(c.posX * scale + height/12, c.posZ * scale + height/12, cylinderBaseSize*2 * scale, cylinderBaseSize*2 * scale);
  }
  topView.stroke(0);
  topView.strokeWeight(2);
  topView.fill(250);
  topView.ellipse(mover.location.x * scale +height/12, mover.location.z * scale + height/12, 2*mover.radius * scale, 2*mover.radius * scale);
  topView.stroke(0);
  topView.strokeWeight(4);
  topView.fill(0, 120, 190);
  topView.endDraw();
}

void drawScoreBoard() {
  scoreBoard.beginDraw();
  scoreBoard.stroke(0);
  scoreBoard.strokeWeight(4);
  scoreBoard.rect(0, 0, height/6, height/6);
  scoreBoard.fill(0);
  scoreBoard.textSize(height/60);

  scoreBoard.text("Total Score : ", height/60, height/60, height/6 - height/60, height/6 - height/60);
  scoreBoard.text(Float.toString(score), height/60, height/30, height/6 - height/60, height/6 - height/60);
  scoreBoard.text("Velocity : ", height/60, 4*height/60, height/6 - height/60, height/6 - height/60);
  scoreBoard.text(Float.toString(mover.velocity.mag()), height/60, height/12, height/6 - height/60, height/6 - height/60);
  scoreBoard.text("Last Score : ", height/60, 7*height/60, height/6 - height/60, height/6 - height/60);
  scoreBoard.text(Float.toString(lastScore), height/60, 8*height/60, height/6 - height/60, height/6 - height/60);

  scoreBoard.fill(250);
  scoreBoard.endDraw();
}

void drawBarchart() {
  barchart.beginDraw();
  barchart.stroke(0);
  barchart.strokeWeight(4);
  barchart.fill(250);
  barchart.rect(0, 0, width - height/3 - 3* width/60 - width/40, height/7);
  float WEDGE = 1;
  float SMALL_RECT_SIZE = height/140;
  float NB_RECT_MAX_X = (width - height/3 - 3* width/60 - width/40)/(WEDGE + SMALL_RECT_SIZE);
  float NB_RECT_MAX_Y = (height/7)/(WEDGE + SMALL_RECT_SIZE);

  if (!pause) {
    if (counter++ < 10) {
      if (score > 0) {
        listScore.add(score);
      } else {
        listScore.add(0.0);
      }
      if (nbRect >= NB_RECT_MAX_Y) {
        scoreMax *= 1.5;
      }
    }
    counter = 0;
  }
  int minX = max(0, (int) (listScore.size() - NB_RECT_MAX_X/(2*hscroll.getPos())));
  float scorePerRect = scoreMax / NB_RECT_MAX_Y;
  boolean scoreTooLow = true;
  boolean scoreTooHigh = false;
  float x = 0;
  for (int i = max(0, minX); i < listScore.size(); i++) {
    x += SMALL_RECT_SIZE + WEDGE;
    float currentScore = listScore.get(i);
    if (currentScore > scoreMax/2) {
      scoreTooLow = false;
    } else if (currentScore > scoreMax) {
      scoreTooHigh = true;
    }
    nbRect = currentScore/scorePerRect;
    for (int j = 0; j < nbRect; j++) {
      barchart.noStroke();
      barchart.fill(255, 0, 0);
      barchart.rect(2*x*hscroll.getPos(), height/7 - (j+1)*(SMALL_RECT_SIZE+WEDGE) - WEDGE, SMALL_RECT_SIZE*2*hscroll.getPos(), SMALL_RECT_SIZE);
    }
  }
  if (scoreTooLow && scoreMax > 100) scoreMax /= 1.5;
  if (scoreTooHigh) scoreMax *= 1.5;

  barchart.endDraw();
}