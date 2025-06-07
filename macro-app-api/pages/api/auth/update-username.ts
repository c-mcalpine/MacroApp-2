import { NextApiRequest, NextApiResponse } from 'next';
import { verifyToken, generateToken } from '../../../lib/auth';
import { updateUsername } from '../../../lib/supabase';
import { rateLimit } from '../../../lib/rate-limit';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  await new Promise<void>((resolve) => rateLimit(req, res, () => resolve()));
  if (res.headersSent) return;
  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Method not allowed' });
  }

  try {
    const { token, username } = req.body;

    if (!token || !username) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    // Verify JWT token
    const payload = verifyToken(token);

    // Update username
    const result = await updateUsername(payload.userId, username);

    if (!result.success) {
      return res.status(400).json(result);
    }

    // Generate new token with updated username
    const newToken = generateToken(payload.userId, username);

    return res.status(200).json({
      success: true,
      token: newToken,
      user_id: payload.userId,
      user_name: username
    });
  } catch (error) {
    console.error('Error updating username:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
} 