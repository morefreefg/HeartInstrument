/*
 *  THIS PROGRAM WORKS WITH PulseSensor STC12C5A60S2 CODE
 *  THE PULSE DATA WINDOW IS SCALEABLE WITH SCROLLBAR AT BOTTOM OF SCREEN
 *  PRESS 'S' OR 's' KEY TO SAVE A PICTURE OF THE SCREEN IN SKETCH FOLDER (.jpg)
 *  MADE BY Bwelco, 17/04/2015
*/

import processing.net.*; 
import java.net.*; 

PFont font;
Scrollbar scaleBar;

Client myClient; 
String dataIn;



int Sensor;      // HOLDS PULSE SENSOR DATA FROM ARDUINO
int IBI;         // HOLDS TIME BETWEN HEARTBEATS FROM ARDUINO
int BPM;         // HOLDS HEART RATE VALUE FROM ARDUINO   /////////////////////HEART RATE
int[] RawY;      // HOLDS HEARTBEAT WAVEFORM DATA BEFORE SCALING
int[] ScaledY;   // USED TO POSITION SCALED HEARTBEAT WAVEFORM
int[] rate;      // USED TO POSITION BPM DATA WAVEFORM
float zoom;      // USED WHEN SCALING PULSE WAVEFORM TO PULSE WINDOW
float offset;    // USED WHEN SCALING PULSE WAVEFORM TO PULSE WINDOW
color eggshell = color(255, 253, 248);
int heart = 0;   // This variable times the heart image 'pulse' on screen

int PulseWindowWidth = 490;
int PulseWindowHeight = 512; 
int BPMWindowWidth = 180;
int BPMWindowHeight = 340;
int error_flag = 0;
boolean beat = false;                            // set when a heart beat is detected, then cleared when the BPM graph is advanced
int connect_error = 0;
int success_flag = 0;
int first_draw = 0;
int exit_flag = 0;
void setup() 
{
      size(700, 600);                            // Stage size
      
      frameRate(100);  
      font = loadFont("Arial-BoldMT-24.vlw");
      textFont(font);
      textAlign(CENTER);
      rectMode(CENTER);
      ellipseMode(CENTER);  
      // Scrollbar constructor inputs: x,y,width,height,minVal,maxVal
      scaleBar = new Scrollbar (400, 575, 180, 12, 0.5, 1.0);  // set parameters for the scale bar
      RawY = new int[PulseWindowWidth];          // initialize raw pulse waveform array
      ScaledY = new int[PulseWindowWidth];       // initialize scaled pulse waveform array
      rate = new int [BPMWindowWidth];           // initialize BPM waveform array
      zoom = 0.75;                               // initialize scale of heartbeat window
        
      // set the visualizer lines to 0
      for (int i=0; i<rate.length; i++)
      {
         rate[i] = 555;      // Place BPM graph line at bottom of BPM Window 
      }
      
      for (int i=0; i<RawY.length; i++)
      {
         RawY[i] = height/2; // initialize the pulse window data line to V/2
      }
      
    
    // try{      
    // myClient = new Client(this, "192.168.7.1", 2500);      
   //  }catch (Exception e){
          
    //      connect_error = 1;
    //  }
      
      frameRate(1);
       background(51);
      
}
  
