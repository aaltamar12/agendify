import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import { useAuthStore } from '@/lib/stores/auth-store';
import type { ApiResponse, User } from '@/lib/api/types';
import type { LoginFormData, RegisterFormData, ForgotPasswordFormData, ResetPasswordFormData } from '@/lib/validations/auth';

interface AuthResponse {
  token: string;
  refresh_token: string;
  user: User;
}

export function useLogin() {
  const router = useRouter();
  const setAuth = useAuthStore((s) => s.setAuth);

  return useMutation({
    mutationFn: (data: LoginFormData) =>
      post<ApiResponse<AuthResponse>>(ENDPOINTS.AUTH.login, data),
    onSuccess: (response) => {
      const { token, refresh_token, user } = response.data;
      setAuth(token, refresh_token, user);
      router.push(user.role === 'employee' ? '/employee' : '/dashboard/agenda');
    },
  });
}

export function useRegister() {
  const router = useRouter();
  const setAuth = useAuthStore((s) => s.setAuth);

  return useMutation({
    mutationFn: (data: RegisterFormData & { referralCode?: string }) =>
      post<ApiResponse<AuthResponse>>(ENDPOINTS.AUTH.register, {
        name: data.name,
        email: data.email,
        password: data.password,
        password_confirmation: data.passwordConfirmation,
        business_name: data.businessName,
        business_type: data.businessType,
        referral_code: data.referralCode,
      }),
    onSuccess: (response) => {
      const { token, refresh_token, user } = response.data;
      setAuth(token, refresh_token, user);
      localStorage.removeItem('agendity_ref_code');
      router.push('/dashboard/onboarding');
    },
  });
}

export function useCurrentUser() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);

  return useQuery({
    queryKey: ['currentUser'],
    queryFn: () => get<ApiResponse<User>>(ENDPOINTS.AUTH.me),
    enabled: isAuthenticated(),
  });
}

export function useForgotPassword() {
  return useMutation({
    mutationFn: (data: ForgotPasswordFormData) =>
      post<ApiResponse<{ message: string }>>(ENDPOINTS.AUTH.forgotPassword, data),
  });
}

export function useResetPassword() {
  const router = useRouter();

  return useMutation({
    mutationFn: (data: ResetPasswordFormData & { token: string }) =>
      post<ApiResponse<{ message: string }>>(ENDPOINTS.AUTH.resetPassword, {
        token: data.token,
        password: data.password,
        password_confirmation: data.passwordConfirmation,
      }),
    onSuccess: () => {
      router.push('/login?reset=success');
    },
  });
}

export function useLogout() {
  const router = useRouter();
  const clearAuth = useAuthStore((s) => s.clearAuth);
  const queryClient = useQueryClient();

  return () => {
    clearAuth();
    localStorage.removeItem('agendity_ref_code');
    queryClient.clear();
    router.push('/login');
  };
}
