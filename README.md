#Summer Practice 2025 - Smart Carwash

Acest proiect realizat in cadrul practicii de vara 2025 integreaza doua componente principale:
1.Un cititor de carduri NFC, modul PN532 ,placuta ESP32 ,led RGB, buzzer activ si LCD.Conectarea la o baza de date mySQL.
2.O aplicatie mobila cu Flutter Framework si Dart, conectata la o baza de date Firebase.Aplicatia se conecteaza prin Bluetooth la o placuta Arduino R3.

Ambele proiecte au fost gandite ca parte a unui sistem inteligent al unei spalatorii auto.

#Partea 1
Am creat un sistem de plata folosind un card NFC care emite un uid unic atunci cand este citit de modulul PN532.Am creat o baza de data cu ajutorul mySQL, in care am stocat uid urile, le am atribuit fiecaruia un nume de utilizator, dar si o suma de bani.
Din interfata web utilizatorul selecteaza un numar de jetoane, apoi se trimite catre terminal o cerere de plata si se asteapta scanarea unui card NFC.
Dupa ce uid ul cardului este identificat, din acel cont sunt retrasi banii aferenti tranzactiei si se transfera intr un alt tabel al bazei de date numit "cont firma".
Daca tranzactia a fost efectuata cu succes RGB ul se aprinde in culoarea verde si buzzer ul actioneaza o data, daca tranzactia este respinsa(in urma fondurilor insuficiente) ledul se aprinde in culoarea rosu si buzzer ul actioneaza de 3 ori.La citirea cardului, buzzer ul mai actioneaza o data.

#Partea 2
Aplicatia mobila permite conectarea printr-un modul Bluetooth HC-05 la o placuta Arduino R3 care are conectat un LCD pe care este afisat programul de spalare selectat din aplicatie de client, se poate urmari si timpul ramas pentru program.
Proiectul mai cuprinde si 5 leduri colorate, cate o culoare alocata pentru fiecare program de spalare.

Aplicatia mobila include urmatoarele functionalitati:

Autentificare:
-Login cu email si parola
-Autentificare cu Google
-Autentificare cu Facebook
-Roluri diferinte de user si admin

Un panou principal care cuprinde:
-nume utilizator
-nr. jetoane
-jurnal de activitati
-buton de ajutor


Control spalatorie auto din tabul Wash:
-selectarea tipului de spalare
-conectarea prin Bluetooth la microcontroller
-trimitere comenzi catre Arduino pentru activare

Sistem de Tichete (Help Center):
-utilizatorul poate trimite un tichet de suport
-mesajele se salveaza in Firebase si sunt vizibile de admin
-adminul si clientul pot conversa in timp real
-afisare timp scurs de la deschiderea tichetului („acum 5 min” etc.)
-posibilitatea de a compensa cu jetoane direct din panoul admin
-inchidere si redeschidere de tichete

Plata cu Stripe
-alegerea unui numar de jetoane si posibilitatea de a cumpara cu Stripe - plata este gestionata pe un server Flask


#Practica de Vara – 2025#
Facultatea de Automatica, Calculatoare și Electronica – Universitatea din Craiova
Student: Arbaselu Mario Ionut
Profesor coordonator: Hurezeanu Bogdan



