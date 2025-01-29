#include "fire_store.h"
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <vector>
#include "display.h" // Assuming your display.h is correctly set up
#include "SD_functions.h"
#include "espNowFunctions.h"


extern std::vector<recivedMessage> g_receivedData;
extern Adafruit_SSD1306 display;
extern String id;        // user ID captured from mainESP

// Global Firebase objects (adjust as needed)
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
String projectId;
String dataBaseUrl;

String extractCreateTime(const String& payload) {
    FirebaseJson payloadJson;
    FirebaseJsonData resultData;
    
    // Parse the payload into a FirebaseJson object
    payloadJson.setJsonData(payload);
    
    // Get the createTime field
    if (payloadJson.get(resultData, "createTime") && resultData.typeNum == FirebaseJson::JSON_STRING) {
        return resultData.stringValue;
    }
    
    return ""; // Return empty string if createTime not found or invalid
}
/**
 * @brief Helper function to build Firestore JSON in the format:
 * {
 *   "fields": {
 *     "someKey": { "stringValue": "someValue" },
 *     ...
 *   }
 * }
 *
 * For simplicity, all fields here are set as strings. If you need numeric or
 * boolean values, adjust accordiingly (e.g. integerValue, booleanValue).
 */
void buildFirestoreJson(FirebaseJson &json, const std::vector<FirebaseField> &fields) {
    for (const auto &field : fields) {
        String path;
        
        // Handle different field types based on field name
        if (field.key == "duration" || field.key == "minuteIndex") {
            // Integer fields
            path = "fields/" + field.key + "/integerValue";
            json.set(path, field.value.toInt());
        }
        else if (field.key == "avgActivity" || field.key == "activity") {
            // Double/float fields
            path = "fields/" + field.key + "/doubleValue";
            json.set(path, field.value.toDouble());
        }
        else {
            // String fields (userID, color, and any other fields)
            path = "fields/" + field.key + "/stringValue";
            json.set(path, field.value);
        }
    }
}
/**
 * @brief Initializes Firestore with credentials read from your custom function.
 *
 * @return true if Firebase is ready, false otherwise.
 */
bool initFirestore() {
    // Reads credentials from SD card or other storage. Make sure it's implemented correctly.
    readFireBaseCredentials(fbdo, auth, config, projectId, dataBaseUrl);

    config.token_status_callback = tokenStatusCallback;
    Firebase.begin(&config, &auth);

    if (Firebase.ready()) {
        Serial.println("Firestore is ready.");
        return true;
    } else {
        Serial.println("Failed to initialize Firestore.");
        return false;
    }
}

String createSessionDocument(const std::vector<FirebaseField>& fields) {
    FirebaseJson json;
    buildFirestoreJson(json, fields);

    // Pass only the collection path so Firestore auto-generates a doc ID.
    String collectionPath = "sessions";

    // Create the Firestore document
    if (Firebase.Firestore.createDocument(&fbdo, projectId, "(default)", collectionPath, json.raw())) {
        String payload = fbdo.payload().c_str();
        Serial.println("Session creation payload: " + payload);

        // Extract the creation time
        String creationTime = extractCreateTime(payload);
        Serial.println("Creation time: " + creationTime);

        FirebaseJsonData resultData;
        FirebaseJson payloadJson;
        payloadJson.setJsonData(payload);

        // Get the document name from Firestore response
        String docName;
        if (payloadJson.get(resultData, "name") && resultData.typeNum == FirebaseJson::JSON_STRING) {
            docName = resultData.stringValue;

            // Construct the update JSON with correct Firestore structure
            FirebaseJson updateJson;
            // Modified this part to use correct Firestore field structure
            updateJson.set("fields/date/timestampValue", creationTime);
            
            // Extract the relative document path from the full document name
            String relativeDocPath = docName.substring(docName.indexOf("/documents/") + 11);

            // Update the document with the creation time
            if (Firebase.Firestore.patchDocument(&fbdo, projectId, "(default)", relativeDocPath, updateJson.raw(), "date")) {
                Serial.println("Added creation time to document.");
                return docName;
            } else {
                Serial.println("Failed to add creation time: " + fbdo.errorReason());
                return docName; // Still return the document name even if patching fails
            }
        }
    } else {
        Serial.println("Failed to create session document: " + fbdo.errorReason());
    }
    return "";
}



