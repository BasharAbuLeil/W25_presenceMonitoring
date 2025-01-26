#include "sd_functions.h"
#include "display.h"
// #include "credentials.h"

extern Adafruit_SSD1306 display;
//Define Global Strings

char* ssid = nullptr;
char* password = nullptr;

void initSd(){
    if(!SD.begin(SD_CS_PIN)) {
        display.clearDisplay();
        display.print("Card Mount Failed!");
        display.display();
        while (true) {
          
        }
    }
}

void getWifiData(){
    if (readWiFiCredentials("/wifi.txt")) {
        // Serial.println("Wi-Fi credentials loaded successfully:");
        // Serial.print("SSID: ");
        Serial.println(ssid);
        // Serial.print("Password: ");
        Serial.println(password);
        
        //Release memory
        // delete[] ssid;
        // delete[] password;
        // ssid = nullptr;
        // password = nullptr;
    } else {
        // Serial.println("Failed to load Wi-Fi credentials.");
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
        // Serial.println("Failed to allocate memory for SSID");
        file.close();
        return false;
      }
       temp.toCharArray(ssid, temp.length()+1);
    
  }else{
    // Serial.println("No SSID found in the file");
     file.close();
    return false;
  }


  // Read the password (second line)
  if (file.available()) {
    String temp2 = file.readString();
    temp2.trim();
    password= new char[temp2.length()+1];
    if(password == nullptr){
        // Serial.println("Failed to allocate memory for password");
        delete[] ssid;
        ssid = nullptr;
        file.close();
        return false;
    }
    temp2.toCharArray(password,temp2.length()+1);
  }else{
    // Serial.println("No password found in the file");
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
    // Serial.println("Wi-Fi credentials saved successfully.");
    } else {
        // Serial.println("Error creating or opening file");
    }
}




void readFireBaseCredentials(FirebaseData &fbdo,FirebaseAuth& auth,FirebaseConfig& config,String &projectId,String& dataBaseUrl){
  //config.api_key = API_KEY;
  // config.project_id = FIREBASE_PROJECT_ID; // 'project_id' is not a member in older library versions


  
  File myFile = SD.open("/fireBaseCreds.txt");
  const int numLines=5;
  if (myFile) {
    // Serial.println("Reading file:");

    // Read and print the specified number of lines (t)
    int linesRead = 0;
    while (myFile.available() && linesRead < numLines) {
      String line = readLine(myFile);  // Function to read a single line without \n
      Serial.println(line);      // Print the line without \n
      if(linesRead==0){
        projectId=line;
      }
      else if(linesRead==1){
        config.api_key=line;
      }
      else if(linesRead==2){
        dataBaseUrl=line;
      }
      else if(linesRead==3){
        auth.user.email = line;
      }
      else {
        auth.user.password = line;
      }
      linesRead++;
    }

    myFile.close();  // Close the file
  } else {
    // Serial.println("Error opening the file");
  }
}


String readLine(File& myFile) {
  String line = "";

  // Read characters until a newline or the end of the file
  while (myFile.available()) {
    char ch = myFile.read();  // Read the next byte

    // If the byte is a newline, stop reading
    if (ch == '\n') {
      break;  // Exit the loop when newline is encountered
    }

    // Otherwise, append the character to the line string
    line += ch;
  }

  return line;  // Return the line without the newline character
}