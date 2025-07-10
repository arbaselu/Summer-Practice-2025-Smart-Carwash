from flask import Flask, request, redirect, render_template
import mysql.connector



app = Flask(__name__)


valoare_selectata = {"tokens": None, "pret": 0}
uid_autorizat = {"status": None}


db_config = {
    "host": "localhost",
    "user": "root",
    "password": "",
    "database": "sistem_bancar"
}


#stare terminal PN532
scanare_pornita = {"status": False}

@app.route('/porneste_scanare', methods=['POST'])
def porneste_scanare():
    scanare_pornita["status"] = True
    return "ok"

@app.route('/scanare_status')
def scanare_status():
    return "start" if scanare_pornita["status"] else "asteapta"

@app.route('/reset_scanare')
def reset_scanare():
    scanare_pornita["status"] = False
    return "resetat"


#functii citire/scriere date
@app.route('/index')
def index():
    return render_template("index.html")

@app.route('/asteapta')
def asteapta():
    tokens = request.args.get('tokens', type=int)
    if not tokens:
        return redirect("/index")
    
    preturi = {1: 4, 3: 10, 7: 20, 10: 27}
    pret = preturi.get(tokens, 4)
    valoare_selectata["tokens"] = tokens
    valoare_selectata["pret"] = pret
    uid_autorizat["status"] = None  # Reset status

    return render_template("asteapta.html", tokens=tokens)

@app.route('/uid', methods=['POST'])
def primeste_uid():
    uid = request.form.get("uid", "").strip().upper()
    if not uid:
        return " UID lipsa!", 400

    tokens = valoare_selectata.get("tokens")
    pret = valoare_selectata.get("pret")

    if not tokens or pret is None:
        return " Nicio valoare selectata!", 400

    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        cursor.execute("SELECT sold FROM utilizatori WHERE uid = %s", (uid,))
        rezultat = cursor.fetchone()

        if rezultat:
            sold = rezultat[0]
            if sold >= pret:
                cursor.execute("UPDATE utilizatori SET sold = sold - %s WHERE uid = %s", (pret, uid))
                cursor.execute("UPDATE firma SET sold = sold + %s WHERE id = %s", (pret, 1))
                cursor.execute("INSERT INTO tranzactii (uid, suma, rezultat) VALUES (%s, %s, %s)", (uid, pret, 'autorizat'))

                conn.commit()
                uid_autorizat["status"] = "autorizat"
                print(f" Tranzactie reusita pentru {uid}")
                return "autorizat"
            else:
                cursor.execute("INSERT INTO tranzactii (uid, suma, rezultat) VALUES (%s, %s, %s)", (uid, pret, 'fonduri_insuficiente'))
                conn.commit()
                uid_autorizat["status"] = "respins"
                print(f" Fonduri insuficiente pentru {uid}")
                return "respins"
        else:
            cursor.execute("INSERT INTO tranzactii (uid, suma, rezultat) VALUES (%s, %s, %s)", (uid, pret, 'uid_inexistent'))
            conn.commit()
            uid_autorizat["status"] = "respins"
            print(f" UID necunoscut: {uid}")
            return "respins"

    except mysql.connector.Error as e:
        print("Eroare la baza de date:", e)
        return "eroare_db"
    finally:
        cursor.close()
        conn.close()

@app.route('/verifica')
def verifica_status():
    return uid_autorizat["status"] or "asteapta"

@app.route('/confirmare')
def confirmare():
    uid_autorizat["status"] = None  # Reset dupa confirmare
    tokens = valoare_selectata.get("tokens", 1)
    return render_template("confirmare.html", tokens=tokens)

@app.route('/refuz')
def refuz():
    uid_autorizat["status"] = None  # Reset dupa refuz
    return render_template("refuz.html")

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)