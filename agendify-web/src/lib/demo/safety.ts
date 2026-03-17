// ============================================================
// Agendify — Demo mode safety mechanisms
// ============================================================

/**
 * Print a prominent warning in the console whenever demo mode is active.
 */
export function logDemoWarning(): void {
  console.warn(
    '%c⚠️  MODO DEMO ACTIVO  ⚠️',
    'background: #f97316; color: #000; font-size: 18px; font-weight: bold; padding: 8px 16px; border-radius: 4px;',
  );
  console.warn(
    '%cTodos los datos son ficticios. Ninguna petición HTTP sale del navegador.\n' +
      'Para desactivar: elimina NEXT_PUBLIC_DEMO_MODE de .env',
    'color: #fb923c; font-size: 12px;',
  );
}

/**
 * Log each intercepted request to the console.
 */
export function logDemoRequest(method: string, url: string): void {
  console.log(
    `%c[DEMO] %c${method.toUpperCase()} %c${url}`,
    'color: #f97316; font-weight: bold;',
    'color: #60a5fa;',
    'color: #a3a3a3;',
  );
}
