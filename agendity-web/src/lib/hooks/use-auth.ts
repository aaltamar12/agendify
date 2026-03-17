import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import { useAuthStore } from '@/lib/stores/auth-store';
import type { ApiResponse, User } from '@/lib/api/types';
import type { LoginFormData, RegisterFormData } from '@/lib/validations/auth';

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
      router.push('/dashboard/agenda');
    },
  });
}

export function useRegister() {
  const router = useRouter();
  const setAuth = useAuthStore((s) => s.setAuth);

  return useMutation({
    mutationFn: (data: RegisterFormData) =>
      post<ApiResponse<AuthResponse>>(ENDPOINTS.AUTH.register, {
        name: data.name,
        email: data.email,
        password: data.password,
        password_confirmation: data.passwordConfirmation,
        business_name: data.businessName,
        business_type: data.businessType,
      }),
    onSuccess: (response) => {
      const { token, refresh_token, user } = response.data;
      setAuth(token, refresh_token, user);
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

export function useLogout() {
  const router = useRouter();
  const clearAuth = useAuthStore((s) => s.clearAuth);
  const queryClient = useQueryClient();

  return () => {
    clearAuth();
    queryClient.clear();
    router.push('/login');
  };
}
