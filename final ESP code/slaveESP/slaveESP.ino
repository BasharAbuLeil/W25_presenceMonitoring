#include <esp_now.h>
#include <WiFi.h>


/*
const int BUILT_IN_LED= 2;
const int S0 =25;
const int S1=32;
const int S2=18;
const int S3=19;
const int sensorOut=27;



int redMin = 70; // Red minimum value
int redMax = 229; // Red maximum value
int greenMin = 90; // Green minimum value
int greenMax = 310; // Green maximum value
int blueMin = 90; // Blue minimum value
int blueMax = 275; // Blue maximum value



int redPW = 0;
int greenPW = 0;
int bluePW = 0;


int redCount=0;
int greenCount=0;
int blueCount=0;

// Define a data structure for receiving session control
typedef struct struct_session {
    bool d;
} struct_session;

// Define a data structure for sending values
typedef struct struct_data {
    int colorNum;
} struct_data;

// Create structured objects
struct_session sessionData;
struct_data sendData;
const char* ssid = "Bashar";
const char* password = "toz12345";
esp_now_peer_info_t peerInfo;
// Global variables
bool session = false;
int timer=0;
// MAC Address of master ESP32
uint8_t masterMACAddress[] = {0x10, 0x06, 0x1C, 0x86, 0x1D, 0xB0};

// Callback function executed when data is received
void onDataReceive(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len) {
    memcpy(&sessionData, incomingData, sizeof(sessionData));
    session = sessionData.d;
    if(session){
      digitalWrite(BUILT_IN_LED, HIGH);
    }
    else{
      digitalWrite(BUILT_IN_LED, LOW);
    }
    Serial.println("Data received");
    Serial.print("Session status: ");
    Serial.println(session);
}

// Callback function executed when data is sent
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  redCount=blueCount=greenCount=0;
  Serial.print("\r\nLast Packet Send Status:\t");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}


int getRedPW() {
 
  // Set sensor to read Red only
  digitalWrite(S2,LOW);
  digitalWrite(S3,LOW);
  // Define integer to represent Pulse Width
  int PW;
  // Read the output Pulse Width
  PW = pulseIn(sensorOut, LOW);
  // Serial.print("Red=");
  // Serial.println(PW);
  // Return the value
  return PW;
 
}
 
 int getGreenPW() {
 
  // Set sensor to read Green only
  digitalWrite(S2,HIGH);
  digitalWrite(S3,HIGH);
  // Define integer to represent Pulse Width
  int PW;
  // Read the output Pulse Width
  PW = pulseIn(sensorOut, LOW);
  //Serial.print("Green=");
  // Serial.println(PW);
  // Return the value
  return PW;
 
}
 
 int getBluePW() {
 
  // Set sensor to read Blue only
  digitalWrite(S2,LOW);
  digitalWrite(S3,HIGH);
  // Define integer to represent Pulse Width
  int PW;
  // Read the output Pulse Width
  PW = pulseIn(sensorOut, LOW);
  // Serial.print("Blue=");
  // Serial.println(PW);
  // Return the value
  return PW;
 
}



void incDominantColor(int r,int g ,int b) {
  int red =r;
  int green=g;
  int blue =b;
  if (red >= green && red >= blue) {
    redCount++;
  }else if (green >= red && green >= blue) {
    greenCount++;
  }
  else{
    blueCount++;
  }
  Serial.println("redCount=");
  Serial.println(redCount);
  Serial.println("greenCount=");
  Serial.println(greenCount);
  Serial.println("blueCount=");
  Serial.println(blueCount);
}


void setSendMessageFileds(){
  Serial.println("eneter set message func");
  sendData.colorNum=getMaxCounter(redCount,greenCount,blueCount);
}
int getMaxCounter(int counter1, int counter2, int counter3) {
  if (counter1 >= counter2 && counter1 >= counter3) {
    return 1; // Counter 1 is the largest or tied
  } else if (counter2 >= counter1 && counter2 >= counter3) {
    return 2; // Counter 2 is the largest or tied
  } else {
    return 3; // Counter 3 is the largest
  }
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
  pinMode(S0, OUTPUT);
  pinMode(S1, OUTPUT);
  pinMode(S2, OUTPUT);
  pinMode(S3, OUTPUT);  
  pinMode(sensorOut, INPUT);
  pinMode(BUILT_IN_LED,OUTPUT);
     
  digitalWrite(S0,HIGH);
  digitalWrite(S1,LOW);
  
}

void loop() {
  if(session) {
    digitalWrite(BUILT_IN_LED, HIGH);
    redPW = getRedPW();
    // Map to value from 0-255
    int redValue = map(redPW, redMin,redMax,255,0);
    // Delay to stabilize sensor
    delay(250);
    
    // Read Green value
    greenPW = getGreenPW();
    // Map to value from 0-255
    int greenValue = map(greenPW, greenMin,greenMax,255,0);

    delay(250);
    // Read Blue value
    bluePW = getBluePW();
    // Map to value from 0-255
    int blueValue = map(bluePW, blueMin,blueMax,255,0);
    Serial.print("RedVal=");
    Serial.println(redValue); 
    Serial.print("greenVal=");
    Serial.println(greenValue);
    Serial.print("blueVal=");
    Serial.println(blueValue);  
    timer+=250;
    incDominantColor(redValue,greenValue,blueValue);
      // Send data to master
    if(timer==2000){
      setSendMessageFileds();
      esp_err_t result = esp_now_send(masterMACAddress, (uint8_t *)&sendData, sizeof(sendData));
        
      if (result == ESP_OK) {
        Serial.println("Sending confirmed");
      }else {
        Serial.println("Sending error");
      }
      timer=0;
    }
  }
  else {
    redCount=blueCount=greenCount=0;
  }
  delay(500);
}*/
#ifdef ESP32
#define sensorSerial Serial1
#define RX_PIN 16
#define TX_PIN 17
#define INDICATOR_PIN 2
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
double movingCounter=0;
double seconds=0;
const int BUILT_IN_LED= 2;
const int S0 =25;
const int S1=32;
const int S2=18;
const int S3=19;
const int sensorOut=27;



