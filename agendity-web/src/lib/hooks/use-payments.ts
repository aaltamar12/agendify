import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, Appointment, Payment } from '@/lib/api/types';

// --- Query keys ---

const paymentKeys = {
  all: ['payments'] as const,
  pendingProofs: ['payments', 'pending-proofs'] as const,
  waitingPayment: ['payments', 'waiting-payment'] as const,
  approved: ['payments', 'approved'] as const,
  rejected: ['payments', 'rejected'] as const,
};

// --- Queries ---

/**
 * Fetch appointments with status `payment_sent`.
 * Customer uploaded proof, business needs to approve/reject.
 */
export function usePendingProofs() {
  return useQuery({
    queryKey: paymentKeys.pendingProofs,
    queryFn: () =>
      get<ApiResponse<Appointment[]>>(ENDPOINTS.APPOINTMENTS.list, {
        params: { status: 'payment_sent' },
      }),
    refetchInterval: 30_000,
  });
}

/**
 * Fetch appointments with status `pending_payment`.
 * Customer booked but hasn't paid yet — no proof uploaded.
 */
export function useWaitingPayment() {
  return useQuery({
    queryKey: paymentKeys.waitingPayment,
    queryFn: () =>
      get<ApiResponse<Appointment[]>>(ENDPOINTS.APPOINTMENTS.list, {
        params: { status: 'pending_payment' },
      }),
    refetchInterval: 30_000,
  });
}

/**
 * Fetch appointments with status `confirmed` — payments already approved.
 */
export function useApprovedPayments() {
  return useQuery({
    queryKey: paymentKeys.approved,
    queryFn: () =>
      get<ApiResponse<Appointment[]>>(ENDPOINTS.APPOINTMENTS.list, {
        params: { status: 'confirmed' },
      }),
  });
}

/**
 * Fetch appointments where the payment status is `rejected`.
 * Note: rejected payments revert appointment to pending_payment,
 * so we filter by payment_status instead.
 */
export function useRejectedPayments() {
  return useQuery({
    queryKey: paymentKeys.rejected,
    queryFn: () =>
      get<ApiResponse<Appointment[]>>(ENDPOINTS.APPOINTMENTS.list, {
        params: { payment_status: 'rejected' },
      }),
  });
}

// --- Mutations ---

/**
 * Approve a payment by its ID.
 */
export function useApprovePayment() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (paymentId: number) =>
      post<ApiResponse<Payment>>(ENDPOINTS.PAYMENTS.approve(paymentId)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: paymentKeys.all });
      queryClient.invalidateQueries({ queryKey: ['appointments'] });
    },
  });
}

/**
 * Reject a payment by its ID.
 */
export function useRejectPayment() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      paymentId,
      reason,
    }: {
      paymentId: number;
      reason?: string;
    }) =>
      post<ApiResponse<Payment>>(ENDPOINTS.PAYMENTS.reject(paymentId), {
        rejection_reason: reason,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: paymentKeys.all });
      queryClient.invalidateQueries({ queryKey: ['appointments'] });
    },
  });
}

/**
 * Send a payment reminder to the customer.
 */
export function useSendPaymentReminder() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (appointmentId: number) =>
      post<ApiResponse<{ message: string }>>(
        ENDPOINTS.APPOINTMENTS.remindPayment(appointmentId),
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: paymentKeys.all });
    },
  });
}
