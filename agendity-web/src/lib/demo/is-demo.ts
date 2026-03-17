// ============================================================
// Agendity — Minimal demo mode check (no side effects, no imports)
// ============================================================
// This file must have ZERO imports from the demo module tree.
// It is imported statically from app-providers.tsx and must not
// pull in any demo code.
// ============================================================

/**
 * Check if demo mode is active.
 * Safe to call anywhere — returns false on server.
 */
export function isDemoMode(): boolean {
  if (typeof window === 'undefined') return false;
  const enabled = process.env.NEXT_PUBLIC_DEMO_MODE === 'true';
  if (!enabled) return false;

  // Extra safety: in production, also require explicit allow flag
  if (process.env.NODE_ENV === 'production') {
    return process.env.NEXT_PUBLIC_DEMO_ALLOW_PRODUCTION === 'true';
  }

  return true;
}
