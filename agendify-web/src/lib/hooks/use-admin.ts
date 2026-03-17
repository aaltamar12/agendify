// ============================================================
// Agendify — Admin hooks (impersonation + business search)
// ============================================================

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import { useAuthStore } from '@/lib/stores/auth-store';
import { useImpersonationStore } from '@/lib/stores/impersonation-store';
import type { ApiResponse, Business, User } from '@/lib/api/types';

// --- Types ---

interface AdminBusiness {
  id: number;
  name: string;
  slug: string;
  business_type: string;
}

interface ImpersonateResponse {
  token: string;
  user: User;
  business: Business;
  impersonating: boolean;
  admin_token: string;
}

// --- Hooks ---

/** Search businesses (admin only). Shows 5 random when no search, filters on 2+ chars */
export function useAdminBusinesses(search: string) {
  return useQuery({
    queryKey: ['admin', 'businesses', search],
    queryFn: () =>
      get<ApiResponse<AdminBusiness[]>>(ENDPOINTS.ADMIN.businesses, {
        params: search.length >= 2 ? { search } : {},
      }),
    enabled: true,
  });
}

/** Start impersonating a business owner */
export function useImpersonate() {
  const { token, refreshToken, setAuth } = useAuthStore.getState();
  const { startImpersonation } = useImpersonationStore.getState();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (businessId: number) =>
      post<ApiResponse<ImpersonateResponse>>(ENDPOINTS.ADMIN.impersonate, {
        business_id: businessId,
      }),
    onSuccess: (response) => {
      const { token: newToken, user, business, admin_token } = response.data;

      // Save admin's original tokens before replacing with owner's
      startImpersonation(
        admin_token,
        refreshToken ?? '',
        business.name,
      );

      // Replace auth with the business owner's token
      // Use empty refresh token since impersonated sessions don't need refresh
      setAuth(newToken, '', user);

      // Clear all cached queries so dashboard reloads with new business data
      queryClient.clear();
    },
  });
}

/** Stop impersonation and restore admin session */
export function useStopImpersonation() {
  const queryClient = useQueryClient();

  return () => {
    const { adminToken, adminRefreshToken, stopImpersonation } =
      useImpersonationStore.getState();

    if (!adminToken) return;

    // Restore admin's original auth
    // We need to decode the admin token to get user info, but since
    // the /auth/me endpoint will return it, we do a simpler approach:
    // set the token and let the app refetch user data
    const { setAuth } = useAuthStore.getState();

    // Temporarily set just the token — the user will be refreshed from /auth/me
    setAuth(adminToken, adminRefreshToken ?? '', {
      id: 0,
      email: '',
      name: 'Admin',
      phone: null,
      role: 'admin',
      avatar_url: null,
      business_id: null,
      created_at: '',
      updated_at: '',
    });

    stopImpersonation();

    // Clear cached data and reload to get admin's own data
    queryClient.clear();
    window.location.href = '/dashboard/agenda';
  };
}
