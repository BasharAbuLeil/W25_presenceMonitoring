#include <WiFi.h>
#include <Wire.h>
#include "display.h"
#include "credentials.h"
#include "SD_functions.h"
// #include"fire_store.h"

// OLED display configuration

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
bool connected=false;
void setup() {
  // Initialize OLED display
  if (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    while (true); // Halt if OLED fails to initialize
  }
   display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Initializing...");
  display.display();
  initSd();
    display.clearDisplay();
    display.setCursor(0, 0);
  display.println("Loading Credentials...");
  display.display();

  getWifiData(); // Load WiFi credentials from SD card

  if(ssid == nullptr || password==nullptr){
      display.clearDisplay();
      display.setCursor(0,0);
      display.println("Failed to load");
      display.println("credentials");
        display.display();
    while(true);
  }

  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("Initializing Wi-Fi...");
  display.display();


  // Set Wi-Fi mode to station
  WiFi.mode(WIFI_STA);
  // Begin Wi-Fi connection
  WiFi.begin(ssid, password);

  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("Connecting to Wi-Fi...");
  display.display();

  int retryCount = 0;
  const int maxRetries = 20; // Number of retries before giving up
  while (WiFi.status() != WL_CONNECTED && retryCount < maxRetries) {
    delay(500);
    retryCount++;
    display.print(".");
    display.display();
  }

  display.clearDisplay();

  if (WiFi.status() == WL_CONNECTED) {
    display.println("Wi-Fi connected!");
    display.print("IP: ");
    display.println(WiFi.localIP());
    connected=true;
  } else {
    display.println("Failed to connect.");
    display.println("Check credentials.");
  }
  display.display();
  if(connected){
    // establishFireBaseConnection();
  }
}

void loop() {
  // Optionally, monitor Wi-Fi connection status
  /*if (WiFi.status() != WL_CONNECTED) {
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("Wi-Fi disconnected!");
    display.println("Reconnecting...");
    display.display();
    WiFi.reconnect();
    delay(10000); // Retry every 10 seconds
  }
  delay(5000);*/
   //Firebase.ready(); // should be called repeatedly to handle authentication tasks.

  // This is a demo of POSTING data to RTDB using setJSON

  
  /*for(int i=1;i<=10;i++){
    FirebaseJson json;
    if (Firebase.ready() && (millis() - sendDataPrevMillis > 15000 || sendDataPrevMillis == 0)){
      String key = "id" + String(i);     // Key as a string
      String value = "ID_" + String(i); // Example value
      json.add(key.c_str(), value);      
      Serial.printf("Set json... %s\n\n", Firebase.RTDB.setJSON(&fbdo, "/counter/data/json", &json) ? "ok" : fbdo.errorReason().c_str());
    }*/
    
  // }

}




