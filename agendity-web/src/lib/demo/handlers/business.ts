// ============================================================
// Agendity — Demo handlers: business + business_hours
// ============================================================

import { route } from '../router';
import { getStore, updateStore, persistStore } from '../store';

// GET /api/v1/business
route('get', '/api/v1/business', () => {
  const store = getStore();
  return { data: store.business };
});

// PUT /api/v1/business
route('put', '/api/v1/business', ({ body }) => {
  const data = (body as any)?.business ?? body;
  updateStore((s) => {
    Object.assign(s.business, data);
  });
  return { data: getStore().business };
});

// POST /api/v1/business/upload_logo
route('post', '/api/v1/business/upload_logo', () => {
  updateStore((s) => {
    s.business.logo_url = 'https://ui-avatars.com/api/?name=Barbería+Elite&background=7c3aed&color=fff&size=200';
  });
  return { data: getStore().business };
});

// POST /api/v1/business/onboarding
route('post', '/api/v1/business/onboarding', ({ body }) => {
  const data = (body as any)?.business ?? body;
  updateStore((s) => {
    Object.assign(s.business, data);
    s.business.onboarding_completed = true;
  });
  return { data: getStore().business };
});

// PUT /api/v1/business/onboarding
route('put', '/api/v1/business/onboarding', ({ body }) => {
  const data = (body as any)?.business ?? body;
  updateStore((s) => {
    Object.assign(s.business, data);
    s.business.onboarding_completed = true;
  });
  return { data: getStore().business };
});

// GET /api/v1/business_hours
route('get', '/api/v1/business_hours', () => {
  const store = getStore();
  return { data: store.businessHours };
});

// PUT /api/v1/business_hours
route('put', '/api/v1/business_hours', ({ body }) => {
  const hours = (body as any)?.business_hours ?? body;
  if (Array.isArray(hours)) {
    updateStore((s) => {
      s.businessHours = hours.map((h: any, i: number) => ({
        ...s.businessHours[i],
        ...h,
        id: s.businessHours[i]?.id ?? i + 1,
        business_id: 1,
        updated_at: new Date().toISOString(),
      }));
    });
  }
  return { data: getStore().businessHours };
});
