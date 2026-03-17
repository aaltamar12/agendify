import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { get, post, del } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, BlockedSlot } from '@/lib/api/types';
import type { BlockSlotFormData } from '@/lib/validations/appointment';

// --- Query keys ---

const blockedSlotKeys = {
  all: ['blockedSlots'] as const,
  list: (params: Record<string, unknown>) =>
    ['blockedSlots', 'list', params] as const,
};

// --- Queries ---

interface UseBlockedSlotsParams {
  date?: string;
  employee_id?: number;
}

export function useBlockedSlots(params: UseBlockedSlotsParams = {}) {
  return useQuery({
    queryKey: blockedSlotKeys.list(params as unknown as Record<string, unknown>),
    queryFn: () =>
      get<ApiResponse<BlockedSlot[]>>(ENDPOINTS.BLOCKED_SLOTS.list, {
        params,
      }),
    refetchInterval: 30_000, // Auto-refresh every 30 seconds
  });
}

// --- Mutations ---

export function useCreateBlockedSlot() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: BlockSlotFormData) =>
      post<ApiResponse<BlockedSlot>>(ENDPOINTS.BLOCKED_SLOTS.create, {
        blocked_slot: data,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: blockedSlotKeys.all });
    },
  });
}

export function useDeleteBlockedSlot() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      del<ApiResponse<void>>(ENDPOINTS.BLOCKED_SLOTS.delete(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: blockedSlotKeys.all });
    },
  });
}
