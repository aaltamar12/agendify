// ============================================================
// Agendity — Next.js middleware (route protection)
// ============================================================

import { NextResponse, type NextRequest } from 'next/server';

// Routes that don't require authentication
const PUBLIC_ROUTES = [
  '/',
  '/login',
  '/register',
  '/explore',
  '/referral',
  '/forgot-password',
  '/reset-password',
  '/terms',
  '/privacy',
];

// Prefixes for public dynamic routes
const PUBLIC_PREFIXES = [
  '/explore',
  '/employee/register',  // Employee invitation registration
  '/r/',                  // Referral redirect /r/CODE
  '/referral',            // Referral program pages
];

function isPublicRoute(pathname: string): boolean {
  // Exact matches
  if (PUBLIC_ROUTES.includes(pathname)) return true;

  // Public prefixes
  if (PUBLIC_PREFIXES.some((prefix) => pathname.startsWith(prefix))) return true;

  // Next.js internals and static files
  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname.includes('.')
  ) {
    return true;
  }

  // Public business pages: /[slug] and /[slug]/ticket/*
  // A slug is a single segment without "dashboard" or "onboarding"
  const segments = pathname.split('/').filter(Boolean);
  if (segments.length >= 1) {
    const firstSegment = segments[0];
    const isReserved = ['dashboard', 'employee', 'login', 'register', 'explore', 'forgot-password', 'reset-password'].includes(firstSegment);
    if (!isReserved) {
      // /[slug] or /[slug]/ticket/[code]
      if (segments.length === 1) return true;
      if (segments.length >= 2 && segments[1] === 'ticket') return true;
    }
  }

  return false;
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // If authenticated user visits /login or /register, redirect to their portal
  if (pathname === '/login' || pathname === '/register') {
    const authCookie = request.cookies.get('agendity-auth')?.value;
    if (authCookie) {
      try {
        const parsed = JSON.parse(authCookie);
        if (parsed?.state?.token) {
          const role = parsed?.state?.user?.role;
          const redirectUrl = role === 'employee' ? '/employee' : '/dashboard/agenda';
          return NextResponse.redirect(new URL(redirectUrl, request.url));
        }
      } catch {
        // Invalid cookie, let them through to login
      }
    }
    return NextResponse.next();
  }

  // Allow public routes
  if (isPublicRoute(pathname)) {
    return NextResponse.next();
  }

  // Check for auth token in cookies
  const token = request.cookies.get('agendity-auth')?.value;

  let hasToken = false;
  let onboardingCompleted = true;

  if (token) {
    try {
      const parsed = JSON.parse(token);
      hasToken = !!parsed?.state?.token;

      // Check if onboarding is completed from the persisted user data
      const user = parsed?.state?.user;
      if (user?.business_id) {
        // The onboarding_completed flag is on the business object
        // We check it from the cookie if available
        onboardingCompleted = parsed?.state?.onboardingCompleted !== false;
      }
    } catch {
      hasToken = false;
    }
  }

  // Protected routes: redirect to login if no token
  if (!hasToken) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('redirect', pathname);
    return NextResponse.redirect(loginUrl);
  }

  // If on dashboard but onboarding not completed, redirect to onboarding
  if (pathname.startsWith('/dashboard') && !onboardingCompleted) {
    return NextResponse.redirect(new URL('/dashboard/onboarding', request.url));
  }

  // If on onboarding but already completed, redirect to dashboard
  if (pathname.startsWith('/dashboard/onboarding') && onboardingCompleted) {
    return NextResponse.redirect(new URL('/dashboard/agenda', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    // Match all paths except static files and Next.js internals
    '/((?!_next/static|_next/image|favicon.ico|icons|manifest.json).*)',
  ],
};
