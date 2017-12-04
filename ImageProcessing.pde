import processing.video.*;
import java.util.Collections;

class ImageProcessing extends PApplet {
  Movie cam;
  PImage img;
  PImage houghAccumulator;
  PImage sobelImage;
  PImage convolutedImage;
  ArrayList<PVector> vectors = new ArrayList<PVector>();
  float threshold = 128;
  HScrollbar thresholdBar;
  HScrollbar hueUpperBound;
  HScrollbar hueLowerBound;
  float lower;
  float upper;
  ArrayList<Integer> bestCandidates = new ArrayList<Integer>();
  QuadGraph graph = new QuadGraph();
  TwoDThreeD proj = new TwoDThreeD(640, 480);
  PImage  result = createImage(640, 480, RGB);
  float IMG_SIZE = 640 * 480;

  void settings() {
    size(640, 480);
  }
 
  
  void setup() {

    cam = new Movie(this, "C:\\Users\\Louis\\Desktop\\Work\\EPFL\\Archived\\Computer Vision\\Game\\data\\testvideo.mp4");
    cam.loop();
    proj = new TwoDThreeD(640, 480);
    result = createImage(640, 480, RGB);
    IMG_SIZE = 640 * 480;

  }

  void draw() {


    cam.read();
    if (pause) {
      cam.pause();
    } else { 
      cam.play();
      cam.loadPixels();
      img = cam.get();
      result.loadPixels();
      colorThreshold(img, 100, 138);
      result.updatePixels();
      binaryThreshold(result, 38, 137);
      saturationThreshold(result, 100, 263);
      image(result, 0, 0);

      convolutedImage = convolute(result);
      sobelImage = sobel(convolutedImage);
      hough(sobelImage, 6);
      graph.build(vectors, 640, 480);
      graph.findCycles();
      graph.displayQuads(vectors);
    }
  }  



  void saturationThreshold(PImage img, float lower, float upper) {
    loadPixels();
    if (lower > upper) {
      float temp = lower;
      lower = upper;
      upper = temp;
    }
    for (int i = 0; i < IMG_SIZE; i++) {
      if (saturation(img.pixels[i]) >= lower && saturation(img.pixels[i]) <= upper) {
        result.pixels[i] = color(255);
      } else {
        result.pixels[i] = color(0);
      }
    }

    updatePixels();
  }
  void binaryThreshold(PImage img, float lower, float upper) {
    loadPixels();
    if (lower > upper) {
      float temp = lower;
      lower = upper;
      upper = temp;
    }
    for (int i = 0; i < IMG_SIZE; i++) {
      if (brightness(img.pixels[i]) >= lower && brightness(img.pixels[i]) <= upper) {
        result.pixels[i] = color(img.pixels[i]);
      } else {
        result.pixels[i] = color(0);
      }
    }

    updatePixels();
  }

  void invertBinaryThreshold(PImage img, float thresh) {
    loadPixels();
    for (int i = 0; i < IMG_SIZE; i++) {
      if (brightness(img.pixels[i]) <= thresh) {
        result.pixels[i] = color(255);
      } else {
        result.pixels[i] = color(0);
      }
    }
    updatePixels();
  }

  void hueMap(PImage img) {
    loadPixels();
    for (int i = 0; i < IMG_SIZE; i++) {
      result.pixels[i] = color(hue(img.pixels[i]));
    }
    updatePixels();
  }

  void colorThreshold(PImage img, float lower, float upper) {

    for (int i = 1; i < IMG_SIZE; i++) {
      if (hue(img.pixels[i]) >= lower && hue(img.pixels[i]) <= upper) {
        result.pixels[i] = color(img.pixels[i]);
      } else {
        result.pixels[i] = color(0);
      }
    }
  }

  PImage convolute(PImage img) {
    float[][] kernel = { { 9, 12, 9 }, 
      { 12, 15, 12 }, 
      { 9, 12, 9 }     };
    float weight = 99.f;
    // create a greyscale image (type: ALPHA) for output
    PImage result = createImage(img.width, img.height, ALPHA);
    // kernel size N = 3
    //
    // for each (x,y) pixel in the image:
    // - multiply intensities for pixels in the range
    // (x - N/2, y - N/2) to (x + N/2, y + N/2) by the
    // corresponding weights in the kernel matrix
    // - sum all these intensities and divide it by the weight
    // - set result.pixels[y * img.width + x] to this value
    for (int i = 0; i < IMG_SIZE; i++) {
      result.pixels[i] = color(0);
    }



    for (int i = 1; i < img.width -1; i++) {
      for (int j = 1; j < img.height-1; j++) {
        float sum = 0;
        for (int k = i-1; k <= i+1; k++) {
          for (int l = j-1; l <= j+1; l++) {
            sum += brightness(img.pixels[l * img.width + k]) * kernel[k-i+1][l-j+1];
          }
        }

        result.pixels[j * img.width + i] = color(sum/weight);
      }
    }
    return result;
  }

