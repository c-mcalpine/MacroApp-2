import { NextApiRequest, NextApiResponse } from 'next';
import { searchRecipes } from '../../lib/supabase';
import { rateLimit } from '../../lib/rate-limit';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  await new Promise<void>((resolve) => rateLimit(req, res, () => resolve()));
  if (res.headersSent) return;
  if (req.method !== 'GET') {
    return res.status(405).json({ success: false, error: 'Method not allowed' });
  }

  try {
    const { q, min_protein, min_carbs, min_fat, max_calories } = req.query;

    if (!q || typeof q !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Missing search query'
      });
    }

    const filters: Record<string, number> = {};
    if (min_protein) filters.min_protein = Number(min_protein);
    if (min_carbs) filters.min_carbs = Number(min_carbs);
    if (min_fat) filters.min_fat = Number(min_fat);
    if (max_calories) filters.max_calories = Number(max_calories);

    const recipes = await searchRecipes(q, filters);

    return res.status(200).json({
      success: true,
      recipes
    });
  } catch (error) {
    console.error('Error searching recipes:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
} 