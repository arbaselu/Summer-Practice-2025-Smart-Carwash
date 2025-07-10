#include <SoftwareSerial.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

SoftwareSerial BT(10, 11);  // RX, TX
LiquidCrystal_I2C lcd(0x27, 16, 2); 

int redLed = 2;
int blueLed = 3;
int yellowLed = 4;
int greenLed = 5;
int whiteLed = 6;

String input = "";
bool running = false;
unsigned long timerStart = 0;
int duration = 0;
String programName = "";

String programe[] = {
  "Prespalare:",
  "Spuma activa:",
  "Clatire:",
  "Ceara lichida:",
  "Uscare finala:"
};

void setup() {
  Serial.begin(9600);
  BT.begin(9600);
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Asteptare...");

  pinMode(redLed, OUTPUT);
  pinMode(blueLed, OUTPUT);
  pinMode(yellowLed, OUTPUT);
  pinMode(greenLed, OUTPUT);
  pinMode(whiteLed, OUTPUT);
}

void loop() {
  if (BT.available()) {
    char c = BT.read();
    if (c == '\n') {
      processCommand(input);
      input = "";
    } else {
      input += c;
    }
  }

  if (running && millis() - timerStart < duration * 1000UL) {
    static unsigned long lastUpdate = 0;
    if (millis() - lastUpdate >= 1000) {
      lastUpdate = millis();
      int timeLeft = duration - (millis() - timerStart) / 1000;
      int min = timeLeft / 60;
      int sec = timeLeft % 60;

      // Actualizează LCD
      lcd.setCursor(0, 0);
      lcd.print(programName.substring(0, 16));
      lcd.setCursor(0, 1);
      lcd.print("Timp: ");
      if (min < 10) lcd.print("0");
      lcd.print(min);
      lcd.print(":");
      if (sec < 10) lcd.print("0");
      lcd.print(sec);
      lcd.print("   "); 
    }
  } else if (running) {
    stopAll();
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Finalizat...");
    delay(2000);
    lcd.clear();
    lcd.print("Asteptare...");
    
    running = false;
  }
}


void processCommand(String cmd) {
  if (cmd.startsWith("start|")) {
    int index1 = cmd.indexOf('|');
    int index2 = cmd.indexOf('|', index1 + 1);
    int progIndex = cmd.substring(index1 + 1, index2).toInt();
    duration = cmd.substring(index2 + 1).toInt();
    programName = programe[progIndex];

    lcd.clear();

    lcd.setCursor(0, 1);
    lcd.print(programName.substring(0, 16));
    
    startProgram(progIndex, duration);
  }
}

void startProgram(int index, int seconds) {
  stopAll();

  switch (index) {
    case 0: digitalWrite(redLed, HIGH); break;
    case 1: digitalWrite(blueLed, HIGH); break;
    case 2: digitalWrite(yellowLed, HIGH); break;
    case 3: digitalWrite(greenLed, HIGH); break;
    case 4: digitalWrite(whiteLed, HIGH); break;
  }

  timerStart = millis();
  running = true;
}

void stopAll() {
  digitalWrite(redLed, LOW);
  digitalWrite(blueLed, LOW);
  digitalWrite(yellowLed, LOW);
  digitalWrite(greenLed, LOW);
  digitalWrite(whiteLed, LOW);
}

