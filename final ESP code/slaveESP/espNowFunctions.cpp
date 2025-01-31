#include "espNowFunctions.h"
uint8_t peerAddress[] = {0x10, 0x06, 0x1C, 0x86, 0x1D, 0xB0};

bool espNowSession;
sentMessage cmd;
int packetNum=0;
extern unsigned long nextPrint,printEvery;
esp_now_peer_info_t peerInfo;
void setupEspNow() {
  WiFi.mode(WIFI_STA);
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
  esp_now_register_send_cb(OnDataSent);
  esp_now_register_recv_cb(onDataReceive);
  memcpy(peerInfo.peer_addr, peerAddress, 6);
  peerInfo.channel = 0;  
  peerInfo.encrypt = false;
  
  // Add peer  
  delay(100);      
  if (esp_now_add_peer(&peerInfo) != ESP_OK){
    Serial.println("Failed to add peer");
    return;
  }
  else{
   Serial.println("Success"); 
  }
}
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  Serial.print("\r\nLast Packet Send Status:\t");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}

void onDataReceive(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len) {
  espNowSession=!espNowSession;
  if(espNowSession){
    Serial.println("session started");
    packetNum=0;
    nextPrint = millis() + printEvery;
  }
  else{
    Serial.println("session ended.");
  }
}

void sendData(double avg,int col){
  cmd.avg=avg;
  cmd.col=col;
  cmd.packetNum=packetNum;
  Serial.print("packetNum");
  Serial.print(cmd.packetNum);
  Serial.print("avg");
  Serial.print(cmd.avg);
  Serial.print("col");
  Serial.print(cmd.col);
  esp_err_t result = esp_now_send(peerAddress, (uint8_t *) &cmd, sizeof(cmd));
   
  if (result == ESP_OK) {
    packetNum++;
    Serial.println("Sending confirmed");
  }
  else {
    Serial.println("Sending error");
  }
}
  
