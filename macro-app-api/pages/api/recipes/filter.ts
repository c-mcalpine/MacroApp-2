import { NextApiRequest, NextApiResponse } from 'next';
import { filterRecipesByCalorieProteinRatio } from '../../../lib/supabase';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const recipes = await filterRecipesByCalorieProteinRatio();
    return res.status(200).json({ success: true, recipes });
  } catch (error) {
    console.error('Error filtering recipes:', error);
    return res.status(500).json({ success: false, error: 'Internal server error' });
  }
}
