import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { get, post, put } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, Appointment, CheckinResponse } from '@/lib/api/types';
import type { CreateAppointmentFormData } from '@/lib/validations/appointment';

// --- Query keys ---

const appointmentKeys = {
  all: ['appointments'] as const,
  list: (params: Record<string, unknown>) => ['appointments', 'list', params] as const,
  detail: (id: number) => ['appointments', 'detail', id] as const,
};

// --- Queries ---

interface UseAppointmentsParams {
  date?: string;
  employee_id?: number;
  status?: string;
}

export function useAppointments(params: UseAppointmentsParams = {}) {
  return useQuery({
    queryKey: appointmentKeys.list(params as unknown as Record<string, unknown>),
    queryFn: () =>
      get<ApiResponse<Appointment[]>>(ENDPOINTS.APPOINTMENTS.list, {
        params,
      }),
    refetchInterval: 15_000, // Auto-refresh every 15 seconds
  });
}

export function useAppointment(id: number) {
  return useQuery({
    queryKey: appointmentKeys.detail(id),
    queryFn: () =>
      get<ApiResponse<Appointment>>(ENDPOINTS.APPOINTMENTS.show(id)),
    enabled: id > 0,
  });
}

// --- Mutations ---

export function useCreateAppointment() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateAppointmentFormData) =>
      post<ApiResponse<Appointment>>(ENDPOINTS.APPOINTMENTS.create, {
        appointment: data,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: appointmentKeys.all });
    },
  });
}

export function useUpdateAppointment() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: number;
      data: Partial<CreateAppointmentFormData>;
    }) =>
      put<ApiResponse<Appointment>>(ENDPOINTS.APPOINTMENTS.update(id), {
        appointment: data,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: appointmentKeys.all });
    },
  });
}

export function useCancelAppointment() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      reason,
      cancelled_by,
    }: {
      id: number;
      reason?: string;
      cancelled_by?: 'business' | 'customer';
    }) =>
      post<ApiResponse<Appointment>>(ENDPOINTS.APPOINTMENTS.cancel(id), {
        cancellation_reason: reason,
        cancelled_by,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: appointmentKeys.all });
    },
  });
}

export function useConfirmPayment(id: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      post<ApiResponse<Appointment>>(ENDPOINTS.APPOINTMENTS.confirm(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: appointmentKeys.all });
    },
  });
}

export function useCheckinAppointment(id: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      post<ApiResponse<Appointment>>(ENDPOINTS.APPOINTMENTS.checkin(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: appointmentKeys.all });
    },
  });
}

export function useCheckinByCode() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (ticketCode: string) =>
      post<CheckinResponse>(ENDPOINTS.APPOINTMENTS.checkinByCode, {
        ticket_code: ticketCode,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: appointmentKeys.all });
    },
  });
}

export function useCompleteAppointment(id: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      post<ApiResponse<Appointment>>(ENDPOINTS.APPOINTMENTS.complete(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: appointmentKeys.all });
    },
  });
}