  PImage sobel(PImage img) {
    float[][] hKernel = { { 0, 1, 0 }, 
      { 0, 0, 0 }, 
      { 0, -1, 0 } };
    float[][] vKernel = { { 0, 0, 0 }, 
      { 1, 0, -1 }, 
      { 0, 0, 0 } };
    PImage result = createImage(img.width, img.height, ALPHA);
    // clear the image
    for (int i = 0; i < IMG_SIZE; i++) {
      result.pixels[i] = color(0);
    }
    float max=0;
    float[] buffer = new float[(int) IMG_SIZE];
    // *************************************
    // Implement here the double convolution
    // *************************************
    float weight = 1.f;

    for (int i = 1; i < img.width -1; i++) {
      for (int j = 1; j < img.height-1; j++) {
        float sum_h = 0;
        float sum_v = 0;
        float sum = 0;
        for (int k = i-1; k <= i+1; k++) {
          for (int l = j-1; l <= j+1; l++) {
            sum_h += brightness(img.pixels[l * img.width + k]) * hKernel[k-i+1][l-j+1];
            sum_v += brightness(img.pixels[l * img.width + k]) * vKernel[k-i+1][l-j+1];
          }
        }
        sum = sqrt(pow(sum_h, 2) + pow(sum_v, 2));
        if (sum > max) {
          max = sum;
        }
        buffer[j * img.width + i] = sum;
      }
    }

    for (int y = 2; y < img.height - 2; y++) { // Skip top and bottom edges
      for (int x = 2; x < img.width - 2; x++) { // Skip left and right
        if (buffer[y * img.width + x] > (int)(max * 0.3f)) { // 30% of the max
          result.pixels[y * img.width + x] = color(255);
        } else {
          result.pixels[y * img.width + x] = color(0);
        }
      }
    }
    return result;
  }

