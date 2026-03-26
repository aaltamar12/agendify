import { useQuery, useMutation } from '@tanstack/react-query';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, PaginatedResponse, Customer } from '@/lib/api/types';

export function useCustomers(page: number = 1, search?: string) {
  return useQuery({
    queryKey: ['customers', page, search],
    queryFn: () =>
      get<PaginatedResponse<Customer>>(ENDPOINTS.CUSTOMERS.list, {
        params: {
          page,
          ...(search ? { q: search } : {}),
        },
      }),
  });
}

export function useCustomer(id: number | null) {
  return useQuery({
    queryKey: ['customer', id],
    queryFn: () =>
      get<ApiResponse<Customer & { appointments: unknown[] }>>(
        ENDPOINTS.CUSTOMERS.show(id!)
      ),
    select: (res) => res.data,
    enabled: id !== null,
  });
}

export function useSendBirthdayGreeting() {
  return useMutation({
    mutationFn: (customerId: number) =>
      post<ApiResponse<{ message: string }>>(
        ENDPOINTS.CUSTOMERS.sendBirthdayGreeting(customerId)
      ),
  });
}
