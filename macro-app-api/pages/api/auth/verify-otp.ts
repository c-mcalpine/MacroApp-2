import { NextApiRequest, NextApiResponse } from 'next';
import { authenticateUser } from '../../../lib/auth';
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
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Method not allowed' });
  }

  try {
    const { phone_number, otp, username } = req.body;
    if (process.env.NODE_ENV !== 'production') {
      console.log('Verifying OTP for:', { phone_number, otp, username });
    }

    if (!phone_number || !otp) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    const result = await authenticateUser(phone_number, otp, username);
    if (process.env.NODE_ENV !== 'production') {
      console.log('Authentication result:', result);
    }

    if (!result.success) {
      if ((result as any).code === 'need_username') {
        return res.status(200).json(result);
      }
      return res.status(401).json(result);
    }

    // Ensure all required fields are present in the response
    const response = {
      success: true,
      token: result.token,
      user_id: result.user_id,
      user_name: result.user_name || username || 'User'
    };

    return res.status(200).json(response);
  } catch (error) {
    console.error('Error verifying OTP:', error);
    return res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Internal server error'
    });
  }
} 