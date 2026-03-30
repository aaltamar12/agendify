'use client';

import { useEffect } from 'react';
import { useCurrentBusiness } from '@/lib/hooks/use-business';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { useSiteConfig } from '@/lib/hooks/use-site-config';

declare global {
  interface Window {
    Tawk_API?: Partial<{
      maximize: () => void;
      minimize: () => void;
      toggle: () => void;
      setAttributes: (attrs: Record<string, string>, callback?: (error: unknown) => void) => void;
      onLoad: () => void;
      visitor: { name: string; email: string; phone: string };
    }>;
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
  const isConfigured = propertyId && propertyId !== '-';

  useEffect(() => {
    if (!isConfigured || !hasAccess || !business) return;

    // Don't load twice
    if (document.getElementById('tawkto-script')) return;

    // Load Tawk.to script
    const script = document.createElement('script');
    script.id = 'tawkto-script';
    script.async = true;
    script.src = `https://embed.tawk.to/${propertyId}`;
    script.charset = 'UTF-8';
    script.setAttribute('crossorigin', '*');

    window.Tawk_API = window.Tawk_API || {};
    window.Tawk_LoadStart = new Date();

    // Set visitor name before load
    window.Tawk_API.visitor = {
      name: business.name,
      email: business.email || '',
      phone: business.phone || '',
    };

    // Minimize widget on load (prevent auto-popup greeting)
    window.Tawk_API.onLoad = function() {
      try {
        window.Tawk_API?.minimize?.();
        window.Tawk_API?.setAttributes?.({
          'business-id': String(business.id),
          'business-name': business.name,
          'business-slug': business.slug,
          'business-type': business.business_type || '',
          'plan': planSlug,
          'email': business.email || '',
          'phone': business.phone || '',
        }, function(error: unknown) {
          if (error) console.warn('[Tawk.to] setAttributes error:', error);
        });
      } catch (e) {
        console.warn('[Tawk.to] onLoad error:', e);
      }
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
  if (window.Tawk_API && typeof window.Tawk_API.maximize === 'function') {
    window.Tawk_API.maximize();
  } else {
    // Widget not loaded yet — open WhatsApp as fallback
    const url = document.querySelector<HTMLAnchorElement>('a[href*="wa.me"]')?.href;
    if (url) window.open(url, '_blank');
  }
}
