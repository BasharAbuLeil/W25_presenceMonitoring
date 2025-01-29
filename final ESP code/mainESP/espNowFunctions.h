#ifndef ESP_NOW_FUNCTIONS_H
#define ESP_NOW_FUNCTIONS_H


#include <esp_now.h>
#include <WiFi.h>





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
void updateMainVector(int packetNum,double avg);
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status);
void onDataReceive(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len);
void printAllData(String id);
double max(double d1,double d2);
std::vector<String> convertRecToString(int packNums,const String& userID, double avgActivity, int color, const std::vector<recivedMessage>& receivedData);
void updateFinalData(const std::vector<String>& vec);
// class espInitFailed{}: public espNowExceptions{};;




#endif






