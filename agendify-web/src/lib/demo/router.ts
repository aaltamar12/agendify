// ============================================================
// Agendify — Demo mode URL router (pattern matching)
// ============================================================

export type HttpMethod = 'get' | 'post' | 'put' | 'patch' | 'delete';

export interface RouteMatch {
  params: Record<string, string>;
  handler: DemoHandler;
}

export type DemoHandler = (ctx: {
  params: Record<string, string>;
  body: unknown;
  query: Record<string, string>;
}) => unknown | Promise<unknown>;

interface Route {
  method: HttpMethod;
  pattern: RegExp;
  paramNames: string[];
  handler: DemoHandler;
}

const routes: Route[] = [];

/**
 * Register a handler for a method + URL pattern.
 * Pattern uses :param syntax, e.g. '/api/v1/services/:id'
 */
export function route(
  method: HttpMethod,
  pattern: string,
  handler: DemoHandler,
): void {
  const paramNames: string[] = [];

  // Convert '/api/v1/services/:id/confirm' → regex with named groups
  const regexStr = pattern
    .replace(/:[a-zA-Z_]+/g, (match) => {
      paramNames.push(match.slice(1));
      return '([^/]+)';
    })
    // Escape remaining special chars
    .replace(/\//g, '\\/');

  routes.push({
    method,
    pattern: new RegExp(`^${regexStr}$`),
    paramNames,
    handler,
  });
}

/**
 * Match an incoming request to a registered handler.
 */
export function matchRoute(
  method: string,
  url: string,
): RouteMatch | null {
  const m = method.toLowerCase() as HttpMethod;

  // Strip query string for matching, but parse it
  const [pathname] = url.split('?');

  for (const r of routes) {
    if (r.method !== m) continue;
    const match = pathname.match(r.pattern);
    if (!match) continue;

    const params: Record<string, string> = {};
    r.paramNames.forEach((name, i) => {
      params[name] = match[i + 1];
    });

    return { params, handler: r.handler };
  }

  return null;
}

/**
 * Parse query string from URL.
 */
export function parseQuery(url: string): Record<string, string> {
  const q: Record<string, string> = {};
  const idx = url.indexOf('?');
  if (idx === -1) return q;

  const searchParams = new URLSearchParams(url.slice(idx + 1));
  searchParams.forEach((value, key) => {
    q[key] = value;
  });
  return q;
}
