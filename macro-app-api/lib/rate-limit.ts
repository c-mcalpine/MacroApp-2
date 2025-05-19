import { Redis } from '@upstash/redis';
import type { NextApiRequest, NextApiResponse } from 'next';

if (!process.env.UPSTASH_REDIS_REST_URL || !process.env.UPSTASH_REDIS_REST_TOKEN) {
  throw new Error('Missing Upstash Redis credentials');
}

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

type RateLimitConfig = {
  maxRequests: number;
  windowSeconds: number;
};

const rateLimits: Record<string, RateLimitConfig> = {
  'auth': { maxRequests: 5, windowSeconds: 60 }, // 5 requests per minute for auth
  'chat': { maxRequests: 10, windowSeconds: 60 }, // 10 requests per minute for chat
  'search': { maxRequests: 30, windowSeconds: 60 }, // 30 requests per minute for search
  'default': { maxRequests: 20, windowSeconds: 60 }, // 20 requests per minute for everything else
};

export async function rateLimit(
  req: NextApiRequest,
  res: NextApiResponse,
  next: () => void
) {
  const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  const path = req.url?.split('/')[2] || 'default'; // Get the main path segment
  const config = rateLimits[path] || rateLimits.default;
  
  const key = `ratelimit:${path}:${ip}`;
  
  try {
    const requests = await redis.incr(key);
    
    if (requests === 1) {
      await redis.expire(key, config.windowSeconds);
    }
    
    if (requests > config.maxRequests) {
      console.error(`Rate limit exceeded for ${ip} on ${path}`);
      return res.status(429).json({
        error: 'Too many requests',
        retryAfter: config.windowSeconds
      });
    }
    
    next();
  } catch (error) {
    console.error('Rate limit error:', error);
    // If Redis fails, allow the request but log the error
    next();
  }
} 