import { useQuery } from '@tanstack/react-query';
import { get } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse } from '@/lib/api/types';

export interface SiteConfigData {
  support_email: string | null;
  support_whatsapp: string | null;
  support_whatsapp_url: string | null;
  payment_nequi: string | null;
  payment_bancolombia: string | null;
  payment_daviplata: string | null;
  company_name: string;
  default_trial_days: number;
  referral_trial_days: number;
  tawkto_property_id: string | null;
}

/**
 * Fetches platform configuration (contact info, payment data) from the public API.
 * Cached for 1 hour since this rarely changes.
 */
export function useSiteConfig() {
  return useQuery({
    queryKey: ['site-config'],
    queryFn: () => get<ApiResponse<SiteConfigData>>(ENDPOINTS.PUBLIC.siteConfig),
    select: (res) => res.data,
    staleTime: 60 * 60 * 1000, // 1 hour
  });
}
