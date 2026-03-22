'use client';

import { Calendar, DollarSign, CheckCircle, Star } from 'lucide-react';
import { Card, Spinner, Badge } from '@/components/ui';
import { useEmployeeDashboard, useEmployeeScore } from '@/lib/hooks/use-employee-dashboard';
import { formatCurrency } from '@/lib/utils/format';

export default function EmployeeDashboardPage() {
  const { data, isLoading } = useEmployeeDashboard();
  const { data: score } = useEmployeeScore();

  if (isLoading) {
    return <div className="flex justify-center py-12"><Spinner size="lg" /></div>;
  }

  if (!data) {
    return <p className="text-gray-500">No se pudo cargar el dashboard.</p>;
  }

  const scoreColor = (score?.overall ?? 0) >= 70 ? 'text-green-600' : (score?.overall ?? 0) >= 40 ? 'text-yellow-600' : 'text-red-600';

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-gray-900">Mi dashboard</h1>

      {/* Score + Stats */}
      <div className="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {score && (
          <Card>
            <div className="flex items-center gap-3">
              <div className={`text-3xl font-bold ${scoreColor}`}>{score.overall}</div>
              <div>
                <p className="text-sm text-gray-500">Score</p>
                <p className="text-xs text-gray-400">de 100</p>
              </div>
            </div>
          </Card>
        )}
        <Card>
          <div className="flex items-center gap-3">
            <Calendar className="h-5 w-5 text-violet-600" />
            <div>
              <p className="text-lg font-bold text-gray-900">{data.stats.today_count}</p>
              <p className="text-xs text-gray-500">Citas hoy</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <CheckCircle className="h-5 w-5 text-green-600" />
            <div>
              <p className="text-lg font-bold text-gray-900">{data.stats.month_completed}</p>
              <p className="text-xs text-gray-500">Completadas (mes)</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <DollarSign className="h-5 w-5 text-green-600" />
            <div>
              <p className="text-lg font-bold text-gray-900">${data.stats.month_revenue.toLocaleString()}</p>
              <p className="text-xs text-gray-500">Ingresos (mes)</p>
            </div>
          </div>
        </Card>
      </div>

      {/* Score details */}
      {score && (
        <Card className="mb-6">
          <h2 className="mb-3 text-lg font-semibold text-gray-900">Desempeno</h2>
          <div className="grid gap-4 sm:grid-cols-3">
            <div className="flex items-center gap-2">
              <Star className="h-4 w-4 text-yellow-500" />
              <span className="text-sm text-gray-600">Calificacion: <strong>{score.rating_avg}/5</strong></span>
            </div>
            <div className="text-sm text-gray-600">Tasa completadas: <strong>{score.completion_rate}%</strong></div>
            <div className="text-sm text-gray-600">Puntualidad: <strong>{score.on_time_rate}%</strong></div>
          </div>
        </Card>
      )}

      {/* Today's appointments */}
      <Card>
        <h2 className="mb-3 text-lg font-semibold text-gray-900">Citas de hoy</h2>
        {data.today.length === 0 ? (
          <p className="py-4 text-sm text-gray-500">No tienes citas programadas para hoy.</p>
        ) : (
          <div className="space-y-2">
            {data.today.map((appt) => (
              <div key={appt.id} className="flex items-center justify-between rounded-lg border border-gray-200 p-3">
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {appt.start_time?.toString().slice(0, 5)} — {appt.customer?.name || 'Cliente'}
                  </p>
                  <p className="text-xs text-gray-500">{appt.service?.name}</p>
                </div>
                <Badge variant={appt.status === 'confirmed' ? 'default' : appt.status === 'checked_in' ? 'success' : 'default'}>
                  {appt.status === 'confirmed' ? 'Confirmada' : appt.status === 'checked_in' ? 'Check-in' : appt.status === 'completed' ? 'Completada' : appt.status}
                </Badge>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}
