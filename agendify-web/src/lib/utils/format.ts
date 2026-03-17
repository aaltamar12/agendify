// ============================================================
// Agendify — Formatting utilities
// ============================================================

/**
 * Format a number as Colombian Pesos (COP).
 * Example: 25000 → "$25.000"
 */
export function formatCurrency(amount: number): string {
  return (
    '$' +
    new Intl.NumberFormat('es-CO', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount)
  );
}

/**
 * Format a phone number in Colombian format.
 * Example: "3001234567" → "300 123 4567"
 */
export function formatPhone(phone: string): string {
  const cleaned = phone.replace(/\D/g, '');

  // Remove country code if present
  const local = cleaned.startsWith('57') ? cleaned.slice(2) : cleaned;

  if (local.length === 10) {
    return `${local.slice(0, 3)} ${local.slice(3, 6)} ${local.slice(6)}`;
  }

  return phone;
}

/**
 * Truncate a string to a given length, appending "..." if needed.
 */
export function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength).trimEnd() + '...';
}

/**
 * Capitalize the first letter of a string.
 */
export function capitalize(text: string): string {
  if (!text) return '';
  return text.charAt(0).toUpperCase() + text.slice(1);
}

/**
 * Format a full name (trim and capitalize each word).
 */
export function formatName(name: string): string {
  return name
    .trim()
    .split(/\s+/)
    .map((word) => capitalize(word.toLowerCase()))
    .join(' ');
}

/**
 * Generate initials from a name (max 2 chars).
 * Example: "Juan Pérez" → "JP"
 */
export function getInitials(name: string): string {
  return name
    .trim()
    .split(/\s+/)
    .map((w) => w[0]?.toUpperCase() ?? '')
    .slice(0, 2)
    .join('');
}
