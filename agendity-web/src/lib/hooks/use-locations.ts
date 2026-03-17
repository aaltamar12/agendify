'use client';

import { useQuery } from '@tanstack/react-query';
import { get } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';

export interface LocationItem {
  code?: string;
  name: string;
}

interface LocationResponse {
  data: LocationItem[];
}

/**
 * Resolves a location value that might be a code ("CO") or a name ("Colombia")
 * to the matching code. Returns the original value if no match found.
 */
export function resolveToCode(
  value: string | null | undefined,
  items: LocationItem[] | undefined,
): string {
  if (!value || !items?.length) return value ?? '';
  // Already a code?
  const byCode = items.find((i) => i.code?.toUpperCase() === value.toUpperCase());
  if (byCode) return byCode.code!;
  // Try matching by name (case-insensitive, accent-insensitive)
  const normalize = (s: string) =>
    s.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  const norm = normalize(value);
  const byName = items.find((i) => normalize(i.name) === norm);
  return byName?.code ?? value;
}

export function useCountries() {
  return useQuery({
    queryKey: ['locations', 'countries'],
    queryFn: () => get<LocationResponse>(ENDPOINTS.LOCATIONS.countries),
    staleTime: Infinity,
  });
}

export function useStates(country: string) {
  return useQuery({
    queryKey: ['locations', 'states', country],
    queryFn: () =>
      get<LocationResponse>(`${ENDPOINTS.LOCATIONS.states}?country=${country}`),
    enabled: !!country,
    staleTime: Infinity,
  });
}

export function useCities(country: string, state: string) {
  return useQuery({
    queryKey: ['locations', 'cities', country, state],
    queryFn: () =>
      get<LocationResponse>(
        `${ENDPOINTS.LOCATIONS.cities}?country=${country}&state=${state}`,
      ),
    enabled: !!country && !!state,
    staleTime: Infinity,
  });
}
