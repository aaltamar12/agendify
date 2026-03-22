import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse } from '@/lib/api/types';

interface Discrepancy {
  id: number;
  name: string;
  expected: number;
  actual: number;
  difference: number;
}

interface ReconciliationResult {
  cash_register: {
    status: 'ok' | 'discrepancies';
    discrepancies: Discrepancy[];
  };
  credits: {
    status: 'ok' | 'discrepancies';
    discrepancies: Discrepancy[];
  };
}

interface BalanceHistoryEntry {
  type: 'payment' | 'adjustment';
  date: string;
  amount: number;
  description: string;
  balance_after?: number;
}

export function useReconciliationCheck() {
  return useMutation({
    mutationFn: () => get<ApiResponse<ReconciliationResult>>(ENDPOINTS.RECONCILIATION.check),
    // Use mutation instead of query so it runs on demand, not automatically
  });
}

export function useAdjustEmployeeBalance() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ employeeId, amount, reason, notes }: { employeeId: number; amount: number; reason: string; notes?: string }) =>
      post<ApiResponse<{ balance: number }>>(ENDPOINTS.EMPLOYEE_BALANCE.adjust(employeeId), { amount, reason, notes }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['employees'] });
      qc.invalidateQueries({ queryKey: ['reconciliation'] });
    },
  });
}

export function useEmployeeBalanceHistory(employeeId: number) {
  return useQuery({
    queryKey: ['employee-balance-history', employeeId],
    queryFn: () => get<ApiResponse<BalanceHistoryEntry[]>>(ENDPOINTS.EMPLOYEE_BALANCE.history(employeeId)),
    select: (res) => res.data,
    enabled: !!employeeId,
  });
}

export type { ReconciliationResult, Discrepancy, BalanceHistoryEntry };
