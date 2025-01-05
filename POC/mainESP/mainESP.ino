/*
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
*/

#include <WiFi.h>
#include "espNowFunctions.h"
// Variables for test data
int int_value=0;
float float_value;
bool bool_value = true;
//10:06:1C:86:1D:B0
// MAC Address of responder - edit as required
uint8_t broadcastAddress[] = {0x10, 0x06, 0x1C, 0x86, 0xA2, 0x9C};
espNow* peerCommunicator;
// Define a data structure
// typedef struct struct_message {
//   char a[32];
//   int b;
//   float c;
//   bool d;
// } struct_message;
 
// Create a structured object
struct_message myData;
 
// Peer info
esp_now_peer_info_t peerInfo;
 
// Callback function called when data is sent
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  Serial.print("\r\nLast Packet Send Status:\t");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}
 
void setup() {
  
  // Set up Serial Monitor
  Serial.begin(115200);
  peerCommunicator=new espNow;
  esp_now_register_send_cb(OnDataSent);
  
  // Register peer
  memcpy(peerInfo.peer_addr, broadcastAddress, 6);
  peerInfo.channel = 0;  
  peerInfo.encrypt = false;
  
  // Add peer  
  delay(100);      
  if (esp_now_add_peer(&peerInfo) != ESP_OK){
    Serial.println("Failed to add peer");
    return;
  }
}
 
void loop() {
  delay(5000);
  peerCommunicator->initSession();
  delay(5000);
  peerCommunicator->haltSession();
}