// ============================================================
// Agendify — Demo mode entry point
// ============================================================
// This module is ONLY imported via dynamic import() when
// NEXT_PUBLIC_DEMO_MODE=true. It adds zero bytes to the
// production bundle otherwise.
// ============================================================

import apiClient from '@/lib/api/client';
import { useAuthStore } from '@/lib/stores/auth-store';
import { demoAdapter } from './adapter';
import { initStore, getStore } from './store';
import { logDemoWarning } from './safety';
import type { User } from '@/lib/api/types';

// Re-export for convenience (dynamic-imported contexts only)
export { isDemoMode } from './is-demo';

/**
 * Bootstrap demo mode:
 * 1. Seed in-memory store (or load from localStorage)
 * 2. Replace axios adapter so no HTTP leaves the browser
 * 3. Auto-login with the demo user
 */
export function setupDemoMode(): void {
  logDemoWarning();

  // 1. Initialize store with seed data (or restore from localStorage)
  initStore();

  // 2. Replace axios transport — ALL requests go through demoAdapter
  apiClient.defaults.adapter = demoAdapter;

  // 3. Auto-login: set auth state so the app thinks we're logged in
  const store = getStore();
  const demoUser: User = store.user;

  useAuthStore.setState({
    token: 'demo-jwt-token',
    refreshToken: 'demo-refresh-token',
    user: demoUser,
  });

  // Sync cookie for Next.js middleware
  if (typeof document !== 'undefined') {
    const cookieVal = encodeURIComponent(
      JSON.stringify({ state: { token: 'demo-jwt-token', user: demoUser } }),
    );
    document.cookie = `agendify-auth=${cookieVal};path=/;max-age=${60 * 60 * 24 * 30};samesite=lax`;
  }

  console.warn(
    '%c[DEMO MODE] Agendify está en modo demostración. Ninguna solicitud sale del navegador.',
    'color: #f97316; font-weight: bold; font-size: 14px;',
  );
}
