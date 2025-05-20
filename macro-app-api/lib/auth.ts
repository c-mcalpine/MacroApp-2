import jwt from 'jsonwebtoken';
import { getUserByPhone, createUser } from './supabase';
import twilio from 'twilio';

if (!process.env.JWT_SECRET) {
  throw new Error('Missing JWT_SECRET');
}

const JWT_SECRET = process.env.JWT_SECRET;

interface TokenPayload {
  userId: string;
  username: string;
}

export function generateToken(userId: string, username: string): string {
  return jwt.sign(
    { userId, username },
    JWT_SECRET,
    { expiresIn: '30d' }
  );
}

export function verifyToken(token: string): TokenPayload {
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as TokenPayload;
    return {
      userId: decoded.userId,
      username: decoded.username
    };
  } catch (error) {
    console.error('JWT verification failed:', error);
    throw new Error('Invalid token');
  }
}

export async function sendOTP(phone: string) {
  try {
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

    if (!accountSid || !authToken || !verifyServiceSid) {
      throw new Error('Missing Twilio credentials');
    }

    console.log('Sending OTP with Twilio credentials:', {
      accountSid: accountSid ? 'present' : 'missing',
      authToken: authToken ? 'present' : 'missing',
      verifyServiceSid: verifyServiceSid ? 'present' : 'missing'
    });

    const client = twilio(accountSid, authToken);
    const verification = await client.verify.v2
      .services(verifyServiceSid)
      .verifications.create({ to: phone, channel: 'sms' });

    console.log('Twilio verification response:', verification);

    return {
      success: true,
      status: verification.status
    };
  } catch (error) {
    console.error('Error sending OTP:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to send OTP'
    };
  }
}

export async function authenticateUser(phone: string, otp: string, username?: string) {
  try {
    // Verify OTP with Twilio
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

    if (!accountSid || !authToken || !verifyServiceSid) {
      throw new Error('Missing Twilio credentials');
    }

    const client = twilio(accountSid, authToken);
    const verification = await client.verify.v2
      .services(verifyServiceSid)
      .verificationChecks.create({ to: phone, code: otp });

    if (verification.status !== 'approved') {
      throw new Error('Invalid OTP');
    }

    // Get or create user
    let user = await getUserByPhone(phone);
    if (!user && username) {
      user = await createUser(phone, username);
    }

    if (!user) {
      throw new Error('User not found and no username provided');
    }

    // Generate JWT token
    const token = generateToken(phone, user.username);

    return {
      success: true,
      token,
      user_id: phone,
      user_name: user.username
    };
  } catch (error) {
    console.error('Authentication error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Authentication failed'
    };
  }
} 