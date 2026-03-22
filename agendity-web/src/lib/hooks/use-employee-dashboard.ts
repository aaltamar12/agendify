import { useQuery, useMutation } from '@tanstack/react-query';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, Employee, Appointment } from '@/lib/api/types';

interface EmployeeDashboardData {
  employee: Employee;
  business: { name: string; logo_url: string | null } | null;
  today: Appointment[];
  stats: {
    today_count: number;
    month_completed: number;
    month_revenue: number;
  };
}

interface EmployeeScore {
  overall: number;
  rating_avg: number;
  completed_appointments: number;
  completion_rate: number;
  on_time_rate: number;
  total_revenue: number;
}

export function useEmployeeDashboard() {
  return useQuery({
    queryKey: ['employee-dashboard'],
    queryFn: () => get<ApiResponse<EmployeeDashboardData>>(ENDPOINTS.EMPLOYEE_PORTAL.dashboard),
    select: (res) => res.data,
  });
}

export function useEmployeeScore() {
  return useQuery({
    queryKey: ['employee-score'],
    queryFn: () => get<ApiResponse<EmployeeScore>>(ENDPOINTS.EMPLOYEE_PORTAL.score),
    select: (res) => res.data,
  });
}

export function useEmployeeAppointments(filters?: { date?: string; status?: string }) {
  return useQuery({
    queryKey: ['employee-appointments', filters],
    queryFn: () =>
      get<ApiResponse<Appointment[]>>(ENDPOINTS.EMPLOYEE_PORTAL.appointments, { params: filters }),
    select: (res) => res.data,
  });
}

export function useEmployeeCheckin() {
  return useMutation({
    mutationFn: (data: { appointmentId: number; confirmed?: boolean; substitute_reason?: string }) =>
      post<ApiResponse<Appointment>>(ENDPOINTS.EMPLOYEE_PORTAL.checkin(data.appointmentId), {
        confirmed: data.confirmed,
        substitute_reason: data.substitute_reason,
      }),
  });
}

export function useInvitationDetails(token: string) {
  return useQuery({
    queryKey: ['invitation', token],
    queryFn: () => get<ApiResponse<{ employee_name: string; business_name: string; email: string; expired: boolean; accepted: boolean }>>(
      ENDPOINTS.EMPLOYEE_INVITATIONS.show(token)
    ),
    select: (res) => res.data,
    enabled: !!token,
  });
}

export function useAcceptInvitation() {
  return useMutation({
    mutationFn: (data: { token: string; password: string; password_confirmation: string }) =>
      post<ApiResponse<{ token: string; refresh_token: string; user: unknown }>>(
        ENDPOINTS.EMPLOYEE_INVITATIONS.accept(data.token),
        { password: data.password, password_confirmation: data.password_confirmation }
      ),
  });
}
