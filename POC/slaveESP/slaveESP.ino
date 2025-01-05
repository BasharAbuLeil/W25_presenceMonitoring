#include <esp_now.h>
#include <WiFi.h>

// Define a data structure for messages
typedef struct struct_message {
  bool d;
} struct_message;

// Create a structured object
struct_message myData;
bool session = false;
int value = 0;

// Callback function executed when data is received
void OnDataRecv(const uint8_t *mac_addr, const uint8_t *incomingData, int len) {
  memcpy(&myData, incomingData, sizeof(myData));
  session = myData.d;
  Serial.println("Data received");
  Serial.print("Session status: ");
  Serial.println(session);
}

void setup() {
  // Set up Serial Monitor
  Serial.begin(115200);

  // Set ESP32 as a Wi-Fi Station
  WiFi.mode(WIFI_STA);

  // Initialize ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }

  // Register callback function
  esp_now_register_recv_cb(OnDataRecv);
}

void loop() {
  
}
