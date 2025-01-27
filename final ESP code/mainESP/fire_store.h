#ifndef FIRE_STORE_H_
#define FIRE_STORE_H_
#include <Firebase_ESP_Client.h>
#include "espNowFunctions.h"
struct FirebaseField {
    String key;
    String value;
    // For numeric fields, you could store as String and convert
};
bool initFirestore();

void uploadDataToFirestore(
    const String& userID,
    double avgActivity,
    int color,
    const std::vector<recivedMessage>& receivedData
);
String createSessionDocument(const std::vector<FirebaseField>& fields);
bool createSubcollectionDocument(const String& parentDocName,
                                 const String& subcollectionName,
                                 const std::vector<FirebaseField>& fields);
void exampleUsage();
String convertColor(int i);


#endif