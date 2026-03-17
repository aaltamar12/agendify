import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import apiClient, { get, put } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, Business, BusinessHour } from '@/lib/api/types';

export function useCurrentBusiness() {
  return useQuery({
    queryKey: ['business'],
    queryFn: () => get<ApiResponse<Business>>(ENDPOINTS.BUSINESS.current),
    select: (res) => res.data,
  });
}

export function useUpdateBusiness() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: Partial<Business>) =>
      put<ApiResponse<Business>>(ENDPOINTS.BUSINESS.current, { business: data }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['business'] });
    },
  });
}

export function useUploadLogo() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (file: File) => {
      const formData = new FormData();
      formData.append('logo', file);
      const response = await apiClient.post(
        ENDPOINTS.BUSINESS.uploadLogo,
        formData,
        { headers: { 'Content-Type': 'multipart/form-data' } },
      );
      return response.data as ApiResponse<Business>;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['business'] });
    },
  });
}

export function useBusinessHours() {
  return useQuery({
    queryKey: ['businessHours'],
    queryFn: () =>
      get<ApiResponse<BusinessHour[]>>(ENDPOINTS.BUSINESS_HOURS.show),
    select: (res) => res.data,
  });
}

export function useUpdateBusinessHours() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (
      hours: {
        day_of_week: number;
        open_time: string;
        close_time: string;
        closed: boolean;
      }[]
    ) =>
      put<ApiResponse<BusinessHour[]>>(ENDPOINTS.BUSINESS_HOURS.update, {
        business_hours: hours,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['businessHours'] });
    },
  });
}
