from flask import Blueprint, jsonify
from services.data_loader import DataLoader
import os

recipes_bp = Blueprint("recipes", __name__)
data_loader = DataLoader()

@recipes_bp.route("/recipes", methods=["GET"])
def get_recipes():
    if os.getenv("FLASK_ENV") != "production":
        print(data_loader.recipes)
    return jsonify(data_loader.recipes)

@recipes_bp.route("/recipe/<string:recipe_id>", methods=["GET"])
def get_recipe(recipe_id):
    recipe_details = data_loader.get_recipe_by_id(recipe_id)
    if not recipe_details:
        return jsonify({"error": "Recipe not found"}), 404
    return jsonify(recipe_details)

@recipes_bp.route("/recipes/filter", methods=["GET"])
def filter_recipes():
    """Filter recipes based on Calories per Gram of Protein."""

    # Build a lookup of nutrients for each recipe
    nutrition_map = {}
    for record in data_loader.nutrition_df:
        rid = record.get("recipe_id")
        name = record.get("nutrient_name", "").lower()
        value = float(record.get("value", 0))
        nutrition_map.setdefault(rid, {})[name] = value

    results = []
    for rid, nutrients in nutrition_map.items():
        calories = nutrients.get("calories")
        protein = nutrients.get("protein")
        if calories is None or protein in (None, 0):
            continue
        cal_per_protein = calories / protein
        results.append({
            "recipe_id": rid,
            "calories": calories,
            "protein": protein,
            "cal_per_protein": cal_per_protein,
        })

    results = sorted(results, key=lambda x: x["cal_per_protein"])
    return jsonify(results)
