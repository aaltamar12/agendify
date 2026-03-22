import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse } from '@/lib/api/types';

interface CreditAccount {
  id: number;
  customer_id: number;
  business_id: number;
  balance: number;
  customer_name: string;
  customer_email: string | null;
  created_at: string;
}

interface CreditTransaction {
  id: number;
  amount: number;
  transaction_type: string;
  description: string;
  appointment_id: number | null;
  performed_by: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
}

interface CustomerCredits {
  balance: number;
  transactions: CreditTransaction[];
}

export function useCreditsSummary() {
  return useQuery({
    queryKey: ['credits-summary'],
    queryFn: () => get<ApiResponse<CreditAccount[]>>(ENDPOINTS.CREDITS.summary),
    select: (res) => res.data,
  });
}

export function useCustomerCredits(customerId: number) {
  return useQuery({
    queryKey: ['customer-credits', customerId],
    queryFn: () => get<ApiResponse<CustomerCredits>>(ENDPOINTS.CUSTOMERS.credits(customerId)),
    select: (res) => res.data,
    enabled: !!customerId,
  });
}

export function useCustomerCreditBalance(customerId: number | undefined) {
  return useQuery({
    queryKey: ['customer-credit-balance', customerId],
    queryFn: () => get<ApiResponse<{ balance: number }>>(ENDPOINTS.CUSTOMERS.creditBalance(customerId!)),
    select: (res) => res.data?.balance ?? 0,
    enabled: !!customerId,
  });
}

export function useAdjustCredits() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ customerId, amount, description }: { customerId: number; amount: number; description?: string }) =>
      post<ApiResponse<{ balance: number }>>(ENDPOINTS.CUSTOMERS.adjustCredits(customerId), { amount, description }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['credits-summary'] });
      queryClient.invalidateQueries({ queryKey: ['customer-credits'] });
      queryClient.invalidateQueries({ queryKey: ['customer-credit-balance'] });
    },
  });
}

export type { CreditAccount, CreditTransaction, CustomerCredits };
