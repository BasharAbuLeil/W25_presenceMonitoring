
const int S0 =25;
const int S1=32;
const int S2=18;
const int S3=19;
const int sensorOut=27;

int frequency=0;

void setup() {
  pinMode(S0, OUTPUT);
  pinMode(S1, OUTPUT);
  pinMode(S2, OUTPUT);
  pinMode(S3, OUTPUT);  
  pinMode(sensorOut, INPUT);
     
  digitalWrite(S0,HIGH);
  digitalWrite(S1,HIGH);
  Serial.begin(115200);
}

void loop() {
  digitalWrite(S2,LOW);
  digitalWrite(S3,LOW);
  frequency = pulseIn(sensorOut, LOW);
  Serial.print("RED= ");
  Serial.print(frequency);
  Serial.print("  ");
  delay(500);

  digitalWrite(S2,HIGH);
  digitalWrite(S3,HIGH);
  frequency = pulseIn(sensorOut, LOW);
  Serial.print("GREEN= ");
  Serial.print(frequency);
  Serial.print("  ");
  delay(500);

  digitalWrite(S2,LOW);
  digitalWrite(S3,HIGH);
  frequency = pulseIn(sensorOut, LOW);
  Serial.print("BLUE= ");
  Serial.print(frequency);
  Serial.println("  ");
  delay(500);
}