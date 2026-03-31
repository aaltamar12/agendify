'use client';

import { useEffect } from 'react';
import { useSearchParams } from 'next/navigation';

const REF_KEY = 'agendity_ref_code';

/**
 * Captures ?ref= param from URL and stores it in localStorage.
 * This ensures the referral code persists even if the user navigates
 * around the landing before clicking "Empieza gratis".
 */
export function RefCapture() {
  const searchParams = useSearchParams();

  useEffect(() => {
    const ref = searchParams.get('ref');
    if (ref) {
      localStorage.setItem(REF_KEY, ref);
    }
  }, [searchParams]);

  return null;
}

/**
 * Get stored referral code from localStorage.
 */
export function getStoredRef(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(REF_KEY);
}
