
#include <WiFi.h>
#include "espNowFunctions.h"
#include "display.h"

extern Adafruit_SSD1306 display;


uint8_t broadcastAddress[] = {0x10, 0x06, 0x1C, 0x86, 0xA2, 0x9C};
espNow* peerCommunicator;
esp_now_peer_info_t peerInfo;
 
// Callback function called when data is sent
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  Serial.print("\r\nLast Packet Send Status:\t");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}
 
void setup() {
  
  // Set up Serial Monitor
  Serial.begin(115200);
  initDisplay();
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
  display.println("ongoing session.");
  display.display();
  delay(5000);
  peerCommunicator->haltSession();
  display.println("ongoing session.");
  display.display();
}