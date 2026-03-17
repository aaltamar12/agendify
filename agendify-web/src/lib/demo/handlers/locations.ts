// ============================================================
// Agendify — Demo handlers: locations
// Pass-through to real API for geographic data.
// If API is unavailable, return minimal Colombia data.
// ============================================================

import { route } from '../router';

const colombiaData = {
  countries: [{ code: 'CO', name: 'Colombia' }],
  states: [
    { code: 'ATL', name: 'Atlántico' },
    { code: 'ANT', name: 'Antioquia' },
    { code: 'DC', name: 'Bogotá D.C.' },
    { code: 'VAC', name: 'Valle del Cauca' },
    { code: 'SAN', name: 'Santander' },
    { code: 'BOL', name: 'Bolívar' },
  ],
  cities: {
    ATL: [{ name: 'Barranquilla' }, { name: 'Soledad' }, { name: 'Malambo' }],
    ANT: [{ name: 'Medellín' }, { name: 'Envigado' }, { name: 'Bello' }],
    DC: [{ name: 'Bogotá' }],
    VAC: [{ name: 'Cali' }, { name: 'Palmira' }],
    SAN: [{ name: 'Bucaramanga' }, { name: 'Floridablanca' }],
    BOL: [{ name: 'Cartagena' }],
  } as Record<string, { name: string }[]>,
};

// GET /api/v1/locations/countries
route('get', '/api/v1/locations/countries', () => {
  return { data: colombiaData.countries };
});

// GET /api/v1/locations/states
route('get', '/api/v1/locations/states', ({ query }) => {
  // For now return Colombian states regardless of country param
  return { data: colombiaData.states };
});

// GET /api/v1/locations/cities
route('get', '/api/v1/locations/cities', ({ query }) => {
  const state = query.state ?? '';
  const cities = colombiaData.cities[state] ?? colombiaData.cities['ATL'] ?? [];
  return { data: cities };
});
