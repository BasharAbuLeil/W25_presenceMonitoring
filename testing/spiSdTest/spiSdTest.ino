#include <SPI.h>
#include <SD.h>

// Define the Chip Select pin for the SD card.
#define SD_CS_PIN 5

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("Initializing SD card...");

  // Initialize the SD card
  if (!SD.begin(SD_CS_PIN)) {
    Serial.println("Card Mount Failed!");
    while (true) {
      // Stay here if SD card mount failed
    }
  }

  uint8_t cardType = SD.cardType();
  if (cardType == CARD_NONE) {
    Serial.println("No SD card attached");
    while (true) {
      // Stay here if no card found
    }
  }

  Serial.print("SD Card Type: ");
  if (cardType == CARD_MMC) {
    Serial.println("MMC");
  } else if (cardType == CARD_SD) {
    Serial.println("SDSC");
  } else if (cardType == CARD_SDHC) {
    Serial.println("SDHC");
  } else {
    Serial.println("UNKNOWN");
  }

  uint64_t cardSize = SD.cardSize() / (1024 * 1024);
  Serial.print("SD Card Size: ");
  Serial.print(cardSize);
  Serial.println("MB");

  // Test writing to file
  testFileIO();
}

void loop() {
  // Nothing in loop. All tests are done in setup().
}

void testFileIO() {
  const char *filename = "/test.txt";

  // Remove the file if it exists, to start fresh
  if (SD.exists(filename)) {
    SD.remove(filename);
  }

  // Open file for writing
  File file = SD.open(filename, FILE_WRITE);
  if (!file) {
    Serial.println("Failed to open file for writing");
    return;
  }

  Serial.println("Writing to file...");
  file.println("Hello from ESP32!");
  file.println("This is a test line. from Ba");
  file.close();
  Serial.println("Write done.");

  // Now read the file back
  file = SD.open(filename);
  if (!file) {
    Serial.println("Failed to open file for reading");
    return;
  }

  Serial.println("Reading from file:");
  while (file.available()) {
    Serial.write(file.read());
  }
  file.close();
  Serial.println("\nRead done.");
}