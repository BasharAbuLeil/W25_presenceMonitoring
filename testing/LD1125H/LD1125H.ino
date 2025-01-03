const int motionPin = 27; // GPIO connected to the sensor's OUT pin

void setup() {
  Serial.begin(115200);
  pinMode(motionPin, INPUT);
}

void loop() {
  int sensorValue = digitalRead(motionPin);
  if (sensorValue == HIGH) {
    Serial.println("Motion detected!");
  } else {
    Serial.println("No motion.");
  }
  delay(500); // Adjust delay as needed
}