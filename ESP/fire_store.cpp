// /**
//  * Based on code created by K. Suwatchai (Mobizt)
//  * https://github.com/mobizt/Firebase-ESP-Client/blob/main/examples/RTDB/DataChangesListener/Callback/Callback.ino
//  */

// #if defined(ESP32)
// #include <WiFi.h>
// #elif defined(ESP8266)
// #include <ESP8266WiFi.h>
// #endif

// #include "fire_store.h"

// // #include <~/Documents/Arduino/libraries/Firebase_ESP_Client.h>

// // Provide the token generation process info.
// // #include <addons/TokenHelper.h>

// // Provide the RTDB payload printing info and other helper functions.
// // #include <addons/RTDBHelper.h>

// // Define Firebase Data object
// FirebaseData stream;
// FirebaseData fbdo;

// FirebaseAuth auth;
// FirebaseConfig config;

// unsigned long sendDataPrevMillis = 0;

// int count = 0;

// volatile bool dataChanged = false;

// void streamCallback(FirebaseStream data)
// {
//   Serial.printf("sream path, %s\nevent path, %s\ndata type, %s\nevent type, %s\n\n",
//                 data.streamPath().c_str(),
//                 data.dataPath().c_str(),
//                 data.dataType().c_str(),
//                 data.eventType().c_str());
//   printResult(data); // see addons/RTDBHelper.h
//   Serial.println();

//   // This is the size of stream payload received (current and max value)
//   // Max payload size is the payload size under the stream path since the stream connected
//   // and read once and will not update until stream reconnection takes place.
//   // This max value will be zero as no payload received in case of ESP8266 which
//   // BearSSL reserved Rx buffer size is less than the actual stream payload.
//   Serial.printf("Received stream payload size: %d (Max. %d)\n\n", data.payloadLength(), data.maxPayloadLength());

//   // Due to limited of stack memory, do not perform any task that used large memory here especially starting connect to server.
//   // Just set this flag and check it status later.
//   dataChanged = true;
// }

// void streamTimeoutCallback(bool timeout)
// {
//   if (timeout)
//     Serial.println("stream timed out, resuming...\n");

//   if (!stream.httpConnected())
//     Serial.printf("error code: %d, reason: %s\n\n", stream.httpCode(), stream.errorReason().c_str());
// }
// void establishFireBaseConnection(){
//      /* Assign the api key (required) */
//   config.api_key = API_KEY;

//   /* Assign the user sign in credentials */
//   auth.user.email = USER_EMAIL;
//   auth.user.password = USER_PASSWORD;

//   /* Assign the RTDB URL (required) */
//   config.database_url = DATABASE_URL;

//   /* Assign the callback function for the long running token generation task */
//   config.token_status_callback = tokenStatusCallback; // see addons/TokenHelper.h

//   // Or use legacy authenticate method
//   // config.database_url = DATABASE_URL;
//   // config.signer.tokens.legacy_token = "<database secret>";

//   // To connect without auth in Test Mode, see Authentications/TestMode/TestMode.ino

//   Firebase.begin(&config, &auth);

//   Firebase.reconnectWiFi(true);
// }
    