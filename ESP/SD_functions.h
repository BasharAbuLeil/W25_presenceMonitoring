#ifndef SD_FUNCTIONS_H
#define SD_FUNCTIONS_H
#include <SPI.h>
#include <SD.h>
#include <string>

#define SD_CS_PIN 5


extern char *ssid;
extern char*password;

void initSd();
void getWifiData();
bool readWiFiCredentials(const char* path);


#endif