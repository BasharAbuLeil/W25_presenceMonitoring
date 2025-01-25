#ifndef ESP_NOW_FUNCTIONS_H
#define ESP_NOW_FUNCTIONS_H


#include <esp_now.h>
#include <WiFi.h>





/*class espNow{
  bool m_isOngoingSession;
  esp_now_peer_info_t m_peerInfo;
  uint8_t* m_macAddress;
  message commands;
  void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status)  ;
  // void OnDataRecv(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len) =0;
public :
  espNow();
  void initSession();
  void haltSession();
  bool isOngoingSession();
};*/

void setupEspNow();
void initSession();
void haltSession();

typedef struct struct_message {
  double avg;
  int col;
  int packetNum;
}recivedMessage;

typedef struct send_Message{
  bool session;
}sendMessage;

void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status);
void onDataReceive(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len);

// class espInitFailed{}: public espNowExceptions{};;




#endif






