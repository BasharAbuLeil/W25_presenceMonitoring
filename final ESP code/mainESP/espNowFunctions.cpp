#include "espNowFunctions.h"
#include <vector>
#include "fire_store.h"
static std::vector<recivedMessage> g_receivedData;
static std::vector<std::pair<int,double>> mainSample;
static std::vector<recivedMessage> finalData;
extern unsigned long nextPrint;
extern unsigned long  printEvery ;
uint8_t peerAddress[]={0x10, 0x06, 0x1C, 0x86, 0xA2, 0x9C};
static std::vector<int>colorFreq(3,0);
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

void printAllData(String id){
  Serial.println("main Data:");
  /*for(const std::pair<int,double>&p:mainSample){
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
  }*/
  double sum=0;
  recivedMessage finalMsg;
  for(int i=0;i<mainSample.size();i++){
    std::pair<int,double>p=mainSample[i];
    int packetNum=p.first;
    int avg=p.second;
    bool found =false;
    for(int j=0;j<g_receivedData.size();j++){
      if(g_receivedData[j].packetNum==packetNum){
        found=true;
        finalMsg=g_receivedData[i];
        break;
      }
    }
    if(found){
      finalMsg.avg=max(avg,finalMsg.avg)*100;
      sum+=finalMsg.avg;
      colorFreq[finalMsg.col-1]++;
      finalData.push_back(finalMsg);
    }
    
  }
  sum=sum/(double)(finalData.size());
  int maxIndex = 0;
  int maxValue = colorFreq[0];

    // Loop through the vector to find the maximum value and its index
  for (int i = 1; i < colorFreq.size(); i++) {
      if (colorFreq[i] > maxValue) {
          maxValue = colorFreq[i];
          maxIndex = i;
      }
  }
  uploadDataToFirestore(id,sum,maxIndex+1,finalData);
  for(int i=0;i<finalData.size();i++){
    Serial.print("packetNum:");
    Serial.println(finalData[i].packetNum);
    Serial.print("avg");
    Serial.println(finalData[i].avg);
    Serial.print("color");
    Serial.println(finalData[i].col);
  }

}

double max(double d1,double d2){
  return d1>d2? d1:d2;
}
