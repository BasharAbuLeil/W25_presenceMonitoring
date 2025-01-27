#include "fire_store.h"
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <vector>
#include "display.h" // Assuming your display.h is correctly set up
#include "SD_functions.h"
#include "espNowFunctions.h"


extern std::vector<recivedMessage> g_receivedData;
extern String id;        // user ID captured from mainESP

// Global Firebase objects (adjust as needed)
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
String projectId;
String dataBaseUrl;

/**
 * @brief Helper function to build Firestore JSON in the format:
 * {
 *   "fields": {
 *     "someKey": { "someType": "someValue" },
 *     ...
 *   }
 * }
 *
 */
void buildFirestoreJson(FirebaseJson &json, const std::vector<FirebaseField> &fields) {
    for (const auto &field : fields) {
        String path;

        // Handle different field types based on field name
        if (field.key == "duration" || field.key == "minuteIndex") {
            // Integer fields
            path = "fields/" + field.key + "/integerValue";
            json.set(path, field.value.toInt());
        } else if (field.key == "avgActivity" || field.key == "activity") {
            // Double/float fields
            path = "fields/" + field.key + "/doubleValue";
            json.set(path, field.value.toDouble());
        } else if (field.key == "date") {
            // Timestamp field - use "serverTimestamp" placeholder
            path = "fields/" + field.key + "/serverTimestampValue"; // Correct path for serverTimestamp
            json.set(path, FirebaseJson::JSON_NULL); // Value should be JSON null for serverTimestamp
        } else {
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

/**
 * @brief Create a session document in the "sessions" collection with a random Firestore-generated document ID.
 *
 * @param fields Vector of FirebaseField containing key-value pairs for the session document.
 * @return Full path ("name") of the created document on success, or an empty string on failure.
 */
String createSessionDocument(const std::vector<FirebaseField>& fields) {
    FirebaseJson json;
    buildFirestoreJson(json, fields);

    // Pass only the collection path so Firestore auto-generates a doc ID.
    String collectionPath = "sessions";

    if (Firebase.Firestore.createDocument(&fbdo, projectId, "(default)", collectionPath, json.raw())) {
        // Retrieve the "name" field from Firestore's response payload.
        String payload = fbdo.payload().c_str();
        Serial.println("Session creation payload: " + payload);

        FirebaseJsonData resultData;
        FirebaseJson payloadJson;
        payloadJson.setJsonData(payload);

        // "name" holds the full path to the newly created document.
        if (payloadJson.get(resultData, "name") && resultData.typeNum == FirebaseJson::JSON_STRING) {
            String docName = resultData.stringValue;
            Serial.println("Created session doc with name: " + docName);
            return docName;
        }
    } else {
        Serial.println("Failed to create session doc: " + fbdo.errorReason());
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
    //    Now the 'date' field will be populated with server timestamp.
    std::vector<FirebaseField> sessionFields = {
        {"userID", userID},
        {"date", "serverTimestamp"}, // Use "serverTimestamp" to get server time
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

    Serial.println("Firestore upload complete.");
}


String convertColor(int i) {
    if (i == 1)
        return "red";
    else if (i == 2)
        return "green";
    return "blue";
}
