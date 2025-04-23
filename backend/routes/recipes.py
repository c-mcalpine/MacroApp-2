import pandas as pd
from flask import Blueprint, jsonify
from services.data_loader import DataLoader

recipes_bp = Blueprint("recipes", __name__)
data_loader = DataLoader()

@recipes_bp.route("/recipes", methods=["GET"])
def get_recipes():
    print(data_loader.recipes)  # <--- log it out
    return jsonify(data_loader.recipes)

@recipes_bp.route("/recipe/<string:recipe_id>", methods=["GET"])
def get_recipe(recipe_id):
    recipe_details = data_loader.get_recipe_by_id(recipe_id)
    if not recipe_details:
        return jsonify({"error": "Recipe not found"}), 404
    return jsonify(recipe_details)

@recipes_bp.route("/recipes/filter", methods=["GET"])
def filter_recipes():
    """Filter recipes based on calculated ratios (e.g., Calories per Gram of Protein)"""
    df = data_loader.nutrition_df.pivot(index="recipe_id", columns="nutrient_name", values="value").reset_index()

    # Ensure values are numeric
    df["calories"] = pd.to_numeric(df["calories"], errors="coerce")
    df["protein"] = pd.to_numeric(df["protein"], errors="coerce")

    # Calculate Calories per Gram of Protein
    df["cal_per_protein"] = df["calories"] / df["protein"]

    # Sort by the best (lowest) calorie per gram of protein
    df = df.sort_values(by="cal_per_protein", ascending=True)

    return jsonify(df.to_dict(orient="records"))