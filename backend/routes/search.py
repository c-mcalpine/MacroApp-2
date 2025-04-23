from flask import Blueprint, jsonify, request
from services.data_loader import DataLoader

search_bp = Blueprint("search", __name__)
data_loader = DataLoader()

@search_bp.route("/search", methods=["GET"])
def search_recipes():
    """Advanced search filters"""
    min_protein = request.args.get("min_protein", type=float)
    max_carbs = request.args.get("max_carbs", type=float)

    filtered_recipes = []
    for _, row in data_loader.nutrition.iterrows():
        if min_protein and row["protein_g"] < min_protein:
            continue
        if max_carbs and row["carbs_g"] > max_carbs:
            continue
        filtered_recipes.append(row.to_dict())

    return jsonify(filtered_recipes)
