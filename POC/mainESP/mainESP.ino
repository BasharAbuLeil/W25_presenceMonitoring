
#include <WiFi.h>
#include "espNowFunctions.h"
#include "display.h"
#include "SD_functions.h"
#include <Keypad.h>
#include <string>
#include "fire_store.h"


const int BUILT_IN_LED=2;
const int  ROW_NUM = 4; // four rows
const int COLUMN_NUM= 4; // four columns
const  int ID_LENGTH=6;
char keys[ROW_NUM][COLUMN_NUM] = {
  {'1', '2', '3', 'A'},
  {'4', '5', '6', 'B'},
  {'7', '8', '9', 'C'},
  {'*', '0', '#', 'D'}
};
byte pin_rows[ROW_NUM]      = {12, 14, 27, 26}; // GPIOs for rows
byte pin_column[COLUMN_NUM] = {25, 33, 32, 4};  // GPIOs for columns
Keypad keypad = Keypad( makeKeymap(keys), pin_rows, pin_column, ROW_NUM, COLUMN_NUM );

typedef struct recieved_message {
  int value ;
} data_received;





typedef struct fireStoreData{
  int id;
  int color;

}fireStoreData;

extern Adafruit_SSD1306 display;


std::string id;
extern char * passwrod;
extern char * ssid;
bool wifiConnceted;
int value;
uint8_t broadcastAddress[] = {0x10, 0x06, 0x1C, 0x86, 0xA2, 0x9C};
espNow* peerCommunicator;
esp_now_peer_info_t peerInfo;
data_received d1;
void onDataReceive(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len) {
  memcpy(&d1, incomingData, sizeof(d1));
  value = d1.value;
  Serial.println("Value received");
  Serial.println(value);
}




void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  Serial.print("\r\nLast Packet Send Status:\t");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}
 



void getId(){
  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("INSERT ID:");
  display.display();
  delay(2000);
  display.clearDisplay();
  id="";
  int counter =0;
  while(counter<ID_LENGTH) {
    char key = keypad.getKey();
    if(key){
      if(key=='D'&&counter>0){
        id.pop_back();
        counter--;
      }
      else{
        id+=key;
        counter++;
      }
      display.setCursor(0, 0);
      display.print(id.c_str());
      display.display();
    }
  }
}




bool isKeyPressed(){
  char key = keypad.getKey();
  if(key)
    return true;
  return false;
}
// Callback function called when data is sent
void setup() {
  
  // Set up Serial Monitor
  Serial.begin(115200);
  initDisplay();
  initSd();
  getWifiData();
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  int tries=0;
  while(WiFi.status() != WL_CONNECTED) {
    tries++;
    delay(1000);
    Serial.print(".");
  }
  Serial.println("ssid:");
  Serial.println(ssid);
  Serial.println("password");
  Serial.println(password);
  peerCommunicator=new espNow;
  esp_now_register_send_cb(OnDataSent);
  esp_now_register_recv_cb(onDataReceive);
  memcpy(peerInfo.peer_addr, broadcastAddress, 6);
  peerInfo.channel = WiFi.channel();  
  peerInfo.encrypt = false;
  pinMode(BUILT_IN_LED,OUTPUT);
  // Add peer  
  delay(100);      
  if (esp_now_add_peer(&peerInfo) != ESP_OK){
    Serial.println("Failed to add peer");
    return;
  }
  establishFireBaseConnection();
}
 
void loop() {
  if(peerCommunicator->isOngoingSession()){
    //if any keyPressed or timeout halt  the time has to be synced.
    if(isKeyPressed()){
      digitalWrite(BUILT_IN_LED, LOW);
      peerCommunicator->haltSession();
      display.clearDisplay();
      display.setCursor(0,0);
      display.println("session halted");
      display.display();
      delay(1000);
      //adding fireStoreData 
    }
  }
  else{
    getId();
    peerCommunicator->initSession(); 
    digitalWrite(BUILT_IN_LED,HIGH);
  }
  delay(100);
}






