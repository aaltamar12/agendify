// ============================================================
// Agendity — localStorage utility for customer data persistence
// ============================================================

const STORAGE_KEY = 'agendity-customer';

export interface SavedCustomer {
  name: string;
  email: string;
  phone: string;
}

export function getSavedCustomer(): SavedCustomer | null {
  try {
    if (typeof window === 'undefined') return null;
    const data = localStorage.getItem(STORAGE_KEY);
    return data ? JSON.parse(data) : null;
  } catch {
    return null;
  }
}

export function saveCustomer(data: SavedCustomer): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  } catch {
    // Silent fail — localStorage might be full or unavailable
  }
}

export function clearSavedCustomer(): void {
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch {
    // Silent fail
  }
}
