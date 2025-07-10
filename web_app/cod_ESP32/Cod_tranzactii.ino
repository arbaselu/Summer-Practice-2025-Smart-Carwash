#include <Wire.h>
#include <Adafruit_PN532.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <LiquidCrystal_I2C.h>

// Pines PN532 I2C
#define SDA_PIN 21
#define SCL_PIN 22
#define PN532_IRQ   (2)
#define PN532_RESET (3)
Adafruit_PN532 nfc(PN532_IRQ, PN532_RESET, &Wire);
LiquidCrystal_I2C lcd(0x27, 16, 2);

#define LED_VERDE 18
#define LED_ROSU  5
#define BUZZER    4


const char* ssid = "NAME";
const char* password = "pass";

const char* SERVER = "http://IPv4:5000";

void beep(int times = 1, int duration = 100, int delayTime = 100) {
  for (int i = 0; i < times; i++) {
    digitalWrite(BUZZER, HIGH);
    delay(duration);
    digitalWrite(BUZZER, LOW);
    delay(delayTime);
  }
}

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);

  pinMode(LED_VERDE, OUTPUT);
  pinMode(LED_ROSU, OUTPUT);
  pinMode(BUZZER, OUTPUT);

  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_ROSU, LOW);

  // LCD
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Conectare WiFi...");

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.println("Nu s-a conectat la WiFi");
  }

  lcd.clear();
  lcd.print("WiFi conectat!");
  delay(1000);

  nfc.begin();
  if (!nfc.getFirmwareVersion()) {
    Serial.println("PN532 nu este detectat.");
    lcd.clear();
    lcd.print("Eroare PN532");
    while (1);
  }

  nfc.SAMConfig();
  Serial.println("PN532 pregatit.");
  lcd.clear();
  lcd.print("Asteptare...");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(String(SERVER) + "/scanare_status");
    int httpCode = http.GET();
    String status = http.getString();
    http.end();

    if (status == "start") {
      Serial.println("Scanare activa");
      lcd.clear();
      lcd.print("Apropie card...");

      uint8_t uid[7];
      uint8_t uidLength;
      delay(2000);

      if (nfc.readPassiveTargetID(PN532_MIFARE_ISO14443A, uid, &uidLength)) {
        String uidStr = "";
        for (uint8_t i = 0; i < uidLength; i++) {
          if (uid[i] < 0x10) uidStr += "0";
          uidStr += String(uid[i], HEX);
        }
        uidStr.toUpperCase();

        Serial.print("UID detectat: ");
        Serial.println(uidStr);

        beep(1);
        delay(1000);

        // Trimite UID la server
        HTTPClient httpPost;
        httpPost.begin(String(SERVER) + "/uid");
        httpPost.addHeader("Content-Type", "application/x-www-form-urlencoded");
        String postData = "uid=" + uidStr;
        int respCode = httpPost.POST(postData);
        String raspuns = httpPost.getString();
        httpPost.end();
        lcd.clear();
        lcd.print("Procesare plata...");
        delay(2000);
        Serial.println("Răspuns server: " + raspuns);

        if (raspuns == "autorizat") {
          digitalWrite(LED_VERDE, HIGH);
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Plata acceptata");
          lcd.setCursor(0, 1);
          lcd.print("Multumim!");
          beep(1);
          delay(2000);
          digitalWrite(LED_VERDE, LOW);
        } else {
          digitalWrite(LED_ROSU, HIGH);
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Plata respinsa");
          lcd.setCursor(0, 1);
          lcd.print("Card invalid");
          beep(3);
          delay(2000);
          digitalWrite(LED_ROSU, LOW);
        }

        // Resetare scanare
        HTTPClient httpReset;
        httpReset.begin(String(SERVER) + "/reset_scanare");
        httpReset.GET();
        httpReset.end();

        lcd.clear();
        lcd.print("Asteptare...");
        delay(2000);
      }
    }
  }

  delay(500);
}
