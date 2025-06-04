import { NextApiRequest, NextApiResponse } from 'next';
import { verifyToken } from '../../../lib/auth';
import { rateLimit } from '../../../lib/rate-limit';

if (!process.env.INSTACART_API_KEY) {
  throw new Error('Missing Instacart API key');
}

const INSTACART_API_URL = 'https://api.instacart.com/v2';
const STORE_ID = process.env.INSTACART_STORE_ID;

interface Ingredient {
  name: string;
  amount?: number;
  unit?: string;
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  await new Promise((resolve) => rateLimit(req, res, resolve));
  if (res.headersSent) return;
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { token, ingredients } = req.body;

    if (!token || !ingredients || !Array.isArray(ingredients)) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    // Verify JWT token
    const payload = verifyToken(token);

    // Create a new cart
    const cartResponse = await fetch(`${INSTACART_API_URL}/carts`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.INSTACART_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        store_id: STORE_ID
      })
    });

    if (!cartResponse.ok) {
      throw new Error('Failed to create Instacart cart');
    }

    const cart = await cartResponse.json();
    const cartId = cart.id;

    // Add items to cart
    const items = ingredients.map((ingredient: Ingredient) => ({
      name: ingredient.name,
      quantity: ingredient.amount || 1,
      unit: ingredient.unit || 'unit'
    }));

    const addItemsResponse = await fetch(`${INSTACART_API_URL}/carts/${cartId}/items`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.INSTACART_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ items })
    });

    if (!addItemsResponse.ok) {
      throw new Error('Failed to add items to cart');
    }

    // Get cart URL
    const cartUrlResponse = await fetch(`${INSTACART_API_URL}/carts/${cartId}/share`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.INSTACART_API_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    if (!cartUrlResponse.ok) {
      throw new Error('Failed to generate cart URL');
    }

    const { share_url } = await cartUrlResponse.json();

    return res.status(200).json({
      success: true,
      shopping_list_url: share_url
    });
  } catch (error) {
    console.error('Error generating shopping list:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
} 