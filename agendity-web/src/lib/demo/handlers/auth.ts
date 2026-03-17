// ============================================================
// Agendity — Demo handlers: auth
// ============================================================

import { route } from '../router';
import { getStore } from '../store';

// POST /api/v1/auth/login — accept any credentials
route('post', '/api/v1/auth/login', () => {
  const store = getStore();
  return {
    data: {
      token: 'demo-jwt-token',
      refresh_token: 'demo-refresh-token',
      user: store.user,
    },
  };
});

// GET /api/v1/auth/me — return demo user
route('get', '/api/v1/auth/me', () => {
  const store = getStore();
  return { data: store.user };
});

// DELETE /api/v1/auth/logout
route('delete', '/api/v1/auth/logout', () => {
  return { data: { message: 'Logged out' } };
});

// POST /api/v1/auth/refresh
route('post', '/api/v1/auth/refresh', () => {
  const store = getStore();
  return {
    data: {
      token: 'demo-jwt-token-refreshed',
      refresh_token: 'demo-refresh-token-refreshed',
      user: store.user,
    },
  };
});

// POST /api/v1/auth/register — simulate registration
route('post', '/api/v1/auth/register', () => {
  const store = getStore();
  return {
    data: {
      token: 'demo-jwt-token',
      refresh_token: 'demo-refresh-token',
      user: store.user,
    },
  };
});
