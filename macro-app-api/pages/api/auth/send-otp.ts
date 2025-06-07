import { NextApiRequest, NextApiResponse } from 'next';
import { sendOTP } from '../../../lib/auth';
import { rateLimit } from '../../../lib/rate-limit';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
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
    if (process.env.NODE_ENV !== 'production') {
      console.log('Received OTP request:', {
        method: req.method,
        headers: req.headers,
        body: req.body
      });
    }

    const { phone_number } = req.body;
    if (process.env.NODE_ENV !== 'production') {
      console.log('Phone number:', phone_number);
    }

    if (!phone_number) {
      if (process.env.NODE_ENV !== 'production') {
        console.log('Missing phone number');
      }
      return res.status(400).json({
        success: false,
        error: 'Phone number is required'
      });
    }

    // Format phone number to ensure it starts with +
    const formattedPhone = phone_number.startsWith('+') ? phone_number : `+${phone_number}`;
    if (process.env.NODE_ENV !== 'production') {
      console.log('Formatted phone number:', formattedPhone);
    }

    const result = await sendOTP(formattedPhone);
    if (process.env.NODE_ENV !== 'production') {
      console.log('OTP send result:', result);
    }

    if (!result.success) {
      if (process.env.NODE_ENV !== 'production') {
        console.log('Failed to send OTP:', result.error);
      }
      return res.status(500).json({
        success: false,
        error: result.error
      });
    }

    return res.status(200).json({
      success: true,
      status: 'pending'
    });
  } catch (error) {
    console.error('Error in send-otp:', error);
    return res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Internal server error'
    });
  }
} 