int redMin = 70; // Red minimum value
int redMax = 229; // Red maximum value
int greenMin = 90; // Green minimum value
int greenMax = 310; // Green maximum value
int blueMin = 90; // Blue minimum value
int blueMax = 275; // Blue maximum value



int redPW = 0;
int greenPW = 0;
int bluePW = 0;


int redCount=0;
int greenCount=0;
int blueCount=0;
int getRedPW() {
 
  // Set sensor to read Red only
  digitalWrite(S2,LOW);
  digitalWrite(S3,LOW);
  // Define integer to represent Pulse Width
  int PW;
  // Read the output Pulse Width
  PW = pulseIn(sensorOut, LOW);
  // Serial.print("Red=");
  // Serial.println(PW);
  // Return the value
  return PW;
 
}
 
 int getGreenPW() {
 
  // Set sensor to read Green only
  digitalWrite(S2,HIGH);
  digitalWrite(S3,HIGH);
  // Define integer to represent Pulse Width
  int PW;
  // Read the output Pulse Width
  PW = pulseIn(sensorOut, LOW);
  //Serial.print("Green=");
  // Serial.println(PW);
  // Return the value
  return PW;
 
}
 
 int getBluePW() {
 
  // Set sensor to read Blue only
  digitalWrite(S2,LOW);
  digitalWrite(S3,HIGH);
  // Define integer to represent Pulse Width
  int PW;
  // Read the output Pulse Width
  PW = pulseIn(sensorOut, LOW);
  // Serial.print("Blue=");
  // Serial.println(PW);
  // Return the value
  return PW;
 
}

