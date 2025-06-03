from flask import Blueprint, jsonify, request
from services.data_loader import DataLoader

search_bp = Blueprint("search", __name__)
data_loader = DataLoader()

@search_bp.route("/search", methods=["GET"])
def search_recipes():
    """Advanced search filters"""
    min_protein = request.args.get("min_protein", type=float)
    max_carbs = request.args.get("max_carbs", type=float)

    # Build nutrient lookup similar to the filter_recipes endpoint
    nutrition_map = {}
    for rec in data_loader.nutrition_df:
        rid = rec.get("recipe_id")
        name = rec.get("nutrient_name", "").lower()
        value = float(rec.get("value", 0))
        nutrition_map.setdefault(rid, {})[name] = value

    filtered_recipes = []
    for rid, nutrients in nutrition_map.items():
        protein = nutrients.get("protein")
        carbs = nutrients.get("carbs")

        if min_protein and (protein is None or protein < min_protein):
            continue
        if max_carbs and (carbs is None or carbs > max_carbs):
            continue

        recipe_data = {"recipe_id": rid}
        recipe_data.update(nutrients)
        filtered_recipes.append(recipe_data)

    return jsonify(filtered_recipes)
