// ============================================================
// Agendity — Explore businesses hook (TanStack Query)
// ============================================================

import { useQuery } from '@tanstack/react-query';
import { get } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { Business, PaginatedResponse } from '@/lib/api/types';

interface ExploreParams {
  search?: string;
  city?: string;
  type?: string;
  page?: number;
}

interface CityOption {
  name: string;
  count: number;
}

export function useCities() {
  return useQuery({
    queryKey: ['cities'],
    queryFn: () =>
      get<{ data: CityOption[] }>('/api/v1/public/cities'),
    select: (res) => {
      // Defensive: ensure we always return an array regardless of
      // response shape (demo adapter vs real backend)
      if (Array.isArray(res)) return res;
      if (res && Array.isArray(res.data)) return res.data;
      return [];
    },
    staleTime: 5 * 60 * 1000, // Cache 5 min
  });
}

export function useExploreBusinesses(params: ExploreParams = {}) {
  return useQuery({
    queryKey: ['explore', params],
    queryFn: () =>
      get<PaginatedResponse<Business>>(ENDPOINTS.PUBLIC.explore, {
        params: {
          ...(params.search && { search: params.search }),
          ...(params.city && { city: params.city }),
          ...(params.type && { type: params.type }),
          ...(params.page && { page: params.page }),
        },
      }),
  });
}

export function useSearchSuggestions(query: string) {
  return useQuery({
    queryKey: ['explore-suggestions', query],
    queryFn: () =>
      get<PaginatedResponse<Business>>(ENDPOINTS.PUBLIC.explore, {
        params: { search: query, per_page: 5 },
      }),
    select: (res) => res.data,
    enabled: query.length >= 2,
    staleTime: 30_000,
  });
}
