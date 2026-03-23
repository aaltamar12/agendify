// ============================================================
// Agendity — Demo mode axios adapter (no HTTP)
// ============================================================

import type { AxiosRequestConfig, InternalAxiosRequestConfig } from 'axios';
import { matchRoute, parseQuery } from './router';
import { logDemoRequest } from './safety';

// Import all handlers so they self-register routes
import './handlers/auth';
import './handlers/business';
import './handlers/services';
import './handlers/employees';
import './handlers/appointments';
import './handlers/customers';
import './handlers/payments';
import './handlers/reports';
import './handlers/notifications';
import './handlers/blocked-slots';
import './handlers/reviews';
import './handlers/locations';
import './handlers/credits';
import './handlers/dynamic-pricing';
import './handlers/goals';
import './handlers/cash-register';
import './handlers/reconciliation';
import './handlers/notification-config';
import './handlers/public';
import './handlers/qr';

/**
 * Simulate network delay (100–300ms) for realistic UX.
 */
function randomDelay(): Promise<void> {
  const ms = 100 + Math.random() * 200;
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Custom axios adapter that routes requests to in-memory handlers.
 * No HTTP request ever leaves the browser.
 */
export async function demoAdapter(
  config: InternalAxiosRequestConfig,
): Promise<any> {
  await randomDelay();

  const method = (config.method ?? 'get').toLowerCase();
  const baseURL = config.baseURL ?? '';
  const rawUrl = config.url ?? '';
  const fullUrl = rawUrl.startsWith('http') ? rawUrl : rawUrl;

  // Build URL with query params from config.params
  let url = fullUrl;
  if (config.params) {
    const qs = new URLSearchParams();
    Object.entries(config.params as Record<string, unknown>).forEach(([k, v]) => {
      if (v !== undefined && v !== null) qs.append(k, String(v));
    });
    const qsStr = qs.toString();
    if (qsStr) url = `${url}${url.includes('?') ? '&' : '?'}${qsStr}`;
  }

  logDemoRequest(method, url);

  const match = matchRoute(method, url);

  if (!match) {
    console.warn(`[DEMO] No handler for ${method.toUpperCase()} ${url}`);
    // Return 404-like response
    return {
      data: { error: 'Not found (demo)' },
      status: 404,
      statusText: 'Not Found',
      headers: { 'content-type': 'application/json' },
      config,
    };
  }

  const query = parseQuery(url);
  const body = config.data
    ? typeof config.data === 'string'
      ? JSON.parse(config.data)
      : config.data
    : undefined;

  try {
    const responseData = await match.handler({
      params: match.params,
      body,
      query,
    });

    return {
      data: responseData,
      status: 200,
      statusText: 'OK',
      headers: { 'content-type': 'application/json' },
      config,
    };
  } catch (err: any) {
    const status = err.status ?? 500;
    return {
      data: { error: err.message ?? 'Internal demo error' },
      status,
      statusText: 'Error',
      headers: { 'content-type': 'application/json' },
      config,
    };
  }
}
