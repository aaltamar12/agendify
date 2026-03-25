import { useQuery, useMutation } from '@tanstack/react-query';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, Plan } from '@/lib/api/types';

export function useSubscriptionPlans() {
  return useQuery({
    queryKey: ['subscription-plans'],
    queryFn: () => get<ApiResponse<Plan[]>>(ENDPOINTS.SUBSCRIPTION.plans),
    select: (res) => res.data,
  });
}

interface PaymentInfo {
  nequi: string | null;
  bancolombia: string | null;
  daviplata: string | null;
  instructions: string | null;
}

export function usePaymentInfo() {
  return useQuery({
    queryKey: ['subscription-payment-info'],
    queryFn: () => get<ApiResponse<PaymentInfo>>(ENDPOINTS.SUBSCRIPTION.paymentInfo),
    select: (res) => res.data,
  });
}

export function useSubscriptionCheckout() {
  return useMutation({
    mutationFn: async (data: { plan_id: number; proof: File }) => {
      const formData = new FormData();
      formData.append('plan_id', String(data.plan_id));
      formData.append('proof', data.proof);
      // Let Axios set Content-Type automatically so it includes the multipart
      // boundary. The instance default (application/json) must be unset here,
      // otherwise Rails never receives the file.
      return post(ENDPOINTS.SUBSCRIPTION.checkout, formData, {
        headers: { 'Content-Type': undefined },
      });
    },
  });
}

interface SubscriptionStatus {
  trial_ends_at: string | null;
  in_trial: boolean;
  had_subscription: boolean;
  subscription: any;
  pending_order: any;
  admin?: boolean;
}

export function useSubscriptionStatus() {
  return useQuery({
    queryKey: ['subscription-status'],
    queryFn: () => get<ApiResponse<SubscriptionStatus>>(ENDPOINTS.SUBSCRIPTION.status),
    select: (res) => res.data,
  });
}
