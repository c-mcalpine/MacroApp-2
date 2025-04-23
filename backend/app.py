from flask import Flask
from flask_cors import CORS
from routes.recipes import recipes_bp
from routes.chat import chat_bp
from routes.search import search_bp
from routes.instacart import instacart_bp
from routes.otp_routes import otp
import logging

# Configure logging to only show warnings and errors
logging.getLogger('werkzeug').setLevel(logging.WARNING)

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})  # Allow all origins for development

# Register blueprints
app.register_blueprint(recipes_bp)
app.register_blueprint(chat_bp)
app.register_blueprint(search_bp)
app.register_blueprint(instacart_bp, url_prefix="/api")  # Ensure '/api' prefix is correct
app.register_blueprint(otp)

if __name__ == "__main__":
    # Run with minimal output
    app.run(debug=False)
