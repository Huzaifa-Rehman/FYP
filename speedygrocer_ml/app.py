from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import numpy as np
from datetime import datetime

app = Flask(__name__)
CORS(app) # Allow Flutter to call this API without CORS errors

# Load trained model
with open('model.pkl', 'rb') as f:
    saved = pickle.load(f)
    model = saved['model']
    encoder = saved['encoder']

@app.route('/')
def home():
    return jsonify({'status': 'SpeedyGrocer ML API is running!'})

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json() or {}
    products = data.get('products', [])
    vendor_id = data.get('vendorId', 'unknown')
    
    # If no products specified, predict for all known products
    if not products:
        products = encoder.classes_.tolist()

    day = datetime.now().weekday()  # 0=Monday, 6=Sunday

    predictions = {}
    for product in products:
        try:
            enc = encoder.transform([product])[0]
            pred = model.predict([[day, enc]])[0]
            predictions[product] = round(float(pred), 1)
        except:
            predictions[product] = 5.0  # default if unknown product

    return jsonify({
        'predictedDemand': predictions, # Matching Flutter's expected key
        'day_of_week': day,
        'status': 'success'
    })

# Stripe Test Key (should be set via environment variable)
import os
import stripe
stripe.api_key = os.environ.get("STRIPE_SECRET_KEY", "YOUR_STRIPE_TEST_KEY_HERE")

@app.route('/create-payment-intent', methods=['POST'])
def create_payment_intent():
    try:
        data = request.get_json()
        amount = data.get('amount', 100)
        currency = data.get('currency', 'pkr')

        # Create a PaymentIntent
        intent = stripe.PaymentIntent.create(
            amount=int(amount), # amount in cents
            currency=currency,
            payment_method_types=['card'],
        )
        return jsonify({
            'clientSecret': intent['client_secret']
        })
    except Exception as e:
        return jsonify(error=str(e)), 403

if __name__ == '__main__':
    app.run(debug=True, port=5000, host='0.0.0.0')
