'use client';

import { useState } from 'react';
import { UserCheck, Search, ChevronLeft, ChevronRight, Calendar } from 'lucide-react';
import { Card, Badge, Modal, Skeleton, EmptyState, Button } from '@/components/ui';
import { useCustomers, useCustomer } from '@/lib/hooks/use-customers';
import { formatPhone } from '@/lib/utils/format';
import type { Customer } from '@/lib/api/types';

export default function CustomersPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [selectedCustomerId, setSelectedCustomerId] = useState<number | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);

  const { data: response, isLoading } = useCustomers(page, debouncedSearch || undefined);
  const { data: customerDetail } = useCustomer(selectedCustomerId);

  const customers = response?.data;
  const meta = response?.meta;

  // Debounce search
  const handleSearchChange = (value: string) => {
    setSearch(value);
    setPage(1);
    // Simple debounce using setTimeout
    const w = window as unknown as { __searchTimer?: ReturnType<typeof setTimeout> };
    clearTimeout(w.__searchTimer);
    w.__searchTimer = setTimeout(() => {
      setDebouncedSearch(value);
    }, 400);
  };

  const openDetail = (customer: Customer) => {
    setSelectedCustomerId(customer.id);
    setDetailOpen(true);
  };

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return 'Sin visitas';
    return new Date(dateStr).toLocaleDateString('es-CO', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    });
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Clientes</h1>
      </div>

      {/* Search */}
      <div className="relative mb-6">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
        <input
          type="text"
          value={search}
          onChange={(e) => handleSearchChange(e.target.value)}
          placeholder="Buscar por nombre, correo o teléfono..."
          className="block w-full rounded-lg border border-gray-300 bg-white py-2.5 pl-10 pr-4 text-sm text-gray-900 placeholder:text-gray-400 transition-colors focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
        />
      </div>

      {/* Loading state */}
      {isLoading && (
        <div className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
        </div>
      )}

      {/* Empty state */}
      {!isLoading && (!customers || customers.length === 0) && (
        <EmptyState
          icon={UserCheck}
          title="No hay clientes"
          description={
            search
              ? 'No se encontraron clientes con esa búsqueda.'
              : 'Los clientes aparecerán aquí cuando reserven su primera cita.'
          }
        />
      )}

      {/* Customer list */}
      {!isLoading && customers && customers.length > 0 && (
        <Card className="overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-gray-200 bg-gray-50">
                <tr>
                  <th className="px-4 py-3 font-medium text-gray-600">Nombre</th>
                  <th className="hidden px-4 py-3 font-medium text-gray-600 sm:table-cell">
                    Correo
                  </th>
                  <th className="hidden px-4 py-3 font-medium text-gray-600 md:table-cell">
                    Teléfono
                  </th>
                  <th className="px-4 py-3 text-center font-medium text-gray-600">
                    Visitas
                  </th>
                  <th className="hidden px-4 py-3 font-medium text-gray-600 lg:table-cell">
                    Última visita
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {customers.map((customer) => (
                  <tr
                    key={customer.id}
                    className="cursor-pointer transition-colors hover:bg-gray-50"
                    onClick={() => openDetail(customer)}
                  >
                    <td className="whitespace-nowrap px-4 py-3 font-medium text-gray-900">
                      {customer.name}
                    </td>
                    <td className="hidden whitespace-nowrap px-4 py-3 text-gray-500 sm:table-cell">
                      {customer.email || '—'}
                    </td>
                    <td className="hidden whitespace-nowrap px-4 py-3 text-gray-500 md:table-cell">
                      {customer.phone ? formatPhone(customer.phone) : '—'}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 text-center">
                      <Badge variant={customer.total_visits > 0 ? 'info' : 'default'}>
                        {customer.total_visits}
                      </Badge>
                    </td>
                    <td className="hidden whitespace-nowrap px-4 py-3 text-gray-500 lg:table-cell">
                      {formatDate(customer.last_visit_at)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Pagination */}
      {meta && meta.total_pages > 1 && (
        <div className="mt-4 flex items-center justify-between">
          <p className="text-sm text-gray-500">
            Página {meta.current_page} de {meta.total_pages} ({meta.total_count}{' '}
            clientes)
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page <= 1}
              onClick={() => setPage((p) => p - 1)}
            >
              <ChevronLeft className="h-4 w-4" />
              Anterior
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= meta.total_pages}
              onClick={() => setPage((p) => p + 1)}
            >
              Siguiente
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}

      {/* Customer detail modal */}
      <Modal
        open={detailOpen}
        onClose={() => {
          setDetailOpen(false);
          setSelectedCustomerId(null);
        }}
        title="Detalle del cliente"
        size="lg"
      >
        {customerDetail && (
          <div>
            <div className="mb-4 space-y-2">
              <h3 className="text-lg font-semibold text-gray-900">
                {customerDetail.name}
              </h3>
              {customerDetail.email && (
                <p className="text-sm text-gray-500">{customerDetail.email}</p>
              )}
              {customerDetail.phone && (
                <p className="text-sm text-gray-500">
                  {formatPhone(customerDetail.phone)}
                </p>
              )}
              <div className="flex items-center gap-4 text-sm text-gray-600">
                <span>
                  <strong>{customerDetail.total_visits}</strong> visitas
                </span>
                <span>
                  Última: {formatDate(customerDetail.last_visit_at)}
                </span>
              </div>
              {customerDetail.notes && (
                <p className="rounded-lg bg-gray-50 p-3 text-sm text-gray-600">
                  {customerDetail.notes}
                </p>
              )}
            </div>

            {/* Appointment history */}
            <div>
              <h4 className="mb-2 flex items-center gap-2 text-sm font-medium text-gray-700">
                <Calendar className="h-4 w-4" />
                Historial de citas
              </h4>
              {Array.isArray(customerDetail.appointments) &&
              customerDetail.appointments.length > 0 ? (
                <div className="max-h-64 space-y-2 overflow-y-auto">
                  {(customerDetail.appointments as Array<{
                    id: number;
                    date: string;
                    start_time: string;
                    status: string;
                    service?: { name: string };
                  }>).map((apt) => (
                    <div
                      key={apt.id}
                      className="flex items-center justify-between rounded-lg border border-gray-100 p-3"
                    >
                      <div>
                        <p className="text-sm font-medium text-gray-900">
                          {apt.service?.name ?? 'Servicio'}
                        </p>
                        <p className="text-xs text-gray-500">
                          {formatDate(apt.date)} - {apt.start_time}
                        </p>
                      </div>
                      <Badge
                        variant={
                          apt.status === 'completed'
                            ? 'success'
                            : apt.status === 'cancelled'
                            ? 'error'
                            : 'default'
                        }
                      >
                        {apt.status}
                      </Badge>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-gray-500">Sin citas registradas.</p>
              )}
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
