import type { NextApiRequest, NextApiResponse } from 'next';
import twilio from 'twilio';

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

if (!accountSid || !authToken || !verifyServiceSid) {
  throw new Error('Missing Twilio credentials');
}

const client = twilio(accountSid, authToken);

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  console.log('Received request:', {
    method: req.method,
    headers: req.headers,
    body: req.body,
    url: req.url
  });

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
    console.log('Handling OPTIONS request');
    res.status(200).end();
    return;
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    console.log('Method not allowed:', req.method);
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const { phone_number } = req.body;
    console.log('Received phone number:', phone_number);

    if (!phone_number || typeof phone_number !== 'string') {
      console.log('Invalid phone number:', phone_number);
      res.status(400).json({ error: 'Valid phone number is required' });
      return;
    }

    // Format phone number for Twilio (ensure it starts with +)
    const formattedPhone = phone_number.startsWith('+') ? phone_number : `+${phone_number}`;
    console.log('Sending OTP to:', formattedPhone);

    const verification = await client.verify.v2
      .services(verifyServiceSid as string)
      .verifications.create({ to: formattedPhone, channel: 'sms' });

    console.log('Twilio verification response:', verification);
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error sending OTP:', error);
    // Send more detailed error information
    res.status(500).json({ 
      error: 'Failed to send OTP',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
} 