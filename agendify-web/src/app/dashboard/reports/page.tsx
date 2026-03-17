'use client';

import { useState } from 'react';
import { DollarSign, CalendarDays, Users, Star } from 'lucide-react';
import { Card, Skeleton } from '@/components/ui';
import { SummaryCard } from '@/components/reports/summary-card';
import { RevenueChart } from '@/components/reports/revenue-chart';
import { TopServicesChart } from '@/components/reports/top-services-chart';
import { TopEmployeesChart } from '@/components/reports/top-employees-chart';
import {
  useReportSummary,
  useRevenueReport,
  useTopServices,
  useTopEmployees,
  useFrequentCustomers,
} from '@/lib/hooks/use-reports';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { ADVANCED_REPORTS_PLANS } from '@/lib/constants';
import { UpgradeBanner } from '@/components/shared/upgrade-banner';
import { formatCurrency } from '@/lib/utils/format';

const PERIOD_OPTIONS = [
  { value: 'week' as const, label: 'Semana' },
  { value: 'month' as const, label: 'Mes' },
  { value: 'year' as const, label: 'Año' },
];

export default function ReportsPage() {
  const [revenuePeriod, setRevenuePeriod] = useState<'week' | 'month' | 'year'>('month');
  const { planSlug } = useCurrentSubscription();
  const hasAdvancedReports = ADVANCED_REPORTS_PLANS.includes(planSlug);

  const { data: summary, isLoading: summaryLoading } = useReportSummary();
  const { data: revenueData, isLoading: revenueLoading } = useRevenueReport(revenuePeriod);
  const { data: topServices, isLoading: servicesLoading } = useTopServices();
  const { data: topEmployees, isLoading: employeesLoading } = useTopEmployees();
  const { data: frequentCustomers, isLoading: customersLoading } = useFrequentCustomers();

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Reportes</h1>
        <p className="mt-1 text-sm text-gray-500">
          Resumen del rendimiento de tu negocio.
        </p>
      </div>

      {/* Upgrade banner for Básico plan */}
      {!hasAdvancedReports && (
        <UpgradeBanner
          feature="reportes avanzados"
          targetPlan="Profesional"
          className="mb-6"
        />
      )}

      {/* Summary cards */}
      {summaryLoading ? (
        <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-24 w-full" />
          ))}
        </div>
      ) : (
        <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <SummaryCard
            title="Ingresos totales"
            value={formatCurrency(summary?.total_revenue ?? 0)}
            icon={DollarSign}
          />
          <SummaryCard
            title="Citas totales"
            value={String(summary?.total_appointments ?? 0)}
            icon={CalendarDays}
          />
          <SummaryCard
            title="Clientes totales"
            value={String(summary?.total_customers ?? 0)}
            icon={Users}
          />
          <SummaryCard
            title="Calificación promedio"
            value={`${(summary?.avg_rating ?? 0).toFixed(1)} / 5`}
            icon={Star}
          />
        </div>
      )}

      {/* Revenue chart */}
      <Card className="mb-8">
        <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Ingresos</h2>
          <div className="flex rounded-lg border border-gray-200 p-0.5">
            {PERIOD_OPTIONS.map((option) => (
              <button
                key={option.value}
                onClick={() => setRevenuePeriod(option.value)}
                className={`cursor-pointer rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
                  revenuePeriod === option.value
                    ? 'bg-violet-600 text-white'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                {option.label}
              </button>
            ))}
          </div>
        </div>
        <RevenueChart data={revenueData ?? []} isLoading={revenueLoading} />
      </Card>

      {/* Charts row */}
      <div className="mb-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card>
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            Servicios más populares
          </h2>
          <TopServicesChart data={topServices ?? []} isLoading={servicesLoading} />
        </Card>
        <Card>
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            Empleados con más citas
          </h2>
          <TopEmployeesChart data={topEmployees ?? []} isLoading={employeesLoading} />
        </Card>
      </div>

      {/* Frequent customers */}
      <Card>
        <h2 className="mb-4 text-lg font-semibold text-gray-900">
          Clientes frecuentes
        </h2>
        {customersLoading ? (
          <div className="space-y-3">
            {Array.from({ length: 5 }).map((_, i) => (
              <Skeleton key={i} className="h-12 w-full" />
            ))}
          </div>
        ) : !frequentCustomers || frequentCustomers.length === 0 ? (
          <p className="py-8 text-center text-sm text-gray-500">
            No hay datos de clientes frecuentes disponibles.
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-gray-200 bg-gray-50">
                <tr>
                  <th className="px-4 py-3 font-medium text-gray-600">Cliente</th>
                  <th className="px-4 py-3 text-center font-medium text-gray-600">
                    Visitas
                  </th>
                  <th className="px-4 py-3 text-right font-medium text-gray-600">
                    Total gastado
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {frequentCustomers.map((customer, idx) => (
                  <tr key={idx}>
                    <td className="whitespace-nowrap px-4 py-3 font-medium text-gray-900">
                      {customer.name}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 text-center text-gray-600">
                      {customer.visits}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 text-right text-gray-600">
                      {formatCurrency(customer.total_spent)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
