#include "sd_functions.h"
#include "display.h"
#include "espNowFunctions.h"
// #include "credentials.h"

extern Adafruit_SSD1306 display;
//Define Global Strings

char* ssid = nullptr;
char* password = nullptr;

void initSd(){
    const int RETRY_DELAY = 1000;  // Delay between retries in milliseconds

    while (!SD.begin(SD_CS_PIN)) {
        display.clearDisplay();
        display.setCursor(0, 0);
        display.print("SD Init Failed!");
        display.print("\nRetry ");
        display.print("/");
        display.display();
        
        delay(RETRY_DELAY);
    }

    display.clearDisplay();
    display.print("SD Card Ready!");
    display.display();
}

void getWifiData(){
    if (readWiFiCredentials("/wifi.txt")) {
        // Serial.println("Wi-Fi credentials loaded successfully:");
        // Serial.print("SSID: ");
        Serial.println(ssid);
        // Serial.print("Password: ");
        Serial.println(password);
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
int getNextFileNumber(const String& userID) {
    File dir = SD.open("/UPLOAD_TO_FIRESTORE");
    if (!dir) {
        Serial.println("Failed to open directory");
        return 1; // Start with 1 if directory doesn't exist
    }

    int maxNumber = 0;
    String baseFileName = userID;
    
    File entry = dir.openNextFile();
    while (entry) {
        String fileName = entry.name();
        if (fileName.startsWith(userID)) {
            // Extract number from filename (if any)
            int underscorePos = fileName.lastIndexOf('_');
            if (underscorePos != -1) {
                String numStr = fileName.substring(underscorePos + 1);
                numStr = numStr.substring(0, numStr.lastIndexOf('.')); // Remove .txt
                int num = numStr.toInt();
                maxNumber = max(maxNumber, num);
            }
        }
        entry.close();
        entry = dir.openNextFile();
    }
    dir.close();
    return maxNumber + 1;
}

// Modified save function
bool saveSessionToSD(const String& userID,  
                    const std::vector<String>& receivedData) {
  if (!SD.exists("/UPLOAD_TO_FIRESTORE")) {
        if (!SD.mkdir("/UPLOAD_TO_FIRESTORE")) {
            Serial.println("Failed to create directory");
            return false;
        }
    }

    String fullPath = String("/UPLOAD_TO_FIRESTORE/") + userID+ ".txt";
    
    // Open file with FILE_WRITE flag for writing
    File file = SD.open(fullPath, FILE_WRITE);  // Using FILE_WRITE instead of 'r'
    if (!file) {
        Serial.println("Failed to open file for writing");
        return false;
    }

    
    // Write each element
    for (const String& data : receivedData) {
        file.println(data);
    }
    
    file.close();
    return true;
}

void  processBackupFiles() {
    File dir = SD.open("/UPLOAD_TO_FIRESTORE");
    if (!dir) {
        Serial.println("Failed to open UPLOAD_TO_FIRESTORE directory");
        return ;
    }

    bool anyFileProcessed = false;
    File entry = dir.openNextFile();
    String fullPath ;
    while (entry) {
        String fileName = entry.name();
        // Check if it's a .txt file
        if(!fileName.startsWith("._")){
          Serial.print("Processing file: ");
          Serial.println(fileName);
          
          // Close the file entry before processing to avoid conflicts
          entry.close();
          // Get full path
          fullPath = "/UPLOAD_TO_FIRESTORE/" + fileName;
          Serial.print("processed file=");
          Serial.println(fullPath);
          // Call your foo function here
          //foo(fullPath);  // You'll implement this function
          std::vector<String> commitedVec=readFileToVector(fullPath.c_str());
          updateFinalData(commitedVec);
          // Get next file
        }
        entry = dir.openNextFile();
        deleteFileFromSD(fullPath.c_str());
    }

    dir.close();
    
    if (!anyFileProcessed) {
        Serial.println("No .txt files found in UPLOAD_TO_FIRESTORE");
    }
    
    return ;
}


std::vector<String> readFileToVector(const char* filePath) {
    std::vector<String> lines;
    
    File file = SD.open(filePath, FILE_READ);
    if (!file) {
        Serial.print("Failed to open file: ");
        Serial.println(filePath);
        return lines;  // Return empty vector if file can't be opened
    }

    // Read file line by line
    while (file.available()) {
        String line = file.readStringUntil('\n');
        line.trim();  // Remove any whitespace and newline characters
        if (line.length() > 0) {  // Only add non-empty lines
            lines.push_back(line);
        }
    }

    file.close();

    // Optional: Print debug information
    Serial.print("Read ");
    Serial.print(lines.size());
    Serial.print(" lines from file: ");
    Serial.println(filePath);

    return lines;
}

bool deleteFileFromSD(const char* fileName) {
    // Construct the full path to the file
    String fullPath =  fileName;
    
    // Check if file exists before attempting to delete
    if (!SD.exists(fullPath)) {
        Serial.println("File does not exist: " + fullPath);
        return false;
    }
    
    // Attempt to delete the file
    if (SD.remove(fullPath)) {
        Serial.println("Successfully deleted file: " + fullPath);
        return true;
    } else {
        Serial.println("Failed to delete file: " + fullPath);
        return false;
    }
}