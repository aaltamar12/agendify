import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { get, post, put, del } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, Employee, EmployeeSchedule } from '@/lib/api/types';

export interface ScheduleEntry {
  day_of_week: number;
  start_time: string;
  end_time: string;
  active: boolean;
}

interface EmployeePayload {
  name: string;
  email?: string;
  phone?: string;
  active?: boolean;
  service_ids?: number[];
  schedules?: ScheduleEntry[];
}

export function useEmployees() {
  return useQuery({
    queryKey: ['employees'],
    queryFn: () => get<ApiResponse<Employee[]>>(ENDPOINTS.EMPLOYEES.list),
    select: (res) => res.data,
  });
}

export function useCreateEmployee() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: EmployeePayload) =>
      post<ApiResponse<Employee>>(ENDPOINTS.EMPLOYEES.create, { employee: data }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employees'] });
    },
  });
}

export function useUpdateEmployee() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<EmployeePayload> }) =>
      put<ApiResponse<Employee>>(ENDPOINTS.EMPLOYEES.update(id), { employee: data }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employees'] });
    },
  });
}

export function useUploadEmployeeAvatar() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, file }: { id: number; file: File }) => {
      const formData = new FormData();
      formData.append('avatar', file);
      return post<ApiResponse<Employee>>(ENDPOINTS.EMPLOYEES.uploadAvatar(id), formData, {
        headers: { 'Content-Type': undefined as unknown as string },
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employees'] });
    },
  });
}

export function useDeleteEmployee() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      del<ApiResponse<null>>(ENDPOINTS.EMPLOYEES.delete(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employees'] });
    },
  });
}
