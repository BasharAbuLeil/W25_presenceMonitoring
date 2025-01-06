#include <esp_now.h>
#include <WiFi.h>



#define BUILT_IN_LED 2
// Define a data structure for receiving session control
typedef struct struct_session {
    bool d;
} struct_session;

// Define a data structure for sending values
typedef struct struct_data {
    int value;
} struct_data;

// Create structured objects
struct_session sessionData;
struct_data sendData;
const char* ssid = "";
const char* password = "";
esp_now_peer_info_t peerInfo;
// Global variables
bool session = false;
int value = 0;

// MAC Address of master ESP32
uint8_t masterMACAddress[] = {0x10, 0x06, 0x1C, 0x86, 0x1D, 0xB0};

// Callback function executed when data is received
void onDataReceive(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len) {
    memcpy(&sessionData, incomingData, sizeof(sessionData));
    session = sessionData.d;
    Serial.println("Data received");
    Serial.print("Session status: ");
    Serial.println(session);
}

// Callback function executed when data is sent
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
    Serial.print("\r\nLast Packet Send Status:\t");
    Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}

void setup() {
  
  // Set up Serial Monitor
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  int tries=0;
  //while(WiFi.status() != WL_CONNECTED) {
  //   tries++;
  //   delay(1000);
  //   Serial.print(".");
  // }
  Serial.println("ssid:");
  Serial.println(ssid);
  Serial.println("password");
  Serial.println(password);
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
  esp_now_register_send_cb(OnDataSent);
  esp_now_register_recv_cb(onDataReceive);
  memcpy(peerInfo.peer_addr, masterMACAddress, 6);
  peerInfo.channel = WiFi.channel();  
  peerInfo.encrypt = false;
  
  // Add peer  
  delay(100);      
  if (esp_now_add_peer(&peerInfo) != ESP_OK){
    Serial.println("Failed to add peer");
    return;
  }
  pinMode(BUILT_IN_LED, OUTPUT);
  //ending the esp now part 
  //wifi part
  
  
  
  // Register peer
  
}

void loop() {
    if(session) {
      digitalWrite(BUILT_IN_LED, HIGH);
      Serial.print("value == ");
      Serial.println(value);
        
      // Increment value and prepare data to send
      value++;
      sendData.value = value;
        
      // Send data to master
      esp_err_t result = esp_now_send(masterMACAddress, (uint8_t *)&sendData, sizeof(sendData));
        
      if (result == ESP_OK) {
           Serial.println("Sending confirmed");
      }else {
           Serial.println("Sending error");
      }
    } else {
      digitalWrite(BUILT_IN_LED, LOW);
      value = 0;
    }
    //test
    delay(1000);
}