from flask import Blueprint, request, jsonify
from twilio.rest import Client
from dotenv import load_dotenv
import os
import jwt
import datetime
import json

load_dotenv()

otp = Blueprint('otp', __name__)
twilio_sid = os.getenv("TWILIO_ACCOUNT_SID")
twilio_auth = os.getenv("TWILIO_AUTH_TOKEN")
twilio_verify_sid = os.getenv("TWILIO_VERIFY_SERVICE_SID")
jwt_secret = os.getenv("JWT_SECRET", "your-secret-key")

# Simple in-memory user storage (replace with database in production)
USERS_FILE = "data/users.json"

def load_users():
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, 'r') as f:
            return json.load(f)
    return {}

def save_users(users):
    os.makedirs(os.path.dirname(USERS_FILE), exist_ok=True)
    with open(USERS_FILE, 'w') as f:
        json.dump(users, f)

client = Client(twilio_sid, twilio_auth)

@otp.route("/auth/send-otp", methods=["POST"])
def send_otp():
    data = request.get_json()
    phone = data.get("phone_number")
    if not phone:
        return jsonify({"error": "Missing phone_number"}), 400

    try:
        verification = client.verify.v2.services(twilio_verify_sid).verifications.create(
            to=phone,
            channel="sms"
        )
        return jsonify({"status": verification.status}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@otp.route("/auth/verify-otp", methods=["POST"])
def verify_otp():
    data = request.get_json()
    phone = data.get("phone_number")
    code = data.get("otp_code")
    username = data.get("username")

    if not phone or not code:
        return jsonify({"error": "Missing phone_number or otp_code"}), 400

    try:
        verification_check = client.verify.v2.services(twilio_verify_sid).verification_checks.create(
            to=phone,
            code=code
        )
        if verification_check.status == "approved":
            # Load existing users
            users = load_users()
            
            # If username is provided, update or create user
            if username:
                users[phone] = {
                    "username": username,
                    "phone": phone,
                    "created_at": datetime.datetime.utcnow().isoformat()
                }
                save_users(users)
            else:
                # If no username provided, use existing or generate default
                if phone not in users:
                    users[phone] = {
                        "username": f"User_{phone[-4:]}",
                        "phone": phone,
                        "created_at": datetime.datetime.utcnow().isoformat()
                    }
                    save_users(users)
            
            # Generate JWT token
            token = jwt.encode({
                'user_id': phone,
                'phone': phone,
                'username': users[phone]["username"],
                'exp': datetime.datetime.utcnow() + datetime.timedelta(days=30)  # Extended to 30 days
            }, jwt_secret, algorithm='HS256')
            
            return jsonify({
                "success": True,
                "token": token,
                "user_id": phone,
                "user_name": users[phone]["username"]
            }), 200
        else:
            return jsonify({"success": False, "status": verification_check.status}), 401
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@otp.route("/auth/update-username", methods=["POST"])
def update_username():
    data = request.get_json()
    phone = data.get("phone_number")
    new_username = data.get("username")

    if not phone or not new_username:
        return jsonify({"error": "Missing phone_number or username"}), 400

    try:
        users = load_users()
        if phone in users:
            users[phone]["username"] = new_username
            save_users(users)
            
            # Generate new token with updated username
            token = jwt.encode({
                'user_id': phone,
                'phone': phone,
                'username': new_username,
                'exp': datetime.datetime.utcnow() + datetime.timedelta(days=30)
            }, jwt_secret, algorithm='HS256')
            
            return jsonify({
                "success": True,
                "token": token,
                "user_name": new_username
            }), 200
        else:
            return jsonify({"error": "User not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500
