import { useQuery } from '@tanstack/react-query';
import { get } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse } from '@/lib/api/types';

// --- Response types ---

export interface ReportSummary {
  total_revenue: number;
  total_appointments: number;
  total_customers: number;
  avg_rating: number;
}

export interface RevenueDataPoint {
  date: string;
  revenue: number;
}

export interface TopService {
  name: string;
  count: number;
}

export interface TopEmployee {
  name: string;
  count: number;
}

export interface FrequentCustomer {
  name: string;
  visits: number;
  total_spent: number;
}

export interface ProfitReport {
  period: string;
  from_date: string;
  revenue: number;
  employee_payments: number;
  net_profit: number;
  credits_issued: number;
  credits_redeemed: number;
  cash_register_closes: number;
  pending_employee_debt: number;
  total_credits_in_circulation: number;
}

// --- Hooks ---

export function useReportSummary() {
  return useQuery({
    queryKey: ['reports', 'summary'],
    queryFn: () =>
      get<ApiResponse<ReportSummary>>(ENDPOINTS.REPORTS.summary),
    select: (res) => res.data,
  });
}

export function useRevenueReport(period: 'week' | 'month' | 'year') {
  return useQuery({
    queryKey: ['reports', 'revenue', period],
    queryFn: () =>
      get<ApiResponse<RevenueDataPoint[]>>(ENDPOINTS.REPORTS.revenue, {
        params: { period },
      }),
    select: (res) => res.data,
  });
}

export function useTopServices() {
  return useQuery({
    queryKey: ['reports', 'topServices'],
    queryFn: () =>
      get<ApiResponse<TopService[]>>(ENDPOINTS.REPORTS.topServices),
    select: (res) => res.data,
  });
}

export function useTopEmployees() {
  return useQuery({
    queryKey: ['reports', 'topEmployees'],
    queryFn: () =>
      get<ApiResponse<TopEmployee[]>>(ENDPOINTS.REPORTS.topEmployees),
    select: (res) => res.data,
  });
}

export function useProfitReport(period: 'week' | 'month' | 'year' = 'month') {
  return useQuery({
    queryKey: ['reports', 'profit', period],
    queryFn: () =>
      get<ApiResponse<ProfitReport>>(ENDPOINTS.REPORTS.profit, { params: { period } }),
    select: (res) => res.data,
  });
}

export function useFrequentCustomers() {
  return useQuery({
    queryKey: ['reports', 'frequentCustomers'],
    queryFn: () =>
      get<ApiResponse<FrequentCustomer[]>>(ENDPOINTS.REPORTS.frequentCustomers),
    select: (res) => res.data,
  });
}
