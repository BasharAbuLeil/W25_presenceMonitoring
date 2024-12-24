#include "sd_functions.h"
#include "credentials.h"

//Define Global Strings
char* ssid = nullptr;
char* password = nullptr;

void initSd(){
    if(!SD.begin(SD_CS_PIN)) {
        Serial.println("Card Mount Failed!");
        while (true) {
          
        }
    }
}

void getWifiData(){
    if (readWiFiCredentials("/wifi.txt")) {
        Serial.println("Wi-Fi credentials loaded successfully:");
        Serial.print("SSID: ");
        Serial.println(ssid);
        Serial.print("Password: ");
        Serial.println(password);
        
        //Release memory
        // delete[] ssid;
        // delete[] password;
        // ssid = nullptr;
        // password = nullptr;
    } else {
        Serial.println("Failed to load Wi-Fi credentials.");
    }
}


bool readWiFiCredentials(const char* path) {
  File file = SD.open(path);
  if (!file) {
    Serial.println("Failed to open file for reading.");
    return false;
  }
  
  // Read the SSID (first line)
  if (file.available()) {
     String temp=file.readStringUntil('\n');
      temp.trim();
      ssid= new char[temp.length()+1];
     if(ssid == nullptr){
        Serial.println("Failed to allocate memory for SSID");
        file.close();
        return false;
      }
       temp.toCharArray(ssid, temp.length()+1);
    
  }else{
    Serial.println("No SSID found in the file");
     file.close();
    return false;
  }


  // Read the password (second line)
  if (file.available()) {
    String temp2 = file.readString();
    temp2.trim();
    password= new char[temp2.length()+1];
    if(password == nullptr){
        Serial.println("Failed to allocate memory for password");
        delete[] ssid;
        ssid = nullptr;
        file.close();
        return false;
    }
    temp2.toCharArray(password,temp2.length()+1);
  }else{
    Serial.println("No password found in the file");
    delete[] ssid;
    ssid= nullptr;
    file.close();
    return false;
  }

  file.close();
  // Validate that both SSID and password were read
  return true;
}
void saveWiFiCredentials(const char* path, const char* _ssid, const char* _password){
  File file = SD.open(path, FILE_WRITE);
    if (file) {
        file.println(_ssid);
        file.print(_password);
         file.close();
    Serial.println("Wi-Fi credentials saved successfully.");
    } else {
        Serial.println("Error creating or opening file");
    }
}