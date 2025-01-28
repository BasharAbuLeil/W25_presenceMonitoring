#include "espNowFunctions.h"
#include <vector>
#include "fire_store.h"
#include "display.h"
#include "SD_functions.h"
static std::vector<recivedMessage> g_receivedData;
static std::vector<std::pair<int,double>> mainSample;
static std::vector<recivedMessage> finalData;
extern unsigned long nextPrint;
extern unsigned long  printEvery ;
extern Adafruit_SSD1306 display;
uint8_t peerAddress[]={0x10, 0x06, 0x1C, 0x86, 0xA2, 0x9C};
static std::vector<int>colorFreq(3,0);
bool espNowSession;
extern bool wifiConnected;

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
  
  // Send message via ESP-NOW
  esp_err_t result = esp_now_send(peerAddress, (uint8_t *) &s1, sizeof(s1));
   
  if (result == ESP_OK) {
    nextPrint = millis() + printEvery;
    espNowSession=true;
    display.clearDisplay();
    display.setCursor(0, 0);
    display.print("Session is on going");
    display.display();
  }
  else {
    Serial.println("Sending error");
  }

}

void haltSession(){
  
  sendMessage s1;
  s1.session=false;
  // Send message via ESP-NOW
  esp_err_t result = esp_now_send(peerAddress, (uint8_t *) &s1, sizeof(s1));
   
  if (result == ESP_OK) {
    nextPrint = millis() + printEvery;
    espNowSession=false;
    display.clearDisplay();
    display.setCursor(0, 0);
    display.print("Session halted.");
  }
  else {
    display.clearDisplay();
    display.setCursor(0, 0);
    display.print("Session didn't halt");
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
  double sum=0;
  recivedMessage finalMsg;
  int packetCounter=1;
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
      if(finalMsg.avg>100){
        finalMsg.avg=100;
      }
      sum+=finalMsg.avg;
      finalMsg.packetNum=packetCounter;
      packetCounter++;
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
  if(!wifiConnected){
    std::vector<String>commitedVec=convertRecToString(packetCounter,id,sum,maxIndex+1,finalData);
    saveSessionToSD(id, commitedVec);
  }
  else{
    uploadDataToFirestore(id,sum,maxIndex+1,finalData);
  }
  for(int i=0;i<finalData.size();i++){
    Serial.print("packetNum:");
    Serial.println(finalData[i].packetNum);
    Serial.print("avg");
    Serial.println(finalData[i].avg);
    Serial.print("color");
    Serial.println(finalData[i].col);
  }

}
std::vector<String> convertRecToString(int packNums,const String& userID, double avgActivity, int color, const std::vector<recivedMessage>& receivedData) {
    std::vector<String> result;
    
    // Push the basic information
    result.push_back(userID);  // Fixed typo: userId -> userID
    result.push_back(String(avgActivity));
    result.push_back(String(color));
    result.push_back(String(packNums-1));
    // Push all received data
    for (const recivedMessage& m : receivedData) {
        result.push_back(String(m.avg));
        result.push_back(String(m.col));
        result.push_back(String(m.packetNum));
    }
    
    return result;  // Added missing return statement
}

// Second function: Updating final data from String vector
// void updateFinalData(const std::vector<String>& vec) {  // Added & and fixed string -> String
//     finalMsg.clear();  // Assuming finalMsg is a global vector<recivedMessage>
    
//     // Get basic information
//     String id = vec[0];
//     double avgActivity = vec[1].toDouble();
//     int color = vec[2].toInt();
    
//     // Process the received messages
//     for (int i = 3; i < vec.size(); i += 3) {  // Changed increment to i += 3
//         recivedMessage toPush;
//         toPush.avg = vec[i].toDouble();
//         toPush.col = vec[i + 1].toInt();
//         toPush.packetNum = vec[i + 2].toInt();
//         finalMsg.push_back(toPush);
//     }
// }
double max(double d1,double d2){
  return d1>d2? d1:d2;
}
