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
            if not Config.INSTACART_API_KEY or Config.INSTACART_API_KEY == "your-default-api-key":
                logging.error("Instacart API key not configured")
                return None

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
            logging.info(f"Sending request to Instacart API with payload: {payload}")

            response = requests.post(
                f"{InstacartService.BASE_URL}/shopping_list",
                json=payload,
                headers=headers
            )
            logging.info(f"Instacart API response: {response.status_code}, {response.text}")

            if response.status_code == 401:
                logging.error("Invalid Instacart API key")
                return None
            elif response.status_code == 403:
                logging.error("Access denied by Instacart API")
                return None
            
            response.raise_for_status()
            shopping_list_url = response.json().get("shopping_list_url")
            if not shopping_list_url:
                logging.error("No shopping list URL in response")
                return None
                
            return shopping_list_url
        except requests.exceptions.RequestException as e:
            logging.error(f"Request to Instacart API failed: {e}")
            return None
        except Exception as e:
            logging.error(f"Unexpected error in get_shopping_list: {e}")
            return None
