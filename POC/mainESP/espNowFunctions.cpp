#include "espNowFunctions.h"

uint8_t peerAddress[]={0x10, 0x06, 0x1C, 0x86, 0x1D, 0xB0};

espNow::espNow():m_isOngoingSession(false),m_macAddress(peerAddress){
  WiFi.mode(WIFI_STA);
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    throw espNowExceptions();
  }
  // esp_now_register_recv_cb(OnDataRecv);
  // esp_now_register_send_cb(OnDataSent);
  memcpy(m_peerInfo.peer_addr, m_macAddress, 6);
  m_peerInfo.channel = 0;
  m_peerInfo.encrypt = false;
  if (esp_now_add_peer(&m_peerInfo) != ESP_OK) {
    Serial.println("Failed to add peer");
    return;
  }
}

void espNow::initSession(){
  msg m1;
  m1.init=true;
  esp_now_send(peerAddress, (uint8_t *)&m1, sizeof(m1));
}



void espNow::haltSession(){
  msg m1;
  m1.init=false;
  esp_now_send(peerAddress, (uint8_t *)&m1, sizeof(m1));
}




void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status){
  Serial.print("\r\nLast Packet Send Status:\t");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}