/**
 * @brief Create a document in a subcollection (e.g., "minuteLogs") under a given parent document.
 *
 * @param parentDocName Full path of the parent doc, e.g., 
 *        "projects/<YOUR_PROJ>/databases/(default)/documents/sessions/<DOC_ID>"
 * @param subcollectionName For example, "minuteLogs"
 * @param fields Vector of FirebaseField for the new subcollection doc
 * @return true on success, false on failure.
 */
bool createSubcollectionDocument(const String& parentDocName,
                                 const String& subcollectionName,
                                 const std::vector<FirebaseField>& fields) {
    // Extract only the portion after "/documents/" so Firestore can build the correct path.
    String pathPrefix = "/documents/";
    int index = parentDocName.indexOf(pathPrefix);
    String docPath = parentDocName;
    if (index != -1) {
        docPath = parentDocName.substring(index + pathPrefix.length());
    }

    // Build the subcollection path, e.g. "sessions/<DOC_ID>/minuteLogs"
    String subcollectionPath = docPath + "/" + subcollectionName;

    FirebaseJson json;
    buildFirestoreJson(json, fields);

    // Create the new document in that subcollection path
    if (Firebase.Firestore.createDocument(&fbdo, projectId, "(default)", subcollectionPath, json.raw())) {
        Serial.println("Subcollection doc created: " + fbdo.payload());
        return true;
    } else {
        Serial.println("Failed to create subcollection doc: " + fbdo.errorReason());
        return false;
    }
}


void uploadDataToFirestore(
    const String& userID,
    double avgActivity,
    int color,
    const std::vector<recivedMessage>& receivedData
) {
    // 1) Ensure Firestore is initialized
    if (!initFirestore()) {
        Serial.println("Firestore initialization failed. Cannot continue.");
        return;
    }


    // 2) Build the main session document fields
    //    Instead of assigning our own date/time string, we'll let Firestore 
    //    fill the 'date' field with server time via REQUEST_TIME.
    std::vector<FirebaseField> sessionFields = {
        {"userID", userID},
        {"duration", String(receivedData.size())},
        {"avgActivity", String(avgActivity)}, // e.g. keep 2 decimal places
        {"color", convertColor(color)}
    };

    // 3) Create the session document in Firestore (auto ID)
    String newSessionDocName = createSessionDocument(sessionFields);
    if (newSessionDocName.isEmpty()) {
        Serial.println("Failed to create session document.");
        return;
    }
    Serial.println("Session doc created successfully.");
    // 4) For each entry in g_receivedData, create a subcollection document
    //    with the fields minuteIndex, color, activity.
    //    (You can add more fields as needed.)
    for (size_t i = 0; i < receivedData.size(); i++) {
        const recivedMessage& msg = receivedData[i];
        std::vector<FirebaseField> minuteFields = {
            {"minuteIndex", String(msg.packetNum)},
            {"color", convertColor(msg.col)},
            {"activity", String(msg.avg, 2)}
        };

        // Create the subcollection document under "minuteLogs"
        bool success = createSubcollectionDocument(newSessionDocName, "minuteLogs", minuteFields);
        if (!success) {
            Serial.printf("Failed to create minuteLogs document at index %d.\n", static_cast<int>(i));
        } else {
            Serial.printf("minuteLogs document created for index %d.\n", static_cast<int>(i));
        }
    }

  display.clearDisplay();
  display.setCursor(0, 0);
  display.println(" upload complete of id ");
  display.print(id.c_str());
  display.display();
  delay(2000);
}


String convertColor(int i){
  if(i==1)
     return "red";
  else if(i==2)
     return "green";
  return "blue";
}






