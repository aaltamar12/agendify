// ============================================================
// Agendify — UI store (Zustand)
// ============================================================

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { ReactNode } from 'react';

export interface Toast {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  message: string;
  duration?: number;
}

interface UIState {
  sidebarOpen: boolean;
  modalOpen: boolean;
  modalContent: ReactNode | null;
  toasts: Toast[];
  notificationSoundEnabled: boolean;

  // Actions
  toggleSidebar: () => void;
  setSidebarOpen: (open: boolean) => void;
  openModal: (content: ReactNode) => void;
  closeModal: () => void;
  addToast: (toast: Omit<Toast, 'id'>) => void;
  removeToast: (id: string) => void;
  toggleNotificationSound: () => void;
}

export const useUIStore = create<UIState>()(
  persist(
    (set) => ({
      sidebarOpen: false,
      modalOpen: false,
      modalContent: null,
      toasts: [],
      notificationSoundEnabled: true,

      toggleSidebar: () =>
        set((state) => ({ sidebarOpen: !state.sidebarOpen })),

      setSidebarOpen: (open) => set({ sidebarOpen: open }),

      openModal: (content) => set({ modalOpen: true, modalContent: content }),

      closeModal: () => set({ modalOpen: false, modalContent: null }),

      addToast: (toast) => {
        const id = `toast-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
        set((state) => ({
          toasts: [...state.toasts, { ...toast, id }],
        }));
        // Auto-dismiss after duration or 5 seconds
        setTimeout(() => {
          set((state) => ({
            toasts: state.toasts.filter((t) => t.id !== id),
          }));
        }, toast.duration ?? 5000);
      },

      removeToast: (id) =>
        set((state) => ({
          toasts: state.toasts.filter((t) => t.id !== id),
        })),

      toggleNotificationSound: () =>
        set((state) => ({ notificationSoundEnabled: !state.notificationSoundEnabled })),
    }),
    {
      name: 'agendify-ui',
      partialize: (state) => ({
        notificationSoundEnabled: state.notificationSoundEnabled,
      }),
    },
  ),
);
