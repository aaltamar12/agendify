import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type {
  ApiResponse,
  Notification,
  PaginatedResponse,
} from '@/lib/api/types';

// --- Query keys ---

const notificationKeys = {
  all: ['notifications'] as const,
  list: (page: number) => ['notifications', 'list', page] as const,
  unreadCount: ['notifications', 'unread_count'] as const,
};

// --- Queries ---

/**
 * Fetch paginated list of notifications for the current business.
 */
export function useNotifications(page = 1) {
  return useQuery({
    queryKey: notificationKeys.list(page),
    queryFn: () =>
      get<PaginatedResponse<Notification>>(ENDPOINTS.NOTIFICATIONS.list, {
        params: { page, per_page: 20 },
      }),
  });
}

/**
 * Fetch unread notification count. Refetches every 30 seconds.
 */
export function useUnreadCount() {
  return useQuery({
    queryKey: notificationKeys.unreadCount,
    queryFn: () =>
      get<ApiResponse<{ unread_count: number }>>(
        ENDPOINTS.NOTIFICATIONS.unreadCount,
      ),
    refetchInterval: 30_000,
  });
}

// --- Mutations ---

/**
 * Mark a single notification as read.
 */
export function useMarkRead() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      post<ApiResponse<Notification>>(ENDPOINTS.NOTIFICATIONS.markRead(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: notificationKeys.all });
      queryClient.invalidateQueries({ queryKey: notificationKeys.unreadCount });
    },
  });
}

/**
 * Mark all notifications as read.
 */
export function useMarkAllRead() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      post<ApiResponse<{ message: string }>>(
        ENDPOINTS.NOTIFICATIONS.markAllRead,
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: notificationKeys.all });
      queryClient.invalidateQueries({ queryKey: notificationKeys.unreadCount });
    },
  });
}
