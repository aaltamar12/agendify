import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { post, put } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, Business, BusinessHour, Service, Employee } from '@/lib/api/types';
import type {
  BusinessProfileFormData,
  BusinessHoursFormData,
  ServiceFormData,
  EmployeeFormData,
} from '@/lib/validations/onboarding';

export function useUpdateBusinessProfile() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: BusinessProfileFormData) =>
      put<ApiResponse<Business>>(ENDPOINTS.BUSINESS.current, { business: data }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['business'] });
    },
  });
}

export function useUpdateBusinessHours() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: BusinessHoursFormData) =>
      put<ApiResponse<BusinessHour[]>>(ENDPOINTS.BUSINESS_HOURS.update, {
        business_hours: data.hours,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['businessHours'] });
    },
  });
}

export function useCreateService() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: ServiceFormData) =>
      post<ApiResponse<Service>>(ENDPOINTS.SERVICES.create, { service: data }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
    },
  });
}

export function useCreateEmployee() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: EmployeeFormData) =>
      post<ApiResponse<Employee>>(ENDPOINTS.EMPLOYEES.create, { employee: data }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employees'] });
    },
  });
}

export function useCompleteOnboarding() {
  const router = useRouter();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      post<ApiResponse<Business>>(ENDPOINTS.BUSINESS.onboarding),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['business'] });
      router.push('/dashboard/agenda');
    },
  });
}
