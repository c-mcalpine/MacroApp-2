import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  // Only apply to API routes
  if (!request.nextUrl.pathname.startsWith('/api')) {
    return NextResponse.next();
  }

  const start = Date.now();
  const response = NextResponse.next();

  // Add response time header
  response.headers.set('X-Response-Time', `${Date.now() - start}ms`);

  // Log API requests in non-production environments
  if (process.env.NODE_ENV !== 'production') {
    console.log(`${request.method} ${request.nextUrl.pathname} - ${response.status}`);
  }

  return response;
}

export const config = {
  matcher: '/api/:path*',
}; 