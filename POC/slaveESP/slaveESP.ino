// Include Libraries
#include <esp_now.h>
#include <WiFi.h>
 
// Define a data structure
typedef struct struct_message {
bool d;
} struct_message;
 
// Create a structured object
struct_message myData;
bool session;
int value =0;
 
// Callback function executed when data is received
void OnDataRecv(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len) {
  memcpy(&myData, incomingData, sizeof(myData));
 /* Serial.print("Data received: ");
  Serial.println(len);
  Serial.print("Boolean Value: ");
  Serial.println(myData.d);
  Serial.println();*/
  session= myData.d;
}
 
void setup() {
  // Set up Serial Monitor
  Serial.begin(115200);
  
  // Set ESP32 as a Wi-Fi Station
  WiFi.mode(WIFI_STA);
 
  // Initilize ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
  
  // Register callback function
  esp_now_register_recv_cb(OnDataRecv);
}
 
void loop() {
  if(session){
    Serial.println(value);
    value++;
  }
  else{
    value=0;
  }
  delay(1000);
}