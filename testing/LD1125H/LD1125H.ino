#include <HardwareSerial.h>
#include <time.h>

HardwareSerial LD1115H_UART(2); // Use UART2 (pins 16 and 17)

// Global variables for thresholds and state tracking
float LD1115H_TH1 = 120.0; // Default TH1 sensitivity
float LD1115H_TH2 = 250.0; // Default TH2 sensitivity
float LD1115H_Clear_Time = 2.0;
float LD1115H_Mov_Time = 2.0;
time_t LD1115H_Last_Time = time(NULL);
time_t LD1115H_Last_Mov_Time = time(NULL);
bool LD1115H_Clearance_Status = false;

// Pin configuration
const int statusLedPin = 2; // GPIO2 for the status LED

void setup() {
  // Initialize serial ports
  Serial.begin(115200); // For debugging
  LD1115H_UART.begin(115200, SERIAL_8N1, 16, 17); // UART2 on GPIO16 and GPIO17

  // Configure status LED
  pinMode(statusLedPin, OUTPUT);
  digitalWrite(statusLedPin, LOW);

  Serial.println("ESP32 LD1115H UART Example Started");

  // Send initialization commands to LD1115H
  sendThreshold("mth1", LD1115H_TH1);
  sendThreshold("mth2", LD1115H_TH2);
}

void loop() {
  // Read data from LD1115H via UART
  if (LD1115H_UART.available()) {
    String uartData = LD1115H_UART.readStringUntil('\n');
    processUARTData(uartData);
  }

  // Periodic clearance scan
  /*if ((time(NULL) - LD1115H_Last_Time) > LD1115H_Clear_Time) {
    handleClearance();
  }*/

  // Simulate status LED blinking
  //digitalWrite(statusLedPin, !digitalRead(statusLedPin));
  delay(500);
}

// Function to send threshold settings to LD1115H
void sendThreshold(const String& name, float value) {
  String command = name + "=" + String(value, 0) + " \n";
  LD1115H_UART.print(command);
  Serial.print("Sent command: ");
  Serial.println(command);
}

// Function to process received UART data
void processUARTData(const String& data) {
  Serial.print("Received: ");
  Serial.println(data);

  if (data.startsWith("occ")) {
    LD1115H_Last_Time = time(NULL);
    LD1115H_Clearance_Status = false;
    Serial.println("Occupancy detected");
  } else if (data.startsWith("mov")) {
    LD1115H_Last_Time = time(NULL);
     LD1115H_Last_Mov_Time = time(NULL);
     Serial.println("Movement detected");
   }
 }

// // Function to handle clearance logic
 void handleClearance() {
   if (!LD1115H_Clearance_Status) {
     Serial.println("Clearance state updated.");
     LD1115H_Clearance_Status = true;
   }
}

