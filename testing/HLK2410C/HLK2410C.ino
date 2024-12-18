/*
  This program reads all data received from
  the HLK-LD2410 presence sensor and periodically
  prints the values to the serial monitor.
  
  Several #defines control the behavior of the program:
  #define SERIAL_BAUD_RATE sets the serial monitor baud rate
  #define ENHANCED_MODE enables the enhanced (engineering)
  mode of the sensor. Comment that line to switch to basic mode.
  #define DEBUG_MODE enables the printing of debug information
  (all reaceived frames are printed). Comment the line to disable
  debugging.

  Communication with the sensor is handled by the 
  "MyLD2410" library Copyright (c) Iavor Veltchev 2024

  Use only hardware UART at the default baud rate 256000,
  or change the #define LD2410_BAUD_RATE to match your sensor.
  For ESP32 or other boards that allow dynamic UART pins,
  modify the RX_PIN and TX_PIN defines

  Connection diagram:
  Arduino/ESP32 RX  -- TX LD2410 
  Arduino/ESP32 TX  -- RX LD2410
  Arduino/ESP32 GND -- GND LD2410
  Provide sufficient power to the sensor Vcc (200mA, 5-12V) 
*/
#ifdef ESP32
#define sensorSerial Serial1
#define RX_PIN 16
#define TX_PIN 17
#define INDICATOR_PIN 15
#elif defined(ARDUINO_SAMD_NANO_33_IOT)
#define sensorSerial Serial1
#else
#error "This sketch only works on ESP32 or Arduino Nano 33IoT"
#endif

// User defines
#define SERIAL_BAUD_RATE 115200
#define ENHANCED_MODE
// #define DEBUG_MODE

//Change the communication baud rate here, if necessary
//#define LD2410_BAUD_RATE 256000
#include "MyLD2410.h"

#ifdef DEBUG_MODE
MyLD2410 sensor(sensorSerial, true);
#else
MyLD2410 sensor(sensorSerial);
#endif

unsigned long nextPrint = 0, printEvery = 1000;  // print every second

void printValue(const byte &val) {
  Serial.print(' ');
  Serial.print(val);
}

void printData() {
  Serial.print(sensor.statusString());
  if (sensor.presenceDetected()) {

    digitalWrite(INDICATOR_PIN, HIGH);

    Serial.print(", distance: ");
    Serial.print(sensor.detectedDistance());
    Serial.print("cm");
  } else {
    digitalWrite(INDICATOR_PIN, LOW);
  }
  Serial.println();
}

void setup() {
  Serial.begin(SERIAL_BAUD_RATE);
#ifdef ESP32
  sensorSerial.begin(LD2410_BAUD_RATE, SERIAL_8N1, RX_PIN, TX_PIN);
#else
  sensorSerial.begin(LD2410_BAUD_RATE);
#endif
  pinMode(INDICATOR_PIN, OUTPUT);
  delay(2000);
  if (!sensor.begin()) {
    Serial.println("Failed to communicate with the sensor.");
    while (true)
      ;
  }

#ifdef ENHANCED_MODE
  sensor.enhancedMode();
#endif

  delay(nextPrint);
}

void loop() {
  if ((sensor.check() == MyLD2410::Response::DATA) && (millis() > nextPrint)) {
    nextPrint = millis() + printEvery;
    printData();
  }
}
