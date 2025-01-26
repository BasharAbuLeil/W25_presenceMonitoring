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
 *     "someKey": { "stringValue": "someValue" },
 *     ...
 *   }
 * }
 *
 * For simplicity, all fields here are set as strings. If you need numeric or
 * boolean values, adjust accordingly (e.g. integerValue, booleanValue).
 */
void buildFirestoreJson(FirebaseJson &json, const std::vector<FirebaseField> &fields) {
    for (const auto &field : fields) {
        // Example: "fields/userID/stringValue": "12345"
        String path = "fields/" + field.key + "/stringValue";
        json.set(path, field.value);
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
    //    Instead of assigning our own date/time string, we'll let Firestore 
    //    fill the 'date' field with server time via REQUEST_TIME.
    std::vector<FirebaseField> sessionFields = {
        {"userID", userID},
        {"date", "REQUEST_TIME"},  // Firestore will store a server timestamp
        {"duration", String(receivedData.size())},
        {"avgActivity", String(avgActivity, 2)}, // e.g. keep 2 decimal places
        {"color", String(color)}
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
            {"color", String(msg.col)},
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


/**
 * @brief Example usage of creating a session document and a subcollection document.
 */
// void exampleUsage() {
//     // Ensure Firestore is initialized before calling this function.
//     if (!initFirestore()) {
//         Serial.println("Firestore initialization failed. Cannot continue.");
//         return;
//     }

//     // Prepare fields for the session document
//     std::vector<FirebaseField> sessionFields{
//         {"userID", "654321"},
//         {"date", "SomeTimestampOrValue"},
//         {"duration", "30"},
//         {"avgActivity", "75.0"},
//         {"color", "blue"},
//         {"intensity", "80"},
//         {"relaxed", "false"}
//     };

//     // Create the session document (Firestore auto-generates a doc ID)
//     String newSessionDocName = createSessionDocument(sessionFields);
//     if (newSessionDocName.isEmpty()) {
//         Serial.println("Failed to create session document.");
//         return;
//     }

//     // Prepare fields for a subcollection document in "minuteLogs"
//     std::vector<FirebaseField> minuteFields{
//         {"minuteIndex", "0"},
//         {"color", "blue"},
//         {"intensity", "80"},
//         {"activity", "85.0"}
//     };

//     // Create the subcollection document
//     if (!createSubcollectionDocument(newSessionDocName, "minuteLogs", minuteFields)) {
//         Serial.println("Failed to create minuteLogs document.");
//         return;
//     }

//     Serial.println("Session doc and minuteLogs doc created successfully.");
// }
