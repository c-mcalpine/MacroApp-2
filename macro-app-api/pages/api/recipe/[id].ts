import { NextApiRequest, NextApiResponse } from 'next';
import { getRecipeById } from '../../../lib/supabase';
import { rateLimit } from '../../../lib/rate-limit';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  await new Promise<void>((resolve) => rateLimit(req, res, () => resolve()));
  if (res.headersSent) return;
  // Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization'
  );

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

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