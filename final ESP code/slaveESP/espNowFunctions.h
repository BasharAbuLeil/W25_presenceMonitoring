#ifndef ESP_NOW_FUNCTIONS_H
#define ESP_NOW_FUNCTIONS_H


#include <esp_now.h>
#include <WiFi.h>



typedef struct struct_message {
  double avg;
  int col;
  int packetNum;
}sentMessage;


void setupEspNow();
void sendData(double avg,int col);
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status);
void onDataReceive(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len);


class espNowExceptions{};

// class espInitFailed{}: public espNowExceptions{};;




#endif






