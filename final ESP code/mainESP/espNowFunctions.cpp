#include "espNowFunctions.h"
#include <iostream>
#include <vector>
static std::vector<recivedMessage> g_receivedData;
static std::vector<std::pair<int,double>> mainSample;
extern unsigned long nextPrint;
extern unsigned long  printEvery ;
uint8_t peerAddress[]={0x10, 0x06, 0x1C, 0x86, 0xA2, 0x9C};
bool espNowSession;
void setupEspNow() {
  WiFi.mode(WIFI_STA);

  // Initialize ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
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
void initSession(){
  sendMessage s1;
  s1.session=false;
  espNowSession=true;
  // Send message via ESP-NOW
  esp_err_t result = esp_now_send(peerAddress, (uint8_t *) &s1, sizeof(s1));
   
  if (result == ESP_OK) {
    nextPrint = millis() + printEvery;
    Serial.println("Sending confirmed");
  }
  else {
    Serial.println("Sending error");
  }

}

void handleReceivedData()
{
    // 1) Check if the vector is empty
    if (g_receivedData.empty()) {
        Serial.println("No data in vector");
        return;
    }

    // 2) List of possible colors and frequency array
    String possibleColors[] = {"BLUE", "GREEN", "RED", "BLACK", "WHITE"};
    const int colorCount = sizeof(possibleColors) / sizeof(possibleColors[0]);
    int colFrequency[colorCount];
    
    // Initialize all frequency counts to 0
    for (int i = 0; i < colorCount; i++) {
        colFrequency[i] = 0;
    }

    // 3) Sum up avg values and track frequency of col
    double sum = 0.0;
    for (size_t i = 0; i < g_receivedData.size(); i++) {
        sum += g_receivedData[i].avg;

        // Look for which color matches msg.col
        for (int j = 0; j < colorCount; j++) {
            if (g_receivedData[i].col == possibleColors[j]) {
                colFrequency[j]++;
                break; // Exit once a match is found
            }
        }
    }

    // 4) Compute overall average
    double avgActivity = sum / g_receivedData.size();

    // 5) Determine which color has the highest frequency
    int maxCount = -1;
    String mostFrequentColor = "UNKNOWN";
    for (int i = 0; i < colorCount; i++) {
        if (colFrequency[i] > maxCount) {
            maxCount = colFrequency[i];
            mostFrequentColor = possibleColors[i];
        }
    }

    // 6) Print or store the results
    Serial.print("Average Activity (avgActivity): ");
    Serial.println(avgActivity, 2);

    Serial.print("Most Frequent Color: ");
    Serial.println(mostFrequentColor);

    // (Optional) Clear g_receivedData if you'd like to reset after processing:
    // g_receivedData.clear();
}

void haltSession(){
  
 sendMessage s1;
  s1.session=false;
  espNowSession=false;
  // Send message via ESP-NOW
  esp_err_t result = esp_now_send(peerAddress, (uint8_t *) &s1, sizeof(s1));
   
  if (result == ESP_OK) {
    Serial.println("Sending confirmed");
  }
  else {
    Serial.println("Sending error");
  }
}


void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  Serial.print("\r\nLast Packet Send Status:\t");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}


recivedMessage d1;
void onDataReceive(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len) {
  memcpy(&d1, incomingData, sizeof(d1));
  Serial.print("packetNum");
  Serial.print(d1.packetNum);
  Serial.print("avg");
  Serial.print(d1.avg);
  Serial.print("col");
  Serial.print(d1.col);
  g_receivedData.push_back(d1);
  // for testing if its accually work
  Serial.print("Current vector size: ");
  Serial.println(g_receivedData.size());
}

void updateMainVector(int packetNum,double avg)
{
  mainSample.push_back({packetNum,avg});
}

void printAllData(){
  Serial.println("main Data:");
  for(const std::pair<int,double>&p:mainSample){
    Serial.print("packetNum:");
    Serial.println(p.first);
    Serial.print("avg");
    Serial.println(p.second);
  } 
  Serial.println("slave data");
  for(const recivedMessage& m:g_receivedData){
    Serial.print("packetNum:");
    Serial.println(m.packetNum);
    Serial.print("avg");
    Serial.println(m.avg);
    Serial.print("color");
    Serial.println(m.col);
  }
}
