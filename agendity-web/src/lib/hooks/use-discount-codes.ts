import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { get, post, patch, del } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, PaginatedResponse, DiscountCode } from '@/lib/api/types';

export function useDiscountCodes(page: number = 1) {
  return useQuery({
    queryKey: ['discount_codes', page],
    queryFn: () =>
      get<PaginatedResponse<DiscountCode>>(ENDPOINTS.DISCOUNT_CODES.list, {
        params: { page },
      }),
  });
}

interface CreateDiscountCodePayload {
  code: string;
  discount_type: 'percentage' | 'fixed';
  discount_value: number;
  max_uses?: number | null;
  valid_from?: string;
  valid_until?: string | null;
}

export function useCreateDiscountCode() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateDiscountCodePayload) =>
      post<ApiResponse<DiscountCode>>(ENDPOINTS.DISCOUNT_CODES.create, {
        discount_code: payload,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['discount_codes'] });
    },
  });
}

export function useDeleteDiscountCode() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      del<ApiResponse<void>>(ENDPOINTS.DISCOUNT_CODES.delete(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['discount_codes'] });
    },
  });
}
