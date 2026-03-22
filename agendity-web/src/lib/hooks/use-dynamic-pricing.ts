import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { get, post, put, del } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse } from '@/lib/api/types';

interface DynamicPricing {
  id: number;
  business_id: number;
  service_id: number | null;
  service_name: string | null;
  name: string;
  start_date: string;
  end_date: string;
  price_adjustment_type: 'percentage' | 'fixed';
  adjustment_mode: 'fixed_mode' | 'progressive_asc' | 'progressive_desc';
  adjustment_value: number | null;
  adjustment_start_value: number | null;
  adjustment_end_value: number | null;
  days_of_week: number[];
  status: 'suggested' | 'active' | 'rejected' | 'expired';
  suggested_by: 'system' | 'manual';
  suggestion_reason: string | null;
  analysis_data: Record<string, unknown>;
  created_at: string;
}

interface DynamicPricingPayload {
  name: string;
  service_id?: number | null;
  start_date: string;
  end_date: string;
  price_adjustment_type: string;
  adjustment_mode: string;
  adjustment_value?: number | null;
  adjustment_start_value?: number | null;
  adjustment_end_value?: number | null;
  days_of_week?: number[];
}

export function useDynamicPricings(status?: string) {
  return useQuery({
    queryKey: ['dynamic-pricing', status],
    queryFn: () =>
      get<ApiResponse<DynamicPricing[]>>(ENDPOINTS.DYNAMIC_PRICING.list, {
        params: status ? { status } : undefined,
      }),
    select: (res) => res.data,
  });
}

export function useCreateDynamicPricing() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: DynamicPricingPayload) =>
      post<ApiResponse<DynamicPricing>>(ENDPOINTS.DYNAMIC_PRICING.create, { dynamic_pricing: data }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['dynamic-pricing'] }),
  });
}

export function useUpdateDynamicPricing() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<DynamicPricingPayload> }) =>
      put<ApiResponse<DynamicPricing>>(ENDPOINTS.DYNAMIC_PRICING.update(id), { dynamic_pricing: data }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['dynamic-pricing'] }),
  });
}

export function useAcceptDynamicPricing() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) =>
      put<ApiResponse<DynamicPricing>>(ENDPOINTS.DYNAMIC_PRICING.accept(id), {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['dynamic-pricing'] }),
  });
}

export function useRejectDynamicPricing() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) =>
      put<ApiResponse<DynamicPricing>>(ENDPOINTS.DYNAMIC_PRICING.reject(id), {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['dynamic-pricing'] }),
  });
}

export function useDeleteDynamicPricing() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => del(ENDPOINTS.DYNAMIC_PRICING.delete(id)),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['dynamic-pricing'] }),
  });
}

export type { DynamicPricing, DynamicPricingPayload };
