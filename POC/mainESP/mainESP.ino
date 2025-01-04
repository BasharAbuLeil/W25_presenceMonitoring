
#include "espNowFunctions.h"



bool onGoingSession=false;
espNow* peerCommunicator;

void setup() {
  // put your setup code here, to run once:
  //boot sequnce if important. screen -> sd -> wifi -> fireStore.
  peerCommunicator=new espNow;
}

void loop() {
  peerCommunicator->initSession();
  delay(10000);
  peerCommunicator->haltSession();
  delay(5000);
}
