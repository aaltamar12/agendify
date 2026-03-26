import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { get, post, put, patch, del } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, Service } from '@/lib/api/types';

interface ServicePayload {
  name: string;
  description?: string;
  price: number;
  duration_minutes: number;
  active?: boolean;
  category?: string | null;
}

export function useServices() {
  return useQuery({
    queryKey: ['services'],
    queryFn: () => get<ApiResponse<Service[]>>(ENDPOINTS.SERVICES.list),
    select: (res) => res.data,
  });
}

export function useCreateService() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: ServicePayload) =>
      post<ApiResponse<Service>>(ENDPOINTS.SERVICES.create, { service: data }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
    },
  });
}

export function useUpdateService() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<ServicePayload> }) =>
      put<ApiResponse<Service>>(ENDPOINTS.SERVICES.update(id), { service: data }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
    },
  });
}

export function useDeleteService() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      del<ApiResponse<null>>(ENDPOINTS.SERVICES.delete(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
    },
  });
}

export function useServiceCategories() {
  return useQuery({
    queryKey: ['service-categories'],
    queryFn: () => get<ApiResponse<string[]>>(ENDPOINTS.SERVICES.categories),
    select: (res) => res.data,
  });
}

export function useRenameCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ oldName, newName }: { oldName: string; newName: string }) =>
      patch<ApiResponse<{ updated: number; new_name: string }>>(
        ENDPOINTS.SERVICES.renameCategory,
        { old_name: oldName, new_name: newName }
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
      queryClient.invalidateQueries({ queryKey: ['service-categories'] });
    },
  });
}

export function useDeleteCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (name: string) =>
      del<ApiResponse<{ updated: number }>>(ENDPOINTS.SERVICES.deleteCategory, {
        data: { name },
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
      queryClient.invalidateQueries({ queryKey: ['service-categories'] });
    },
  });
}
