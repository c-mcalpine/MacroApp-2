import { NextApiRequest, NextApiResponse } from 'next';
import { getAllRecipes } from '../../../lib/supabase';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const recipes = await getAllRecipes();

    return res.status(200).json({
      success: true,
      recipes
    });
  } catch (error) {
    console.error('Error fetching recipes:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
} 