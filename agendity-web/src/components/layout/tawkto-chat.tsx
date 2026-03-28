'use client';

import { useEffect } from 'react';
import { useCurrentBusiness } from '@/lib/hooks/use-business';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { useSiteConfig } from '@/lib/hooks/use-site-config';

declare global {
  interface Window {
    Tawk_API?: {
      maximize: () => void;
      minimize: () => void;
      toggle: () => void;
      setAttributes: (attrs: Record<string, string>, callback?: (error: unknown) => void) => void;
      onLoad?: () => void;
    };
    Tawk_LoadStart?: Date;
  }
}

/**
 * Loads the Tawk.to chat widget for businesses on Plan Inteligente or trial.
 * The property ID comes from SiteConfig (tawkto_property_id).
 * Pass business metadata so the admin sees who they're chatting with.
 */
export function TawktoChat() {
  const { data: business } = useCurrentBusiness();
  const { planSlug, isTrialing } = useCurrentSubscription();
  const { data: siteConfig } = useSiteConfig();

  const propertyId = siteConfig?.tawkto_property_id;
  const hasAccess = planSlug === 'inteligente' || isTrialing;

  useEffect(() => {
    if (!propertyId || !hasAccess || !business) return;

    // Don't load twice
    if (document.getElementById('tawkto-script')) return;

    // Load Tawk.to script
    const script = document.createElement('script');
    script.id = 'tawkto-script';
    script.async = true;
    script.src = `https://embed.tawk.to/${propertyId}/default`;
    script.charset = 'UTF-8';
    script.setAttribute('crossorigin', '*');

    window.Tawk_API = window.Tawk_API || {};
    window.Tawk_LoadStart = new Date();

    // Set business metadata when widget loads
    window.Tawk_API.onLoad = () => {
      window.Tawk_API?.setAttributes({
        name: business.name,
        email: business.email || '',
        business_slug: business.slug,
        plan: planSlug,
        phone: business.phone || '',
      });
    };

    document.head.appendChild(script);

    return () => {
      const existing = document.getElementById('tawkto-script');
      if (existing) existing.remove();
    };
  }, [propertyId, hasAccess, business, planSlug]);

  return null; // Widget renders itself
}

/**
 * Opens the Tawk.to chat widget programmatically.
 * Used by the help button.
 */
export function openTawktoChat() {
  window.Tawk_API?.maximize();
}
