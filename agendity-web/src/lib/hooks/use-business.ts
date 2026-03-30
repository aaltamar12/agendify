import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import apiClient, { get, post, put } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, Business, BusinessHour } from '@/lib/api/types';

interface PexelsPhoto {
  id: number;
  url_small: string;
  url_medium: string;
  url_large: string;
  photographer: string;
  alt: string;
}

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
      queryClient.invalidateQueries({ queryKey: ['onboarding-progress'] });
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
      queryClient.invalidateQueries({ queryKey: ['onboarding-progress'] });
    },
  });
}

export function useUploadCover() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (file: File) => {
      const formData = new FormData();
      formData.append('cover', file);
      const response = await apiClient.post(
        ENDPOINTS.BUSINESS.uploadCover,
        formData,
        { headers: { 'Content-Type': 'multipart/form-data' } },
      );
      return response.data as ApiResponse<Business>;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['business'] });
      queryClient.invalidateQueries({ queryKey: ['onboarding-progress'] });
    },
  });
}

export function useCoverGallery(query: string, page: number = 1) {
  return useQuery({
    queryKey: ['cover-gallery', query, page],
    queryFn: () =>
      get<ApiResponse<PexelsPhoto[]>>(ENDPOINTS.BUSINESS.coverGallery, {
        params: { query, page },
      }),
    select: (res) => res.data,
    enabled: !!query,
  });
}

export function useSelectCover() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (url: string) =>
      post<ApiResponse<Business>>(ENDPOINTS.BUSINESS.selectCover, { url }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['business'] });
      queryClient.invalidateQueries({ queryKey: ['onboarding-progress'] });
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
      queryClient.invalidateQueries({ queryKey: ['onboarding-progress'] });
    },
  });
}
