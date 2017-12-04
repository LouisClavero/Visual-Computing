class Cylinder{
  float posX;
  float posZ;
  float cylinderHeight = 150;
  int cylinderResolution = 40;
  PShape openCylinder = new PShape();
  PShape topSurface = new PShape();
  PShape bottomSurface = new PShape();
  
  Cylinder(float posX, float posZ) {
    this.posX = posX;
    this.posZ = posZ;
    
    float angle;
    float[] x = new float[cylinderResolution + 1];
    float[] y = new float[cylinderResolution + 1];
  
     //get the x and y position on a circle for all the sides
    for(int i = 0; i < x.length; i++) {
      angle = (TWO_PI / cylinderResolution) * i;
      x[i] = sin(angle) * cylinderBaseSize;
      y[i] = cos(angle) * cylinderBaseSize;
    }
    topSurface = createShape();
    topSurface.beginShape(TRIANGLE_FAN);
    topSurface.vertex(0, 0, cylinderHeight);
    for(int i = 0 ; i < x.length ; i++){
      topSurface.vertex(x[i], y[i], cylinderHeight);
    }
    topSurface.endShape();
  
    bottomSurface = createShape();
    bottomSurface.beginShape(TRIANGLE_FAN);
    bottomSurface.vertex(0, 0, 0);
    for(int i = 0 ; i < x.length ; i++){
      bottomSurface.vertex(x[i], y[i], 0);
    }
    bottomSurface.endShape();

    openCylinder = createShape();
    openCylinder.beginShape(QUAD_STRIP);
    //draw the border of the cylinder
    for(int i = 0; i < x.length; i++) {
      openCylinder.vertex(x[i], y[i] , 0);
      openCylinder.vertex(x[i], y[i], cylinderHeight);
    }
     openCylinder.endShape();
   }
   
   void display() {
     
     pushMatrix();
     rotateX(PI/2);
     translate(posX, posZ, 0);
     shape(openCylinder);
     shape(bottomSurface);
     shape(topSurface);
     popMatrix();
   }
   
   PVector getCenter() {
     return new PVector(posX, posZ);
   }
}