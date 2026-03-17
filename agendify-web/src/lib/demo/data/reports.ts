// ============================================================
// Agendify — Demo seed: pre-calculated report data
// ============================================================

import type { DemoStore } from '../store';

export function getReportSummary(store: DemoStore) {
  const completed = store.appointments.filter((a) => a.status === 'completed');
  const totalRevenue = completed.reduce((sum, a) => sum + a.price, 0);
  const uniqueCustomers = new Set(store.appointments.map((a) => a.customer_id)).size;

  return {
    total_revenue: totalRevenue || 2450000,
    total_appointments: store.appointments.length,
    total_customers: uniqueCustomers || store.customers.length,
    avg_rating: store.business.rating_average,
  };
}

export function getRevenueReport(store: DemoStore, period: string) {
  // Generate realistic revenue data points
  const now = new Date();
  const points: { date: string; revenue: number }[] = [];

  let days = 7;
  if (period === 'month') days = 30;
  if (period === 'year') days = 365;

  // For year, aggregate by month
  if (period === 'year') {
    for (let i = 11; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const baseRevenue = 2000000 + Math.random() * 800000;
      points.push({
        date: d.toISOString().split('T')[0],
        revenue: Math.round(baseRevenue),
      });
    }
    return points;
  }

  for (let i = days - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dateStr = d.toISOString().split('T')[0];
    const dayOfWeek = d.getDay();

    // More revenue on weekends, less on Monday
    let base = 80000;
    if (dayOfWeek === 0) base = 0; // Closed Sunday
    else if (dayOfWeek === 6) base = 150000; // Saturday peak
    else if (dayOfWeek === 5) base = 120000; // Friday busy

    const revenue = base + Math.round(Math.random() * 50000);
    points.push({ date: dateStr, revenue: dayOfWeek === 0 ? 0 : revenue });
  }

  return points;
}

export function getTopServices(store: DemoStore) {
  const counts: Record<string, number> = {};
  for (const a of store.appointments.filter((a) => a.status !== 'cancelled')) {
    const svc = store.services.find((s) => s.id === a.service_id);
    if (svc) counts[svc.name] = (counts[svc.name] ?? 0) + 1;
  }

  return Object.entries(counts)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 5);
}

export function getTopEmployees(store: DemoStore) {
  const counts: Record<string, number> = {};
  for (const a of store.appointments.filter((a) => a.status !== 'cancelled')) {
    const emp = store.employees.find((e) => e.id === a.employee_id);
    if (emp) counts[emp.name] = (counts[emp.name] ?? 0) + 1;
  }

  return Object.entries(counts)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count);
}

export function getFrequentCustomers(store: DemoStore) {
  return store.customers
    .map((c) => ({
      name: c.name,
      visits: c.total_visits,
      total_spent: c.total_visits * 20000, // Average spend estimate
    }))
    .sort((a, b) => b.visits - a.visits)
    .slice(0, 10);
}
