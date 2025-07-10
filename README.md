# Summer Practice 2025 - Smart Carwash
Acest proiect realizat în cadrul practicii de vară 2025 integrează două componente principale:

1. Un cititor de carduri NFC (modul PN532), plăcuță ESP32, LED RGB, buzzer activ și LCD. Conectarea la o bază de date MySQL.
2. O aplicație mobilă cu Flutter Framework și Dart, conectată la o bază de date Firebase. Aplicația se conectează prin Bluetooth la o plăcuță Arduino R3.

Ambele proiecte au fost gândite ca parte a unui sistem inteligent al unei spălătorii auto.


# Partea 1 – Sistem de plată cu NFC

Am creat un sistem de plată folosind un card NFC care emite un UID unic atunci când este citit de modulul PN532.

- Am creat o bază de date MySQL, în care am stocat UID-urile.
- Fiecărui UID i-am atribuit un nume de utilizator și o sumă de bani.
- Din interfața web, utilizatorul selectează un număr de jetoane, apoi se trimite către terminal o cerere de plată și se așteaptă scanarea unui card NFC.
- După identificarea UID-ului, din acel cont sunt retrași banii aferenți tranzacției și se transferă într-un alt tabel numit cont_firma.

Feedback vizual:
- Dacă tranzacția este efectuată cu succes, LED-ul RGB se aprinde verde și buzzer-ul acționează o dată.
- Dacă **tranzacția este respinsă (fonduri insuficiente), LED-ul se aprinde roșu și buzzer-ul acționează de 3 ori.
- La fiecare citire de card, buzzer-ul acționează o dată.



# Partea 2 – Aplicație mobilă

Aplicația permite conectarea printr-un modul Bluetooth HC-05 la o plăcuță Arduino R3, care are conectat un LCD.

Funcționalități:

- Afișarea programului de spălare selectat de client.
- Afișarea timpului rămas pentru program.
- 5 LED-uri colorate – câte un LED pentru fiecare program de spălare.

# Autentificare:

- Login cu email și parolă
- Autentificare cu Google
- Autentificare cu Facebook
- Roluri diferite: user / admin

# Panou principal:

- Nume utilizator
- Număr de jetoane
- Jurnal de activități
- Buton de ajutor

# Control spălătorie – Tabul *Wash*:

- Selectare tip spălare
- Conectare prin Bluetooth la Arduino
- Trimitere comenzi pentru activare program

# Sistem de Tichete:

- Utilizatorul poate trimite un tichet de suport
- Mesajele se salvează în Firebase și sunt vizibile de admin
- Conversație în timp real între client și admin
- Afișare timp scurs de la deschiderea tichetului (ex: „acum 5 minute”)
- Posibilitatea de a compensa cu jetoane din panoul admin
- Închidere și redeschidere tichete

# Plata cu Stripe:

- Alegerea unui număr de jetoane
- Plata este procesată pe un server Flask



# Practica de vară – 2025

**Facultatea de Automatică, Calculatoare și Electronică – Universitatea din Craiova**  
**Student:** Arbaselu Mario Ionuț  
**Profesor coordonator:** Hurezeanu Bogdan



