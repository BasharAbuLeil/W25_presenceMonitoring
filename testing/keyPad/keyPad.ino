#include <Keypad.h>

// For a 3x4 keypad (3 columns, 4 rows)
const byte ROWS = 4; // four rows
const byte COLS = 3; // three columns

// Define the keymap for the keypad
char keys[ROWS][COLS] = {
  {'1', '2', '3'},
  {'4', '5', '6'},
  {'7', '8', '9'},
  {'*', '0', '#'}
};

// Connect the row pin numbers and column pin numbers to the Arduino
byte rowPins[ROWS] = {13, 12, 14, 27}; // R1, R2, R3, R4
byte colPins[COLS] = {26, 25, 33};     // C1, C2, C3

// Create the keypad object
Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

void setup() {
  Serial.begin(9600);
  delay(1000);
  Serial.println("3x4 Keypad Test");
  Serial.println("Press keys and see output on the Serial Monitor");
}

void loop() {
  char key = keypad.getKey();
  if (key) {
    Serial.print("Key Pressed: ");
    Serial.println(key);
  }
}