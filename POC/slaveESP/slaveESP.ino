#include <esp_now.h>
#include <WiFi.h>

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
const char* ssid = "Bashar";
const char* password = "toz12345";
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
    
    // Set ESP32 as a Wi-Fi Station
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);
    // Initialize ESP-NOW
    if (esp_now_init() != ESP_OK) {
        Serial.println("Error initializing ESP-NOW");
        return;
    }
    Serial.println("ESP-NOW initialized.");
    
    // Register callback functions
    esp_now_register_recv_cb(onDataReceive);
    esp_now_register_send_cb(OnDataSent);
    
    // Add the master as a peer
    esp_now_peer_info_t peerInfo;
    memcpy(peerInfo.peer_addr, masterMACAddress, 6);
    peerInfo.channel = WiFi.channel(); // Use the same channel as the master
    peerInfo.encrypt = false;  // No encryption used (modify if you want encryption)

    delay(100);
    if (esp_now_add_peer(&peerInfo) != ESP_OK) {
        Serial.println("Failed to add peer");
        return;
    }
    Serial.println("Peer added.");
}

void loop() {
    if(session) {
        Serial.print("value == ");
        Serial.println(value);
        
        // Increment value and prepare data to send
        value++;
        sendData.value = value;
        
        // Send data to master
        esp_err_t result = esp_now_send(masterMACAddress, (uint8_t *)&sendData, sizeof(sendData));
        
        if (result == ESP_OK) {
            Serial.println("Sending confirmed");
        } else {
            Serial.println("Sending error");
        }
    } else {
        value = 0;
    }
    //test
    delay(1000);
}