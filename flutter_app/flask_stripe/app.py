import firebase_admin
from flask import Flask, request,jsonify
import stripe

from firebase_admin import credentials, firestore
import os


app = Flask(__name__)

#Stripe
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_KEY")

#Firebase
cred = credentials.Certificate(os.getenv("FIREBASE_CREDENTIALS_PATH"))
firebase_admin.initialize_app(cred)
db = firestore.client()


#Creare payment 
@app.route("/create-payment-intent", methods=["POST"])
def create_payment():
    try:
        data = request.get_json()
        amount_ron = data.get("amountRon")
        tokens = data.get("tokens")
        uid = data.get("uid")

        if not amount_ron or not tokens or not uid:
            return jsonify({"error": "Date lipsă"}), 400

        intent = stripe.PaymentIntent.create(
            amount=amount_ron * 100, 
            currency="ron",
            metadata={"uid": uid, "tokens": str(tokens)}
        )
        return jsonify({"clientSecret": intent.client_secret})
    except Exception as e:
        return jsonify(error=str(e)), 400


#Webhook de la Stripe
@app.route('/stripe-webhook', methods=['POST'])
def stripe_webhook():
    payload = request.data
    sig_header = request.headers.get('Stripe-Signature')

    try:
        event = stripe.Webhook.construct_event(payload, sig_header, WEBHOOK_SECRET)
    except ValueError as e:

        return "Invalid payload", 400
    except stripe.error.SignatureVerificationError as e:

        return "Invalid signature", 400

    if event['type'] == 'payment_intent.succeeded':
        payment_intent = event['data']['object']
        metadata = payment_intent.get('metadata', {})
        uid = metadata.get('uid')
        tokens = metadata.get('tokens')

        try:
            tokens = int(tokens)
            user_ref = db.collection("utilizatori").document(uid)
            user_doc = user_ref.get()

            if user_doc.exists:
                user_ref.update({
                    "jetoane": firestore.Increment(tokens)
                })

        except Exception as e:
            print(f"Eroare la actualizare Firestore: {e}")
            return {}, 500
    return {}, 200

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)