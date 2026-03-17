// ============================================================
// Agendify — Impersonation store (Zustand + persist sessionStorage)
// Allows superadmins to observe any business's dashboard.
// ============================================================

import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

interface ImpersonationState {
  isImpersonating: boolean;
  adminToken: string | null;
  adminRefreshToken: string | null;
  businessName: string | null;

  // Actions
  startImpersonation: (adminToken: string, adminRefreshToken: string, businessName: string) => void;
  stopImpersonation: () => void;
}

export const useImpersonationStore = create<ImpersonationState>()(
  persist(
    (set) => ({
      isImpersonating: false,
      adminToken: null,
      adminRefreshToken: null,
      businessName: null,

      startImpersonation: (adminToken, adminRefreshToken, businessName) =>
        set({
          isImpersonating: true,
          adminToken,
          adminRefreshToken,
          businessName,
        }),

      stopImpersonation: () =>
        set({
          isImpersonating: false,
          adminToken: null,
          adminRefreshToken: null,
          businessName: null,
        }),
    }),
    {
      name: 'agendify-impersonation',
      storage: createJSONStorage(() =>
        typeof window !== 'undefined' ? sessionStorage : {
          getItem: () => null,
          setItem: () => {},
          removeItem: () => {},
        }
      ),
    },
  ),
);
