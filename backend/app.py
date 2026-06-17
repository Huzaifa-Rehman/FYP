from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import hmac
import hashlib
import random
import json

app = Flask(__name__)
CORS(app)

# ───────── Safepay Configuration ─────────
SAFEPAY_API_KEY = "sec_04a628bf-111a-405f-a62d-449a91003b6d"
SAFEPAY_SECRET_KEY = "49a95417eb713631120d06c4b2a7e7ab8e6e3c2243a00b57255c6dae6f45ebb1"
SAFEPAY_BASE_URL = "https://sandbox.api.getsafepay.com"

# ───────── Helper: Generate Auth Header ─────────
def _safepay_headers():
    return {
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

# ───────── 1. Create Payment Session (Tracker Token) ─────────
@app.route('/create-payment', methods=['POST'])
def create_payment():
    """
    Creates a Safepay payment session and returns the tracker token.
    The Flutter app will use this token to open the Safepay checkout.
    """
    data = request.json or {}
    amount = data.get('amount', 0)
    order_id = data.get('orderId', 'order_unknown')

    try:
        payload = {
            "client": SAFEPAY_API_KEY,
            "amount": amount,
            "currency": "PKR",
            "environment": "sandbox",
        }

        response = requests.post(
            f"{SAFEPAY_BASE_URL}/order/v1/init",
            json=payload,
            headers=_safepay_headers(),
            timeout=15,
        )

        if response.status_code == 201 or response.status_code == 200:
            resp_data = response.json()
            tracker = resp_data.get("data", {}).get("token", "")
            return jsonify({
                "status": "success",
                "tracker": tracker,
                "orderId": order_id,
            }), 200
        else:
            print(f"Safepay Error ({response.status_code}): {response.text}")
            return jsonify({
                "status": "error",
                "message": f"Safepay returned {response.status_code}",
                "details": response.text,
            }), 500

    except Exception as e:
        print(f"Create Payment Error: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# ───────── 2. Generate Client Auth Token (TBT) ─────────
@app.route('/create-token', methods=['POST'])
def create_token():
    """
    Creates a time-based token (TBT) for the Safepay checkout component.
    """
    try:
        payload = {
            "client": SAFEPAY_API_KEY,
            "secret": SAFEPAY_SECRET_KEY,
        }

        response = requests.post(
            f"{SAFEPAY_BASE_URL}/client/passport/v1/token",
            json=payload,
            headers=_safepay_headers(),
            timeout=15,
        )

        if response.status_code == 200 or response.status_code == 201:
            resp_data = response.json()
            token = resp_data.get("data", {}).get("token", "")
            return jsonify({"status": "success", "tbt": token}), 200
        else:
            print(f"Token Error ({response.status_code}): {response.text}")
            return jsonify({
                "status": "error",
                "message": f"Safepay token endpoint returned {response.status_code}",
                "details": response.text,
            }), 500

    except Exception as e:
        print(f"Create Token Error: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# ───────── 3. Verify Payment Signature ─────────
@app.route('/verify-payment', methods=['POST'])
def verify_payment():
    """
    Verifies a Safepay payment by checking the signature
    returned after a successful checkout.
    """
    data = request.json or {}
    tracker = data.get('tracker', '')
    signature = data.get('signature', '')
    order_id = data.get('orderId', '')

    try:
        # Verify the signature using HMAC-SHA256
        expected_sig = hmac.new(
            SAFEPAY_SECRET_KEY.encode('utf-8'),
            tracker.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

        if hmac.compare_digest(expected_sig, signature):
            return jsonify({
                "status": "verified",
                "tracker": tracker,
                "orderId": order_id,
            }), 200
        else:
            return jsonify({
                "status": "invalid",
                "message": "Signature mismatch. Payment could not be verified.",
            }), 400

    except Exception as e:
        print(f"Verify Payment Error: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# ───────── 4. Process Refund (via Safepay Dashboard note) ─────────
@app.route('/refund', methods=['POST'])
def refund():
    """
    Safepay refunds are processed via the Merchant Dashboard.
    This endpoint logs the refund request and updates our Firestore
    record for tracking purposes. In production, integrate with Safepay
    refund API if available, or queue for manual dashboard processing.
    """
    data = request.json or {}
    order_id = data.get('orderId', '')
    amount = data.get('amount', 0)
    tracker = data.get('tracker', '')

    # Log the refund request
    print(f"Refund requested: Order={order_id}, Amount=Rs.{amount}, Tracker={tracker}")

    # In production: call Safepay refund API or mark for manual processing
    return jsonify({
        "status": "refund_queued",
        "orderId": order_id,
        "amount": amount,
        "message": "Refund has been queued for processing.",
    }), 200

# ───────── 5. ML Demand Prediction (Existing) ─────────
@app.route('/predict', methods=['POST'])
def predict_demand():
    """
    Mock ML Predictor API.
    In a real scenario, this would load a trained Scikit-Learn or TensorFlow model
    and predict demand based on historical sales data.
    """
    data = request.json or {}
    vendor_id = data.get('vendorId', 'unknown')
    
    # Simulating a Machine Learning model prediction
    predictions = {
        'Fresh Tomatoes': round(random.uniform(10.0, 25.0), 1),
        'Full Cream Milk': round(random.uniform(8.0, 30.0), 1),
        'White Bread': round(random.uniform(5.0, 20.0), 1),
        'Potato Chips': round(random.uniform(15.0, 40.0), 1),
    }
    
    return jsonify({
        'vendorId': vendor_id,
        'predictedDemand': predictions,
        'status': 'success'
    })

if __name__ == '__main__':
    # Run the app locally for testing
    app.run(host='0.0.0.0', port=5001, debug=True)
