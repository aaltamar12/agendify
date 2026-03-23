import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import apiClient, { get, post, del } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse } from '@/lib/api/types';

interface AppointmentDetail {
  id: number;
  customer_name: string;
  service_name: string;
  start_time: string;
  price: number;
  status: string;
}

interface EmployeeSummary {
  employee_id: number;
  employee_name: string;
  payment_type?: 'none' | 'commission' | 'fixed_daily';
  appointments_count: number;
  total_earned: number;
  commission_pct: number;
  commission_amount: number;
  fixed_daily_pay?: number;
  pending_from_previous: number;
  total_owed: number;
  appointments: AppointmentDetail[];
}

interface DailySummary {
  date: string;
  total_revenue: number;
  total_appointments: number;
  employees: EmployeeSummary[];
  already_closed: boolean;
  close_id: number | null;
}

interface EmployeePaymentData {
  employee_id: number;
  employee_name?: string;
  appointments_count: number;
  total_earned: number;
  commission_pct: number;
  commission_amount: number;
  pending_from_previous?: number;
  total_owed?: number;
  amount_paid: number;
  payment_method: string;
  proof_url?: string | null;
  remaining_debt?: number;
  notes?: string;
}

interface CashRegisterClose {
  id: number;
  date: string;
  closed_at: string;
  total_revenue: number;
  total_tips: number;
  total_appointments: number;
  notes: string | null;
  status: string;
  created_at: string;
  employee_payments?: EmployeePaymentData[];
}

export function useDailySummary(date?: string) {
  return useQuery({
    queryKey: ['cash-register-today', date],
    queryFn: () =>
      get<ApiResponse<DailySummary>>(ENDPOINTS.CASH_REGISTER.today, {
        params: date ? { date } : undefined,
      }),
    select: (res) => res.data,
  });
}

export function useCloseCashRegister() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: {
      date: string;
      employee_payments: EmployeePaymentData[];
      notes?: string;
    }) => post<ApiResponse<CashRegisterClose>>(ENDPOINTS.CASH_REGISTER.close, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cash-register-today'] });
      queryClient.invalidateQueries({ queryKey: ['cash-register-history'] });
    },
  });
}

export function useUploadPaymentProof() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ employeePaymentId, file }: { employeePaymentId: number; file: File }) => {
      const formData = new FormData();
      formData.append('proof', file);
      formData.append('employee_payment_id', String(employeePaymentId));
      const response = await apiClient.post(ENDPOINTS.CASH_REGISTER.uploadProof, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cash-register'] });
    },
  });
}

export function useDeletePaymentProof() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (employeePaymentId: number) =>
      del(ENDPOINTS.CASH_REGISTER.deleteProof, { params: { employee_payment_id: employeePaymentId } }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cash-register'] });
    },
  });
}

export function useCashRegisterHistory(filters?: { from?: string; to?: string }) {
  return useQuery({
    queryKey: ['cash-register-history', filters],
    queryFn: () =>
      get<ApiResponse<CashRegisterClose[]>>(ENDPOINTS.CASH_REGISTER.history, {
        params: filters,
      }),
    select: (res) => res.data,
  });
}

export type { DailySummary, EmployeeSummary, EmployeePaymentData, CashRegisterClose };
