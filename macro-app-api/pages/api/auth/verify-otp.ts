import { NextApiRequest, NextApiResponse } from 'next';
import { authenticateUser } from '../../../lib/auth';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { phone_number, otp, username } = req.body;

    if (!phone_number || !otp) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    const result = await authenticateUser(phone_number, otp, username);

    if (!result.success) {
      return res.status(401).json(result);
    }

    return res.status(200).json(result);
  } catch (error) {
    console.error('Error verifying OTP:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
} 