  ArrayList<PVector> hough(PImage edgeImg, int nLines) {
    vectors = new ArrayList<PVector>();
    float discretizationStepsPhi = 0.06f;
    float discretizationStepsR = 2.5f;

    // dimensions of the accumulator
    int phiDim = (int) (Math.PI / discretizationStepsPhi);
    int rDim = (int) (((edgeImg.width + edgeImg.height) * 2 + 1) / discretizationStepsR);

    // our accumulator (with a 1 pix margin around)
    int[] accumulator = new int[(phiDim + 2) * (rDim + 2)];

    // pre-compute the sin and cos values
    float[] tabSin = new float[phiDim];
    float[] tabCos = new float[phiDim];
    float ang = 0;
    float inverseR = 1.f / discretizationStepsR;
    for (int accPhi = 0; accPhi < phiDim; ang += discretizationStepsPhi, accPhi++) {
      // we can also pre-multiply by (1/discretizationStepsR) since we need it in the Hough loop
      tabSin[accPhi] = (float) (Math.sin(ang) * inverseR);
      tabCos[accPhi] = (float) (Math.cos(ang) * inverseR);
    }

    // Fill the accumulator: on edge points (ie, white pixels of the edge
    // image), store all possible (r, phi) pairs describing lines going
    // through the point.
    for (int y = 0; y < edgeImg.height; y++) {
      for (int x = 0; x < edgeImg.width; x++) {
        // Are we on an edge?
        if (brightness(edgeImg.pixels[y * edgeImg.width + x]) != 0) {

          // ...determine here all the lines (r, phi) passing through
          // pixel (x,y), convert (r,phi) to coordinates in the
          // accumulator, and increment accordingly the accumulator.
          // Be careful: r may be negative, so you may want to center onto
          // the accumulator with something like: r += (rDim - 1) / 2

          for (float p = 0; p < phiDim; p++) {
            float r = x * tabCos[(int) (p)] + y * tabSin[(int)(p)];
            r = r/discretizationStepsR + (rDim - 1)/2; 
            int index  = round((p+1)*(rDim+2) + r+1);
            accumulator[index] += 1;
          }
        }
      }
    }

    houghAccumulator = createImage(rDim + 2, phiDim + 2, ALPHA);
    for (int i = 0; i < accumulator.length; i++) {
      houghAccumulator.pixels[i] = color(min(255, accumulator[i]));
    }
    // You may want to resize the accumulator to make it easier to see:
    houghAccumulator.resize(400, 600);
    houghAccumulator.updatePixels();

    bestCandidates = new ArrayList<Integer>();;
    // size of the region we search for a local maximum
    int neighbourhood = 30;
    // only search around lines with more that this amount of votes
    // (to be adapted to your image)
    int minVotes = 200;
    for (int accR = 0; accR < rDim; accR++) {
      for (int accPhi = 0; accPhi < phiDim; accPhi++) {
        // compute current index in the accumulator
        int idx = (accPhi + 1) * (rDim + 2) + accR + 1;
        if (accumulator[idx] > minVotes) {
          boolean bestCandidate=true;
          // iterate over the neighbourhood
          for (int dPhi=-neighbourhood/2; dPhi < neighbourhood/2+1; dPhi++) {
            // check we are not outside the image
            if ( accPhi+dPhi < 0 || accPhi+dPhi >= phiDim) continue;
            for (int dR=-neighbourhood/2; dR < neighbourhood/2 +1; dR++) {
              // check we are not outside the image
              if (accR+dR < 0 || accR+dR >= rDim) continue;
              int neighbourIdx = (accPhi + dPhi + 1) * (rDim + 2) + accR + dR + 1;
              if (accumulator[idx] < accumulator[neighbourIdx]) {
                // the current idx is not a local maximum!
                bestCandidate=false;
                break;
              }
            }
            if (!bestCandidate) break;
          }
          if (bestCandidate) {
            // the current idx *is* a local maximum
            bestCandidates.add(idx);
          }
        }
      }
    }


    Collections.sort(bestCandidates, new HoughComparator(accumulator));

    for (int i = 0; i < nLines && i < bestCandidates.size(); i++) {
      int idx = bestCandidates.get(i);

      // first, compute back the (r, phi) polar coordinates:
      int accPhi = (int) (idx / (rDim + 2)) - 1;
      int accR = idx - (accPhi + 1) * (rDim + 2) - 1;
      float r = (accR - (rDim - 1) * 0.5f) * discretizationStepsR;
      float phi = accPhi * discretizationStepsPhi;

      // Cartesian equation of a line: y = ax + b
      // in polar, y = (-cos(phi)/sin(phi))x + (r/sin(phi))
      // => y = 0 : x = r / cos(phi)
      // => x = 0 : y = r / sin(phi)
      // compute the intersection of this line with the 4 borders of
      // the image

      /*  int x0 = 0;
       int y0 = (int) (r / sin(phi));
       int x1 = (int) (r / cos(phi));
       int y1 = 0;
       int x2 = edgeImg.width;
       int y2 = (int) (-cos(phi) / sin(phi) * x2 + r / sin(phi));
       int y3 = edgeImg.width;
       int x3 = (int) (-(y3 - r / sin(phi)) * (sin(phi) / cos(phi)));
       */
      /*
    // Finally, plot the lines
       stroke(204, 102, 0);
       if (y0 > 0) {
       if (x1 > 0)
       line(x0, y0, x1, y1);
       else if (y2 > 0)
       line(x0, y0, x2, y2);
       else
       line(x0, y0, x3, y3);
       } else {
       if (x1 > 0) {
       if (y2 > 0)
       line(x1, y1, x2, y2);
       else
       line(x1, y1, x3, y3);
       } else
       line(x2, y2, x3, y3);
       }*/
      vectors.add(new PVector(r, phi));
    }
    return vectors;
  }
  ArrayList<PVector> getIntersections(ArrayList<PVector> lines) {
    ArrayList<PVector> intersections = new ArrayList<PVector>();
    for (int i = 0; i < lines.size() - 1; i++) {
      PVector line1 = lines.get(i);
      float cos1 = cos(line1.y);
      float sin1 = sin(line1.y);

      for (int j = i + 1; j < lines.size(); j++) {
        PVector line2 = lines.get(j);

        float cos2 = cos(line2.y);
        float sin2 = sin(line2.y);
        // compute the intersection and add it to ’intersections’
        float d = cos2 * sin1 - cos1 * sin2;
        float x = (line2.x*sin1 - line1.x * sin2)/d;
        float y = (-line2.x*cos1 + line1.x*cos2)/d;
        intersections.add(new PVector(x, y));

        // draw the intersection
        fill(255, 128, 0);
        ellipse(x, y, 10, 10);
      }
    }
    return intersections;
  }
}