from flask import Blueprint, jsonify, request
from services.data_loader import DataLoader
from services.openai_service import OpenAIService

chat_bp = Blueprint("chat", __name__)
data_loader = DataLoader()

@chat_bp.route("/recipe/<int:recipe_id>/chat", methods=["POST"])
def recipe_chat(recipe_id):
    data = request.get_json()
    user_message = data.get("message", "")

    recipe_details = data_loader.get_recipe_by_id(recipe_id)
    if not recipe_details:
        return jsonify({"error": "Recipe not found"}), 404

    ai_response = OpenAIService.chat_with_ai(user_message, recipe_details)
    return jsonify({"response": ai_response})
