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
const char* ssid = "Bashar";
const char* password = "";
uint8_t masterMACAddress[] = {0x10,0x06,0x1C,0x86,0x1D,0xB0 };
// Callback function executed when data is received
void onDataReceive(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len) {
  memcpy(&myData, incomingData, sizeof(myData));
  session = myData.d;
  Serial.println("Data received");
  Serial.print("Session status: ");
  Serial.println(session);
}

void setup() {
  // Set up Serial Monitor
  Serial.begin(115200);

  // Connect to Wi-Fi
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

 // Serial.print("Connecting to Wi-Fi");

  // Initialize ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
  Serial.println("ESP-NOW initialized.");

  // Register the receive callback function
  esp_now_register_recv_cb(onDataReceive);

  // Add the master as a peer
  esp_now_peer_info_t peerInfo;
  memcpy(peerInfo.peer_addr, masterMACAddress, 6);
  peerInfo.channel = WiFi.channel(); // Use the same channel as the master
  peerInfo.encrypt = false;  // No encryption used (modify if you want encryption)

  if (esp_now_add_peer(&peerInfo) != ESP_OK) {
    Serial.println("Failed to add peer");
    return;
  }
  Serial.println("Peer added.");
}

void loop() {
  
}



