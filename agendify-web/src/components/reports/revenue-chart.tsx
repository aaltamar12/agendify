'use client';

import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { Skeleton } from '@/components/ui';
import { formatCurrency } from '@/lib/utils/format';

interface RevenueChartProps {
  data: { date: string; revenue: number }[];
  isLoading: boolean;
}

function formatDateLabel(dateStr: string) {
  const date = new Date(dateStr);
  return date.toLocaleDateString('es-CO', { day: 'numeric', month: 'short' });
}

export function RevenueChart({ data, isLoading }: RevenueChartProps) {
  if (isLoading) {
    return <Skeleton className="h-72 w-full" />;
  }

  if (!data || data.length === 0) {
    return (
      <div className="flex h-72 items-center justify-center text-sm text-gray-500">
        No hay datos de ingresos para este periodo.
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={288}>
      <AreaChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id="revenueGradient" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#7C3AED" stopOpacity={0.3} />
            <stop offset="95%" stopColor="#7C3AED" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
        <XAxis
          dataKey="date"
          tickFormatter={formatDateLabel}
          tick={{ fontSize: 12, fill: '#6B7280' }}
          axisLine={{ stroke: '#E5E7EB' }}
          tickLine={false}
        />
        <YAxis
          tickFormatter={(v: number) => formatCurrency(v)}
          tick={{ fontSize: 12, fill: '#6B7280' }}
          axisLine={false}
          tickLine={false}
          width={80}
        />
        <Tooltip
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          formatter={(value: any) => [formatCurrency(Number(value)), 'Ingresos']}
          labelFormatter={(label: any) => formatDateLabel(String(label))}
          contentStyle={{
            borderRadius: '8px',
            border: '1px solid #E5E7EB',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
          }}
        />
        <Area
          type="monotone"
          dataKey="revenue"
          stroke="#7C3AED"
          strokeWidth={2}
          fill="url(#revenueGradient)"
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
