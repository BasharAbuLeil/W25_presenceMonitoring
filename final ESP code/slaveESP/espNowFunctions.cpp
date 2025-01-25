#include "espNowFunctions.h"

uint8_t peerAddress[]={0x10,0x06,0x1C,0x86,0xA2,0x9C};
bool espNowSession;
sentMessage cmd;
int packetNum=0;
extern unsigned long nextPrint,printEvery;
void setupEspNow() {
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();

  // Initialize ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    ESP.restart();
  }
  Serial.println("ESP-NOW initialized");

  // Register peer
  esp_now_peer_info_t peerInfo;
  memcpy(peerInfo.peer_addr, peerAddress, 6);
  peerInfo.channel = 0;
  peerInfo.encrypt = false;
  esp_now_register_send_cb(OnDataSent);
  esp_now_register_recv_cb(onDataReceive);
  if (esp_now_add_peer(&peerInfo) != ESP_OK) {
    Serial.println("Failed to add peer");
  } else {
    Serial.println("Peer added successfully");
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
    Serial.println("Sending confirmed");
  }
  else {
    Serial.println("Sending error");
  }
}
  
