import { NextApiRequest, NextApiResponse } from 'next';
import OpenAI from 'openai';
import { verifyToken } from '../../../lib/auth';
import { getRecipeById } from '../../../lib/supabase';

if (!process.env.OPENAI_API_KEY) {
  throw new Error('Missing OpenAI API key');
}

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const SYSTEM_PROMPT = `You are an expert meal-prep AI assistant focused on healthy cooking and nutrition. 
When responding to questions about recipes:
1. Focus on healthy modifications and substitutions
2. Consider meal-prep friendly options
3. Provide clear, concise answers
4. Only respond about the specific recipe being discussed
5. Include nutritional considerations
6. Suggest healthy ingredient alternatives
7. Consider portion control and meal planning
8. Emphasize balanced nutrition

Keep responses focused and practical. If asked about modifications, prioritize healthy and meal-prep friendly options.`;

type Message = {
  role: 'system' | 'user' | 'assistant';
  content: string;
};

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { token, recipe_id, message } = req.body;

    if (!token || !recipe_id || !message) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    // Verify JWT token
    const payload = verifyToken(token);

    // Get recipe details
    const recipe = await getRecipeById(recipe_id);
    if (!recipe) {
      return res.status(404).json({
        success: false,
        error: 'Recipe not found'
      });
    }

    // Format ingredients and nutrition info
    const ingredients = recipe.ingredients?.map((i: { name: string }) => i.name).join(', ') || 'No ingredients listed';
    const nutrition = recipe.nutritional_info ? 
      Object.entries(recipe.nutritional_info)
        .map(([key, value]) => `${key}: ${value}`)
        .join(', ') : 
      'No nutritional info available';

    const prompt = `
    A user is viewing the recipe "${recipe.name}" and has asked a question:
    
    "${message}"

    Here are the details of the recipe:
    - **Ingredients**: ${ingredients}
    - **Nutritional Info**: ${nutrition}
    - **Instructions**: ${recipe.instructions || 'No instructions available'}
    - **Cooking Time**: ${recipe.cooking_time || 'Not specified'}
    - **Difficulty**: ${recipe.difficulty || 'Not specified'}

    Provide clear, concise answers focused on healthy modifications and meal-prep friendly options. Only respond about this specific recipe.
    `;

    // Create chat completion
    const completion = await openai.chat.completions.create({
      model: "gpt-4",  // Using GPT-4 for better quality responses
      messages: [
        {
          role: "system",
          content: SYSTEM_PROMPT
        },
        {
          role: "user",
          content: prompt
        }
      ],
      max_tokens: 1000,
      temperature: 0.7,
      presence_penalty: 0.6,
      frequency_penalty: 0.3,
    });

    const response = completion.choices[0]?.message?.content;

    if (!response) {
      throw new Error('No response from OpenAI');
    }

    return res.status(200).json({
      success: true,
      response,
      conversation_id: completion.id
    });
  } catch (error) {
    console.error('Error in recipe chat:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
} 