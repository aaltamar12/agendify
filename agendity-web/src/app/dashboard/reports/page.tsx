'use client';

import { useState, useEffect } from 'react';
import { DollarSign, CalendarDays, Users, Star, TrendingUp, TrendingDown, Wallet, Coins, AlertTriangle, CheckCircle, Target } from 'lucide-react';
import Link from 'next/link';
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
  useProfitReport,
} from '@/lib/hooks/use-reports';
import { useReconciliationCheck } from '@/lib/hooks/use-reconciliation';
import { AI_FEATURES_PLANS } from '@/lib/constants';
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
  const { data: profit } = useProfitReport(revenuePeriod);
  const hasAI = AI_FEATURES_PLANS.includes(planSlug);
  const reconciliation = useReconciliationCheck();

  // Auto-check reconciliation when profit loads (Plan Inteligente only)
  const [reconciliationChecked, setReconciliationChecked] = useState(false);
  useEffect(() => {
    if (hasAdvancedReports && profit && !reconciliationChecked && hasAI) {
      reconciliation.mutate(undefined, {
        onSettled: () => setReconciliationChecked(true),
      });
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hasAdvancedReports, hasAI, profit, reconciliationChecked]);
  const reconResult = reconciliation.data?.data;
  const reconFailed = reconciliation.isError;
  const reconLoading = reconciliation.isPending;
  const hasDiscrepancies = reconResult && (
    reconResult.cash_register?.ok === false ||
    reconResult.credits?.ok === false
  );
  const reconVerified = reconciliationChecked && reconResult && !hasDiscrepancies && !reconFailed;

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

      {/* Profit section (Profesional+) */}
      {hasAdvancedReports && profit && (
        <Card className="mb-8">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900">Ganancias netas</h2>
            {hasDiscrepancies && (
              <a
                href="/dashboard/reconciliation"
                className="flex items-center gap-1.5 rounded-full bg-red-100 px-3 py-1 text-xs font-medium text-red-700 hover:bg-red-200 transition-colors"
              >
                <AlertTriangle className="h-3.5 w-3.5" />
                Datos inconsistentes — Revisar reconciliacion
              </a>
            )}
            {reconVerified && (
              <span className="flex items-center gap-1.5 text-xs text-green-600">
                <CheckCircle className="h-3.5 w-3.5" />
                Datos verificados
              </span>
            )}
            {reconLoading && (
              <span className="text-xs text-gray-400">Verificando...</span>
            )}
            {reconFailed && !hasAI && null}
            {reconFailed && hasAI && (
              <span className="text-xs text-orange-500">No se pudo verificar</span>
            )}
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
            <div className="rounded-lg border border-gray-200 p-4">
              <div className="flex items-center gap-2">
                <TrendingUp className="h-5 w-5 text-green-600" />
                <p className="text-xs text-gray-500">Ingresos (servicios)</p>
              </div>
              <p className="mt-1 text-xl font-bold text-gray-900">{formatCurrency(Number(profit.revenue))}</p>
            </div>
            {profit.penalty_income > 0 && (
              <div className="rounded-lg border border-orange-200 bg-orange-50 p-4">
                <div className="flex items-center gap-2">
                  <AlertTriangle className="h-5 w-5 text-orange-600" />
                  <p className="text-xs text-orange-700">Penalizaciones</p>
                </div>
                <p className="mt-1 text-xl font-bold text-orange-700">{'+' + formatCurrency(Number(profit.penalty_income))}</p>
                <p className="text-[10px] text-orange-500">Retencion por cancelaciones</p>
              </div>
            )}
            <div className="rounded-lg border border-gray-200 p-4">
              <div className="flex items-center gap-2">
                <Wallet className="h-5 w-5 text-red-500" />
                <p className="text-xs text-gray-500">Pagos empleados</p>
              </div>
              <p className="mt-1 text-xl font-bold text-red-600">{'-' + formatCurrency(Number(profit.employee_payments))}</p>
            </div>
            <div className="rounded-lg border border-gray-200 p-4">
              <div className="flex items-center gap-2">
                {profit.net_profit >= 0 ? <TrendingUp className="h-5 w-5 text-green-600" /> : <TrendingDown className="h-5 w-5 text-red-600" />}
                <p className="text-xs text-gray-500">Ganancia neta</p>
              </div>
              <p className={`mt-1 text-xl font-bold ${profit.net_profit >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                {formatCurrency(Number(profit.net_profit))}
              </p>
            </div>
            <div className="rounded-lg border border-gray-200 p-4">
              <div className="flex items-center gap-2">
                <CalendarDays className="h-5 w-5 text-violet-600" />
                <p className="text-xs text-gray-500">Cierres de caja</p>
              </div>
              <p className="mt-1 text-xl font-bold text-gray-900">{profit.cash_register_closes}</p>
            </div>
          </div>

          {/* Additional metrics */}
          <div className="mt-4 grid gap-3 sm:grid-cols-3">
            <div className="flex items-center gap-3 rounded-lg bg-gray-50 p-3">
              <Coins className="h-4 w-4 text-green-600" />
              <div>
                <p className="text-xs text-gray-500">Creditos en circulacion</p>
                <p className="text-sm font-semibold text-gray-900">{formatCurrency(Number(profit.total_credits_in_circulation))}</p>
              </div>
            </div>
            <div className="flex items-center gap-3 rounded-lg bg-gray-50 p-3">
              <DollarSign className="h-4 w-4 text-blue-600" />
              <div>
                <p className="text-xs text-gray-500">Cashback otorgado</p>
                <p className="text-sm font-semibold text-gray-900">{formatCurrency(Number(profit.credits_issued))}</p>
              </div>
            </div>
            {profit.pending_employee_debt > 0 && (
              <div className="flex items-center gap-3 rounded-lg bg-orange-50 p-3">
                <AlertTriangle className="h-4 w-4 text-orange-600" />
                <div>
                  <p className="text-xs text-orange-700">Deuda pendiente empleados</p>
                  <p className="text-sm font-semibold text-orange-900">{formatCurrency(Number(profit.pending_employee_debt))}</p>
                </div>
              </div>
            )}
          </div>
        </Card>
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
