import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type {
  ApiResponse,
  Business,
  Service,
  Employee,
  Review,
  BusinessHour,
  Appointment,
} from '@/lib/api/types';

// --- Response types for public endpoints ---

interface PublicBusinessResponse {
  business: Business;
  services: Service[];
  employees: Employee[];
  reviews: Review[];
  business_hours: BusinessHour[];
  average_rating: number;
  total_reviews: number;
}

interface AvailabilityParams {
  service_id: number;
  employee_id?: number | null;
  date: string;
}

interface AvailabilityResponse {
  date: string;
  slots: string[];
}

interface BookAppointmentPayload {
  slug: string;
  service_id: number;
  employee_id?: number | null;
  date: string;
  start_time: string;
  customer: {
    name: string;
    email: string;
    phone: string;
  };
  notes?: string;
  additional_service_ids?: number[];
}

interface BookAppointmentResponse {
  appointment: Appointment;
  ticket_code: string;
  business: Business;
  penalty_applied?: number;
}

interface TicketResponse {
  appointment: Appointment;
  business: Business;
  ticket_vip: boolean;
}

interface CancelBookingPayload {
  code: string;
  reason?: string;
}

interface CancelBookingResponse {
  appointment: Appointment;
  penalty_applied: boolean;
  penalty_amount: number;
  credit_amount?: number;
}

interface CancelPreviewResponse {
  has_paid: boolean;
  deadline_passed: boolean;
  penalty_pct: number;
  penalty_amount: number;
  refund_amount: number;
  price: number;
  business_contact: {
    name: string;
    phone: string | null;
    email: string | null;
    address: string | null;
  };
}

interface SubmitPaymentPayload {
  appointment_id: number;
  payment_method: string;
  reference?: string;
  proof: File | null;
}

interface SubmitTicketPaymentPayload {
  code: string;
  payment_method?: string;
  proof: File;
  customer_email: string;
}

// --- Hooks ---

export function usePublicBusiness(slug: string) {
  return useQuery({
    queryKey: ['public', 'business', slug],
    queryFn: () =>
      get<ApiResponse<PublicBusinessResponse>>(ENDPOINTS.PUBLIC.business(slug)),
    select: (res) => res.data,
    enabled: !!slug,
  });
}

export function useAvailability(slug: string, params: AvailabilityParams) {
  return useQuery({
    queryKey: ['public', 'availability', slug, params],
    queryFn: async () => {
      const res = await get<ApiResponse<{ time: string; available: boolean }[]>>(
        ENDPOINTS.PUBLIC.availability(slug),
        {
          params: {
            service_id: params.service_id,
            employee_id: params.employee_id,
            date: params.date,
          },
        },
      );
      // Transform backend format [{time, available}] to {slots: string[]}
      const slots = (res.data ?? [])
        .filter((s) => s.available)
        .map((s) => s.time);
      return { date: params.date, slots } as AvailabilityResponse;
    },
    enabled: !!slug && !!params.service_id && !!params.date,
  });
}

export function useBookAppointment() {
  return useMutation({
    mutationFn: (payload: BookAppointmentPayload) => {
      const { slug, ...data } = payload;
      return post<ApiResponse<BookAppointmentResponse>>(
        ENDPOINTS.PUBLIC.book(slug),
        { booking: data },
      );
    },
  });
}

export function usePublicTicket(code: string) {
  return useQuery({
    queryKey: ['public', 'ticket', code],
    queryFn: () =>
      get<ApiResponse<TicketResponse>>(ENDPOINTS.PUBLIC.ticket(code)),
    select: (res) => res.data,
    enabled: !!code,
  });
}

export function useCancelPreview(code: string, enabled: boolean) {
  return useQuery({
    queryKey: ['public', 'cancel_preview', code],
    queryFn: () =>
      get<ApiResponse<CancelPreviewResponse>>(ENDPOINTS.PUBLIC.cancelPreview(code)),
    select: (res) => res.data,
    enabled: !!code && enabled,
  });
}

export function useCancelBooking() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CancelBookingPayload) =>
      post<ApiResponse<CancelBookingResponse>>(
        ENDPOINTS.PUBLIC.cancelTicket(payload.code),
        { reason: payload.reason },
      ),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ['public', 'ticket', variables.code],
      });
    },
  });
}

export function useSubmitPayment() {
  return useMutation({
    mutationFn: (payload: SubmitPaymentPayload) => {
      const formData = new FormData();
      formData.append('payment[payment_method]', payload.payment_method);
      if (payload.reference) {
        formData.append('payment[reference]', payload.reference);
      }
      if (payload.proof) {
        formData.append('payment[proof]', payload.proof);
      }

      return post<ApiResponse<{ status: string }>>(
        ENDPOINTS.PAYMENTS.submit(payload.appointment_id),
        formData,
        {
          headers: { 'Content-Type': undefined },
          timeout: 60_000,
        },
      );
    },
  });
}

/**
 * Submit a payment proof for a ticket (public, no auth required).
 * Uses the public endpoint: POST /api/v1/public/tickets/:code/payment
 */
export function useSubmitTicketPayment() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: SubmitTicketPaymentPayload) => {
      const formData = new FormData();
      formData.append('payment_method', payload.payment_method ?? 'transfer');
      formData.append('proof', payload.proof);
      formData.append('customer_email', payload.customer_email);

      return post<ApiResponse<{ status: string; message: string }>>(
        ENDPOINTS.PUBLIC.submitTicketPayment(payload.code),
        formData,
        {
          headers: { 'Content-Type': undefined },
          timeout: 60_000,
        },
      );
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ['public', 'ticket', variables.code],
      });
    },
  });
}
