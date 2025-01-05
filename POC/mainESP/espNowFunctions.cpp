#include "espNowFunctions.h"

uint8_t peerAddress[]={0x10, 0x06, 0x1C, 0x86, 0xA2, 0x9C};

espNow::espNow():m_isOngoingSession(false),m_macAddress(peerAddress){
  WiFi.mode(WIFI_STA);
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
 
  // memcpy(m_peerInfo.peer_addr, peerAddress, 6);
  // m_peerInfo.channel = 0;  
  // m_peerInfo.encrypt = false;
  
  // // Add peer   
  // // delay(100);     
  // if (esp_now_add_peer(&m_peerInfo) != ESP_OK){
  //   Serial.println("Failed to add peer");
  //   return;
  // }
}

  
void espNow::initSession(){
  
  commands.session=true;
  
  // Send message via ESP-NOW
  esp_err_t result = esp_now_send(peerAddress, (uint8_t *) &commands, sizeof(commands));
   
  if (result == ESP_OK) {
    Serial.println("Sending confirmed");
  }
  else {
    Serial.println("Sending error");
  }

}



void espNow::haltSession(){
  commands.session=false;
  
  // Send message via ESP-NOW
  esp_err_t result = esp_now_send(peerAddress, (uint8_t *) &commands, sizeof(commands));
   
  if (result == ESP_OK) {
    Serial.println("Sending confirmed");
  }
  else {
    Serial.println("Sending error");
  }
  delay(2000);
}


bool espNow::isOngoingSession(){
  return m_isOngoingSession;
};



// void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status){
//   Serial.print("\r\nLast Packet Send Status:\t");
//   Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
// }