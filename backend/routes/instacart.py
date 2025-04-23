from flask import Blueprint, request, jsonify
from services.instacart_service import InstacartService
import logging

instacart_bp = Blueprint("instacart", __name__)

@instacart_bp.route("/instacart/shopping-list", methods=["POST"])
def generate_shopping_list():
    """
    API route to generate a shopping list link for the given recipe ingredients.
    """
    try:
        data = request.json
        logging.info(f"Received payload: {data}")  # Log the incoming payload

        ingredients = data.get("ingredients", [])
        if not ingredients:
            logging.error("No ingredients provided in the payload.")
            return jsonify({"error": "No ingredients provided"}), 400

        shopping_list_url = InstacartService.get_shopping_list(ingredients)
        if shopping_list_url:
            return jsonify({"shopping_list_url": shopping_list_url}), 200
        else:
            logging.error("Failed to generate shopping list URL.")
            return jsonify({"error": "Failed to generate shopping list. Please check your API key and permissions."}), 403
    except Exception as e:
        logging.error(f"Error in /instacart/shopping-list: {e}")
        return jsonify({"error": "Internal server error"}), 500
