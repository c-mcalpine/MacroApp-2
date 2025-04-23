import requests
import logging
from config import Config

class InstacartService:
    BASE_URL = "https://api.instacart.com/v2"

    @staticmethod
    def get_shopping_list(recipe_ingredients):
        """
        Generate a shopping list link for the given recipe ingredients.
        """
        try:
            headers = {
                "Authorization": f"Bearer {Config.INSTACART_API_KEY}",
                "Content-Type": "application/json"
            }
            payload = {
                "items": [
                    {"name": ingredient.get("name", ""), "quantity": ingredient.get("amount", 1)}
                    for ingredient in recipe_ingredients
                ]
            }
            logging.info(f"Instacart API Key: {Config.INSTACART_API_KEY}")  # Log the API key
            logging.info(f"Sending request to Instacart API with payload: {payload}")
            logging.info(f"Headers: {headers}")

            response = requests.post(
                f"{InstacartService.BASE_URL}/shopping_list",
                json=payload,
                headers=headers
            )
            logging.info(f"Instacart API response: {response.status_code}, {response.text}")

            response.raise_for_status()
            return response.json().get("shopping_list_url", "")
        except requests.exceptions.RequestException as e:
            logging.error(f"Request to Instacart API failed: {e}")
            return None
