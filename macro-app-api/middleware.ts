import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { rateLimit } from './lib/rate-limit';

export async function middleware(request: NextRequest) {
  // Only apply to API routes
  if (!request.nextUrl.pathname.startsWith('/api')) {
    return NextResponse.next();
  }

  const start = Date.now();
  const response = NextResponse.next();

  // Add response time header
  response.headers.set('X-Response-Time', `${Date.now() - start}ms`);

  // Log API requests
  console.log(`${request.method} ${request.nextUrl.pathname} - ${response.status}`);

  return response;
}

export const config = {
  matcher: '/api/:path*',
}; 