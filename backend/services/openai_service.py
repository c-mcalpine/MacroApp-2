from openai import OpenAI
from config import Config
import logging

client = OpenAI(api_key=Config.OPENAI_API_KEY)

class OpenAIService:
    @staticmethod
    def chat_with_ai(user_message, recipe_details):
        """Generate AI-powered suggestions for recipe modifications"""
        recipe_name = recipe_details.get('recipe', {}).get('name', 'Unknown Recipe')
        ingredients = recipe_details.get('ingredients', [])
        nutrition = recipe_details.get('nutrition', [])

        logging.info(f"Processing chat for recipe: {recipe_name}")

        prompt = f"""
        You are an AI chef assistant. A user is viewing the recipe "{recipe_name}" and has asked a question:
        
        "{user_message}"

        Here are the details of the recipe:
        - **Ingredients**: {", ".join([i.get('name', 'Unknown') for i in ingredients])}
        - **Nutritional Info**: {", ".join([f"{n.get('nutrient_name', 'Unknown')}: {n.get('value', 'N/A')} {n.get('unit', '')}" for n in nutrition])}

        Provide **clear, concise** answers. If they ask for modifications, suggest **healthy or meal-prep friendly** options. Only respond about this recipe.
        """

        try:
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": "You are an expert meal-prep AI assistant."},
                    {"role": "user", "content": prompt}
                ]
            )
            return response.choices[0].message.content
        except Exception as e:
            logging.error(f"OpenAI API call failed: {e}")
            return "Sorry, I couldn't process your request. Please try again."