void incDominantColor(int r,int g ,int b) {
  int red =r;
  int green=g;
  int blue =b;
  if (red >= green && red >= blue) {
    redCount++;
  }else if (green >= red && green >= blue) {
    greenCount++;
  }
  else{
    blueCount++;
  }
  Serial.println("redCount=");
  Serial.println(redCount);
  Serial.println("greenCount=");
  Serial.println(greenCount);
  Serial.println("blueCount=");
  Serial.println(blueCount);
}
void colorMeasure(){
  redPW = getRedPW();
  // Map to value from 0-255
  int redValue = map(redPW, redMin,redMax,255,0);
  // Delay to stabilize sensor
  delay(250);
  
  // Read Green value
  greenPW = getGreenPW();
  // Map to value from 0-255
  int greenValue = map(greenPW, greenMin,greenMax,255,0);
  delay(250);
  // Read Blue value
  bluePW = getBluePW();
  // Map to value from 0-255
  int blueValue = map(bluePW, blueMin,blueMax,255,0);
  Serial.print("RedVal=");
  Serial.println(redValue); 
  Serial.print("greenVal=");
  Serial.println(greenValue);
  Serial.print("blueVal=");
  Serial.println(blueValue);  
  incDominantColor(redValue,greenValue,blueValue);
}
void calcMovementPerc()
{
  Serial.print("moving percentage:");
  double movingPerc=movingCounter/seconds;
  movingPerc=movingPerc/0.8;
  if(movingPerc>1){
  Serial.print("1.00");
  }else{
    Serial.println(movingPerc);
  }    
  Serial.println();
  movingCounter=0;
  seconds=0;
}
int getMaxCounter(int counter1, int counter2, int counter3) {
  if (counter1 >= counter2 && counter1 >= counter3) {
    return 1; // Counter 1 is the largest or tied
  } else if (counter2 >= counter1 && counter2 >= counter3) {
    return 2; // Counter 2 is the largest or tied
  } else {
    return 3; // Counter 3 is the largest
  }
}


void printData() {
  //Serial.print(sensor.statusString());
  if (sensor.presenceDetected()) {

    // digitalWrite(INDICATOR_PIN, HIGH);

    // Serial.print(", distance: ");
    // Serial.print(sensor.detectedDistance());
    // Serial.print("cm");
    if (sensor.movingTargetDetected()) {
      if(seconds>=3){
        movingCounter++;
      }
      digitalWrite(INDICATOR_PIN, HIGH);
      Serial.print(" MOVING    = ");
      Serial.print(sensor.movingTargetSignal());
      Serial.print("@");
      Serial.print(sensor.movingTargetDistance());
      Serial.print("cm ");
      /*if (sensor.inEnhancedMode()) {
        Serial.print("\n signals->[");
        sensor.getMovingSignals().forEach(printValue);
        Serial.print(" ] thresholds:");
        sensor.getMovingThresholds().forEach(printValue);
      }*/
     Serial.println();
    }
    else{
      Serial.println("NO MOVEMENT");
      digitalWrite(INDICATOR_PIN,LOW);
    }
  } else {
    Serial.println("NO MOVEMENT");
    digitalWrite(INDICATOR_PIN, LOW);
  }
  Serial.println();
  seconds++;
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
  Serial.println(__FILE__);
  if (!sensor.begin()) {
    Serial.println("Failed to communicate with the sensor.");
    while (true)
      ;
  }

#ifdef ENHANCED_MODE
  sensor.enhancedMode();
#endif

  //color sensor part
  pinMode(S0, OUTPUT);
  pinMode(S1, OUTPUT);
  pinMode(S2, OUTPUT);
  pinMode(S3, OUTPUT);  
  pinMode(sensorOut, INPUT);
  digitalWrite(S0,HIGH);
  digitalWrite(S1,LOW);
}

void loop() {
  if ((sensor.check() == MyLD2410::Response::DATA) && (millis() > nextPrint)) {
    nextPrint = millis() + printEvery;
    printData();
    colorMeasure();
    if(seconds>=30){
      calcMovementPerc();
      int maxColor=getMaxCounter(redCount,greenCount,blueCount);
      Serial.println(maxColor);
      redCount=greenCount=blueCount=0;
    }
  }
}