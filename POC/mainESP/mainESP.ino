
#include "espNowFunctions.h"



bool onGoingSession=false;


void setup() {
  // put your setup code here, to run once:
  //boot sequnce if important. screen -> sd -> wifi -> fireStore.
  espNow peerCommunicator=new espNow;
}

void loop() {
  if(!onGoingSesson){
    //output get id message on the screen .
    // key pad aware. 
  }
  else {
    //manage esp now  communication
    // 
  }
}
