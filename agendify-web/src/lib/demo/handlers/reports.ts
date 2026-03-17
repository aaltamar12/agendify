// ============================================================
// Agendify — Demo handlers: reports
// ============================================================

import { route } from '../router';
import { getStore } from '../store';
import {
  getReportSummary,
  getRevenueReport,
  getTopServices,
  getTopEmployees,
  getFrequentCustomers,
} from '../data/reports';

// GET /api/v1/reports/summary
route('get', '/api/v1/reports/summary', () => {
  return { data: getReportSummary(getStore()) };
});

// GET /api/v1/reports/revenue
route('get', '/api/v1/reports/revenue', ({ query }) => {
  const period = query.period ?? 'month';
  return { data: getRevenueReport(getStore(), period) };
});

// GET /api/v1/reports/top_services
route('get', '/api/v1/reports/top_services', () => {
  return { data: getTopServices(getStore()) };
});

// GET /api/v1/reports/top_employees
route('get', '/api/v1/reports/top_employees', () => {
  return { data: getTopEmployees(getStore()) };
});

// GET /api/v1/reports/frequent_customers
route('get', '/api/v1/reports/frequent_customers', () => {
  return { data: getFrequentCustomers(getStore()) };
});
