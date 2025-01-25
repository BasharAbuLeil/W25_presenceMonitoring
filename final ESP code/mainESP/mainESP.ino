
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
byte pin_rows[ROW_NUM] = {12, 14, 27, 26}; // GPIOs for rows
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

int value;
esp_now_peer_info_t peerInfo;
extern bool espNowSession;



void connectToWiFi() {
  getWifiData();
  Serial.println("Connecting to Wi-Fi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nConnected to Wi-Fi!");
}
void disconnectWiFi() {
  Serial.println("Disconnecting Wi-Fi...");
  WiFi.disconnect(true);
  WiFi.mode(WIFI_OFF);
  Serial.println("Wi-Fi disconnected.");
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
      else if(key>='0'&&key<='9'){
        id+=key;
        counter++;
      }
      display.setCursor(0, 0);
      display.clearDisplay();
      display.print(id.c_str());
      display.display();
      Serial.println("id string =");
      Serial.println(id.c_str());
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
  espNowSession=false;
  Serial.begin(115200);
  initDisplay();
  initSd();
  setupEspNow();
  pinMode(BUILT_IN_LED,OUTPUT);
}
 
void loop() {
  if(espNowSession){
    //if any keyPressed or timeout halt  the time has to be synced.
    if(isKeyPressed()){
      digitalWrite(BUILT_IN_LED, LOW);
      haltSession();
      display.clearDisplay();
      display.setCursor(0,0);
      display.println("session halted");
      display.display();
      delay(1000);
      //exampleUsage();
      //adding fireStoreData 
      connectToWiFi();
      if (!initFirestore()) {
      Serial.println("Failed to initialize Firestore.");
      } else {
        Serial.println("Firestore initialized successfully.");
      }
      delay(5000);
      disconnectWiFi();
      setupEspNow();
    }
  }
  else{
    getId();
    initSession(); 
    digitalWrite(BUILT_IN_LED,HIGH);
  }
  delay(100);
}






