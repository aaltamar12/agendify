// ============================================================
// Agendity — Demo handlers: notifications
// ============================================================

import { route } from '../router';
import { getStore, updateStore } from '../store';

// GET /api/v1/notifications (paginated)
route('get', '/api/v1/notifications', ({ query }) => {
  const store = getStore();
  const page = Number(query.page) || 1;
  const perPage = Number(query.per_page) || 20;

  const sorted = [...store.notifications].sort(
    (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
  );

  const totalCount = sorted.length;
  const totalPages = Math.ceil(totalCount / perPage);
  const start = (page - 1) * perPage;
  const data = sorted.slice(start, start + perPage);

  return {
    data,
    meta: {
      current_page: page,
      total_pages: totalPages,
      total_count: totalCount,
      per_page: perPage,
    },
  };
});

// GET /api/v1/notifications/unread_count
route('get', '/api/v1/notifications/unread_count', () => {
  const store = getStore();
  const unread = store.notifications.filter((n) => !n.read).length;
  return { data: { unread_count: unread } };
});

// POST /api/v1/notifications/:id/mark_read
route('post', '/api/v1/notifications/:id/mark_read', ({ params }) => {
  const id = Number(params.id);

  updateStore((s) => {
    const notif = s.notifications.find((n) => n.id === id);
    if (notif) notif.read = true;
  });

  const store = getStore();
  const notif = store.notifications.find((n) => n.id === id);
  return { data: notif };
});

// POST /api/v1/notifications/mark_all_read
route('post', '/api/v1/notifications/mark_all_read', () => {
  updateStore((s) => {
    s.notifications.forEach((n) => {
      n.read = true;
    });
  });

  return { data: { message: 'All notifications marked as read' } };
});