void draw() 
{
      error_flag = 0;
     
      if(first_draw == 0){
        fill(255, 0, 0);
      text("Connecting...",350,230);
      fill(255, 251, 240);
      text("If it doesn't responce for a long time.",350,300);
      text("Please check your wifi connection",350,330);  
      text("Or if your machine is normal running.",350,360);  
      }
      if(first_draw == 1)
      {      
        if(success_flag == 0)
        {            
            try{      
                   myClient = new Client(this, "192.168.7.1", 2500);      
               }catch (Exception e){
                   text("Connect Error!",350,260);
                   text("Please check if you connect to wifi \"RAK415AP\"",350,290);   
                   loop();          
                }finally{
                   success_flag = 1;      
                   frameRate(60);      
                }
  
        }
      }
      frameRate(60);      
      if(first_draw == 0)
      {
           first_draw++;
           return;
      }
      if (myClient.available() > 0)
      { 
         dataIn = myClient.readStringUntil('\n'); 
      } 
      
      if(dataIn == null)
      {
         return;
      }
      
      if((dataIn.charAt(0) != 'S') && (dataIn.charAt(0) != 'B') && (dataIn.charAt(0) != 'Q'))
      {
         error_flag = 1;
         return;
      }
      
      if(error_flag == 0)
      {
         dataIn = trim(dataIn);                     // cut off white space (carriage return)         
         
         if (dataIn.charAt(0) == 'S')               // leading 'S' for sensor data
         {            
             dataIn = dataIn.substring(1);          // cut off the leading 'S'
             Sensor = int(dataIn);                  // convert the string to usable int 
         }
         
         if (dataIn.charAt(0) == 'B')               // leading 'B' for BPM data
         {            
             dataIn = dataIn.substring(1);          // cut off the leading 'B'
             BPM = int(dataIn);                     // convert the string to usable int
             beat = true;                           // set beat flag to advance heart rate graph
             heart = 20;                            // begin heart image 'swell' timer  
         }
         
         if (dataIn.charAt(0) == 'Q')               // leading 'Q' means IBI data 
         {            
             dataIn = dataIn.substring(1);          // cut off the leading 'Q'
             IBI = int(dataIn);                     // convert the string to usable int
         }  
        
        
      
          background(0);
          noStroke();
          // DRAW OUT THE PULSE WINDOW AND BPM WINDOW RECTANGLES  
          fill(eggshell);  // color for the window background
          rect(255,height/2,PulseWindowWidth,PulseWindowHeight);
          rect(600,385,BPMWindowWidth,BPMWindowHeight);
          
          // DRAW THE PULSE WAVEFORM
          // prepare pulse data points    
          RawY[RawY.length-1] = (1023 - Sensor) - 212;   // place the new raw datapoint at the end of the array
          zoom = scaleBar.getPos();                      // get current waveform scale value
          offset = map(zoom,0.5,1,150,0);                // calculate the offset needed at this scale
          
          for (int i = 0; i < RawY.length-1; i++) 
          {      // move the pulse waveform by
              RawY[i] = RawY[i+1];                         // shifting all raw datapoints one pixel left
              float dummy = RawY[i] * zoom + offset;       // adjust the raw data to the selected scale
              ScaledY[i] = constrain(int(dummy),44,556);   // transfer the raw data array to the scaled array
          }
          
          stroke(250,0,0);                               // red is a good color for the pulse waveform
          noFill();
          beginShape(); 
          // using beginShape() renders fast
          for (int x = 1; x < ScaledY.length-1; x++) 
          {    
            vertex(x+10, ScaledY[x]);                    //draw a line connecting the data points
          }
          
          endShape();
      
          // DRAW THE BPM WAVE FORM
          // first, shift the BPM waveform over to fit then next data point only when a beat is found
          if (beat == true)
          {   // move the heart rate line over one pixel every time the heart beats 
               beat = false;      // clear beat flag (beat flag waset in serialEvent tab)
               
               for (int i=0; i<rate.length-1; i++)
               {
                   rate[i] = rate[i+1];                  // shift the bpm Y coordinates over one pixel to the left
               }
               
               // then limit and scale the BPM value
               BPM = min(BPM,200);                     // limit the highest BPM value to 200
               float dummy = map(BPM,0,200,555,215);   // map it to the heart rate window Y
               rate[rate.length-1] = int(dummy);       // set the rightmost pixel to the new data point value
          } 
          // GRAPH THE HEART RATE WAVEFORM
          stroke(250,0,0);                          // color of heart rate graph
          strokeWeight(2);                          // thicker line is easier to read
          noFill();
          beginShape();
          
          for (int i=0; i < rate.length-1; i++)
          {    // variable 'i' will take the place of pixel x position   
              vertex(i+510, rate[i]);                 // display history of heart rate datapoints
          }
          
          endShape();
         
          // DRAW THE HEART AND MAYBE MAKE IT BEAT
          fill(250,0,0);
          stroke(250,0,0);
          // the 'heart' variable is set in serialEvent when arduino sees a beat happen
          heart--;                    // heart is used to time how long the heart graphic swells when your heart beats
          heart = max(heart,0);       // don't let the heart variable go into negative numbers
          
          if (heart > 0)
          {             // if a beat happened recently, 
              strokeWeight(8);          // make the heart big
          }
          
          smooth();   // draw the heart with two bezier curves
          bezier(width-100,50, width-20,-20, width,140, width-100,150);
          bezier(width-100,50, width-190,-20, width-200,140, width-100,150);
          strokeWeight(1);          // reset the strokeWeight for next time
        
        
          // PRINT THE DATA AND VARIABLE VALUES
          fill(eggshell);                                       // get ready to print text
          text("Heart Rate Waveform",245,30);   // tell them what you are
          text("Interval " + IBI + "ms",600,585);                    // print the time between heartbeats in mS
          text(BPM + " b/s",600,200);                           // print the Beats Per Minute
          text("Pulse Window Scale " + nf(zoom,1,2), 150, 585); // show the current scale of Pulse Window
          
          //  DO THE SCROLLBAR THINGS
          scaleBar.update (mouseX, mouseY);
          scaleBar.display();
          myClient.clear();
     }  
   
} 



