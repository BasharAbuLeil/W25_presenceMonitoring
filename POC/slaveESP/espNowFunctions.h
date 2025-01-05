#ifndef ESP_NOW_FUNCTIONS_H
#define ESP_NOW_FUNCTIONS_H

#include <esp_now.h>
#include <WiFi.h>

// Define a structure for received messages
typedef struct struct_message {
  bool init;
} recievedMsg;

class espNow {
private:
  bool m_isOngoingSession;
  esp_now_peer_info_t m_peerInfo;
  uint8_t* m_macAddress;

  static void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status);
  static void OnDataRecv(const uint8_t *mac_addr, const uint8_t *incomingData, int len);

public:
  espNow();
  bool isOngoingSession() const;
};

class espNowExceptions {};

#endif
