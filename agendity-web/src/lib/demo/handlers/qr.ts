// ============================================================
// Agendity — Demo handlers: QR generation
// ============================================================

import { route } from '../router';
import { getStore } from '../store';

// POST /api/v1/qr/generate
route('post', '/api/v1/qr/generate', () => {
  const store = getStore();
  const slug = store.business.slug;
  const publicUrl = `${typeof window !== 'undefined' ? window.location.origin : 'https://agendity.co'}/${slug}`;

  return {
    data: {
      qr_url: publicUrl,
      short_url: publicUrl,
    },
  };
});
