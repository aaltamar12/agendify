// ============================================================
// Agendify — Auth store (Zustand + persist)
// ============================================================

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { User } from '@/lib/api/types';

interface AuthState {
  token: string | null;
  refreshToken: string | null;
  user: User | null;

  // Actions
  setAuth: (token: string, refreshToken: string, user: User) => void;
  setUser: (user: User) => void;
  clearAuth: () => void;

  // Computed
  isAuthenticated: () => boolean;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      token: null,
      refreshToken: null,
      user: null,

      setAuth: (token, refreshToken, user) => {
        set({ token, refreshToken, user });
        // Sync to cookie so Next.js middleware can read it
        if (typeof document !== 'undefined') {
          document.cookie = `agendify-auth=${encodeURIComponent(JSON.stringify({ state: { token, user } }))};path=/;max-age=${60 * 60 * 24 * 30};samesite=lax`;
        }
      },

      setUser: (user) => set({ user }),

      clearAuth: () => {
        set({ token: null, refreshToken: null, user: null });
        if (typeof document !== 'undefined') {
          document.cookie = 'agendify-auth=;path=/;max-age=0';
        }
      },

      isAuthenticated: () => get().token !== null,
    }),
    {
      name: 'agendify-auth',
      partialize: (state) => ({
        token: state.token,
        refreshToken: state.refreshToken,
        user: state.user,
      }),
    },
  ),
);
