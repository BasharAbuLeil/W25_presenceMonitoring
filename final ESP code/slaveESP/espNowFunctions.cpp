// #include "espNowFunctions.h"

// // Define a peer address
// uint8_t peerAddress[] = {0x10, 0x06, 0x1C, 0x86, 0xA2, 0x9C};

// // Constructor for espNow class
// espNow::espNow() : m_isOngoingSession(false), m_macAddress(peerAddress) {
//   WiFi.mode(WIFI_STA);

//   if (esp_now_init() != ESP_OK) {
//     Serial.println("Error initializing ESP-NOW");
//     throw espNowExceptions();
//   }

//   esp_now_register_recv_cb(OnDataRecv);
//   esp_now_register_send_cb(OnDataSent);

//   memcpy(m_peerInfo.peer_addr, m_macAddress, 6);
//   m_peerInfo.channel = 0;
//   m_peerInfo.encrypt = false;

//   if (esp_now_add_peer(&m_peerInfo) != ESP_OK) {
//     Serial.println("Failed to add peer");
//     return;
//   }
// }

// // Callback function executed when data is sent
// void espNow::OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
//   Serial.print("\r\nLast Packet Send Status:\t");
//   Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
// }

// // Callback function executed when data is received
// void espNow::OnDataRecv(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len) {
//   recievedMsg m1;
//   memcpy(&m1, incomingData, sizeof(m1));
//   Serial.println("Data received");
//   Serial.print("Session status: ");
//   Serial.println(m1.init);
// }

// // Method to check ongoing session status
// bool espNow::isOngoingSession() const {
//   return m_isOngoingSession;
// }
