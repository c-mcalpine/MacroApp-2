from supabase import create_client, Client
from config import Config

supabase: Client = create_client(Config.SUPABASE_URL, Config.SUPABASE_KEY)


class DataLoader:
    def __init__(self):
        """Load Supabase tables into memory"""
        self.recipes = self._fetch("recipes")
        self.ingredients_library = self._fetch("ingredients_library")
        self.recipe_ingredients = self._fetch("recipe_ingredients_join_table")

        self.nutrient_library = self._fetch("nutrient_library")
        self.recipe_nutrition = self._fetch("recipe_nutrition_join_table")

        self.diet_plans = self._fetch("diet_plans")
        self.recipe_diet_plan = self._fetch("recipe_diet_plan_join_table")

        self.tags_library = self._fetch("tags_library")
        self.recipe_tags = self._fetch("recipe_tags_join_table")

        self.instructions = self._fetch("instructions")
        self.meal_prep_tips = self._fetch("meal_prep_tips")

    def _fetch(self, table):
        result = supabase.table(table).select("*").execute()
        print(f"Fetched from {table}: {result.data}")
        return result.data

    def get_recipe_by_id(self, recipe_id: str):
        """Return full recipe data using normalized structure"""
        recipe_id = int(recipe_id)
        recipe = next((r for r in self.recipes if r["recipe_id"] == recipe_id), None)
        if not recipe:
            return None

        # Resolve ingredients
        ingredient_map = {i["ingredient_id"]: i["name"] for i in self.ingredients_library}
        ingredients = [
            {
                **entry,
                "name": ingredient_map.get(entry["ingredient_id"], "Unknown")
            }
            for entry in self.recipe_ingredients
            if entry["recipe_id"] == recipe_id
        ]

        # Resolve nutrition
        nutrient_map = {n["nutrient_id"]: {"name": n["name"], "unit": n["unit"]} for n in self.nutrient_library}
        nutrition = [
            {
                **entry,
                "name": nutrient_map.get(entry["nutrient_id"], {}).get("name", "Unknown"),  # Ensure name is resolved
                "unit": nutrient_map.get(entry["nutrient_id"], {}).get("unit", ""),
                "value": entry.get("value", 0.0)  # Ensure value is not missing
            }
            for entry in self.recipe_nutrition
            if entry["recipe_id"] == recipe_id
        ]

        # Resolve diet plans
        diet_plan_map = {d["diet_plan_id"]: d["name"] for d in self.diet_plans}
        diet_plans = [
            {"diet_plan_id": entry["diet_plan_id"], "name": diet_plan_map.get(entry["diet_plan_id"])}
            for entry in self.recipe_diet_plan
            if entry["recipe_id"] == recipe_id
        ]

        # Resolve tags
        tag_map = {t["tag_id"]: t["tag_name"] for t in self.tags_library}  # Ensure tag_name is used
        tags = [
            {"tag_id": entry["tag_id"], "tag_name": tag_map.get(entry["tag_id"], "Unknown")}  # Use tag_name
            for entry in self.recipe_tags
            if entry["recipe_id"] == recipe_id
        ]

        return {
            "recipe": recipe,
            "ingredients": ingredients,
            "nutrition": nutrition,
            "diet_plans": diet_plans,
            "tags": tags,
            "instructions": [i for i in self.instructions if i["recipe_id"] == recipe_id],
            "meal_prep_tips": [m for m in self.meal_prep_tips if m["recipe_id"] == recipe_id]
        }
