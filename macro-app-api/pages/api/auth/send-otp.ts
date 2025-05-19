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
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { phone_number } = req.body;

    if (!phone_number || typeof phone_number !== 'string') {
      return res.status(400).json({ error: 'Valid phone number is required' });
    }

    const verification = await client.verify.v2
      .services(verifyServiceSid as string)
      .verifications.create({ to: phone_number, channel: 'sms' });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error sending OTP:', error);
    return res.status(500).json({ error: 'Failed to send OTP' });
  }
} 