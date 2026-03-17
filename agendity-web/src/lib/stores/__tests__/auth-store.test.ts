import { describe, it, expect, beforeEach } from 'vitest';
import { useAuthStore } from '../auth-store';
import type { User } from '@/lib/api/types';

const mockUser: User = {
  id: 1,
  email: 'test@agendity.co',
  name: 'Test User',
  phone: '3001234567',
  role: 'owner',
  avatar_url: null,
  business_id: 1,
  created_at: '2025-01-01T00:00:00Z',
  updated_at: '2025-01-01T00:00:00Z',
};

describe('useAuthStore', () => {
  beforeEach(() => {
    useAuthStore.getState().clearAuth();
  });

  it('has correct initial state', () => {
    const state = useAuthStore.getState();
    expect(state.token).toBeNull();
    expect(state.refreshToken).toBeNull();
    expect(state.user).toBeNull();
    expect(state.isAuthenticated()).toBe(false);
  });

  it('setAuth sets token, refreshToken, and user', () => {
    useAuthStore.getState().setAuth('jwt-token', 'refresh-token', mockUser);

    const state = useAuthStore.getState();
    expect(state.token).toBe('jwt-token');
    expect(state.refreshToken).toBe('refresh-token');
    expect(state.user).toEqual(mockUser);
  });

  it('isAuthenticated returns true when token exists', () => {
    useAuthStore.getState().setAuth('jwt-token', 'refresh-token', mockUser);
    expect(useAuthStore.getState().isAuthenticated()).toBe(true);
  });

  it('clearAuth resets everything', () => {
    useAuthStore.getState().setAuth('jwt-token', 'refresh-token', mockUser);
    useAuthStore.getState().clearAuth();

    const state = useAuthStore.getState();
    expect(state.token).toBeNull();
    expect(state.refreshToken).toBeNull();
    expect(state.user).toBeNull();
    expect(state.isAuthenticated()).toBe(false);
  });

  it('setUser updates only the user', () => {
    useAuthStore.getState().setAuth('jwt-token', 'refresh-token', mockUser);

    const updatedUser = { ...mockUser, name: 'Updated Name' };
    useAuthStore.getState().setUser(updatedUser);

    const state = useAuthStore.getState();
    expect(state.user?.name).toBe('Updated Name');
    expect(state.token).toBe('jwt-token');
  });
});
