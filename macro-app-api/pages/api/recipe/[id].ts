import { NextApiRequest, NextApiResponse } from 'next';
import { getRecipeById } from '../../../lib/supabase';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { id } = req.query;
    
    if (!id || typeof id !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Invalid recipe ID'
      });
    }

    const recipe = await getRecipeById(id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        error: 'Recipe not found'
      });
    }

    return res.status(200).json({
      success: true,
      recipe
    });
  } catch (error) {
    console.error('Error fetching recipe:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
} 