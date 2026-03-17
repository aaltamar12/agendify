// ============================================================
// Agendity — Demo handlers: reviews
// ============================================================

import { route } from '../router';
import { getStore } from '../store';

// GET /api/v1/reviews (paginated)
route('get', '/api/v1/reviews', ({ query }) => {
  const store = getStore();
  const page = Number(query.page) || 1;
  const perPage = 10;

  const sorted = [...store.reviews].sort(
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
