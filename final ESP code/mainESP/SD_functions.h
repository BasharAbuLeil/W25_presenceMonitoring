#ifndef SD_FUNCTIONS_H
#define SD_FUNCTIONS_H
#include <SPI.h>
#include <SD.h>
#include <string>
#include <Firebase_ESP_Client.h>
#include <vector>

#define SD_CS_PIN 5


extern char *ssid;
extern char*password;

void initSd();
void getWifiData();
bool readWiFiCredentials(const char* path);
void readFireBaseCredentials(FirebaseData &fbdo,FirebaseAuth& auth,FirebaseConfig& config,String &projectId,String& dataBaseUrl);
String readLine(File& myFile);
bool deleteFileFromSD(const char* fileName);
bool saveSessionToSD(const String& userID,  const std::vector<String>& receivedData);
void processBackupFiles();
std::vector<String> readFileToVector(const char* filePath);
#endif