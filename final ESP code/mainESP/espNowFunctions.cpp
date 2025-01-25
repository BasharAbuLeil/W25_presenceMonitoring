#include "espNowFunctions.h"
#include <vector>

static std::vector<recivedMessage> g_receivedData;

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
    Serial.println("Sending confirmed");
  }
  else {
    Serial.println("Sending error");
  }

}

void handleReceivedData()
{
    // Check if the vector is empty
    if (g_receivedData.empty()) {
        Serial.println("No data in vector");
        return;
    }

    double sum = 0.0;
    // A map to track frequency of each col value
    std::map<int, int> colFrequency;

    // Iterate through the vector
    for (const auto& msg : g_receivedData) {
        sum += msg.avg;           // Accumulate avg values
        colFrequency[msg.col]++;  // Count frequency of each col
    }

    // Calculate overall average
    double avgActivity = sum / g_receivedData.size();

    // Find the color (col) with the highest frequency
    // The following code uses a simple loop or std::max_element
    int color = 0;
    int maxCount = 0;
    for (const auto& item : colFrequency) {
        if (item.second > maxCount) {
            maxCount = item.second;
            color = item.first;
        }
    }

    // Print or use avgActivity and color as needed
    Serial.print("Average Activity (avgActivity): ");
    Serial.println(avgActivity);

    Serial.print("Most Frequent Color (color): ");
    Serial.println(color);
    
    // Optionally, clear the vector if you want to reset after processing
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

